import 'dart:typed_data';

final int32 = Int32List(1);
final float32 = Float32List.view(int32.buffer);

class ByteBuffer {
  Uint8List _buffer;

  int _offset = 0;
  int length;

  ByteBuffer([Uint8List? buffer])
      : _buffer = (buffer ?? Uint8List(256)),
        length = buffer?.length ?? 0;

  Uint8List toUint8List() {
    return _buffer.sublist(0, length);
  }

  int readByte() {
    return _buffer[_offset++];
  }

  Uint8List readByteList() {
    int length = readVarUint();
    int start = _offset;
    int end = start + length;

    if (end > _buffer.length) {
      throw RangeError('Invalid byte list length');
    }

    _offset = end;

    final result = Uint8List(length);
    result.setRange(0, length, _buffer, start);
    return result;
  }

  double readVarFloat() {
    int index = _offset;

    if (index + 1 > length) {
      throw RangeError('Index out of bounds');
    }

    int first = _buffer.first;
    if (first == 0) {
      _offset = index + 1;
      return 0.0;
    }

    if (index + 4 > length) {
      throw RangeError('Index out of bounds');
    }

    int bits = first |
        (_buffer[index + 1] << 8) |
        (_buffer[index + 2] << 16) |
        (_buffer[index + 3] << 24);

    _offset = index + 4;

    bits = (bits << 23) | (bits >>> 9);

    int32[0] = bits;
    return float32[0];
  }

  int readVarUint() {
    int value = 0;
    int shift = 0;
    int byte = 0;
    do {
      byte = readByte();
      value |= (byte & 0x7f) << shift;
      shift += 7;
    } while (byte & 0x80 != 0 && shift < 35);

    return value >>> 0;
  }

  int readVarInt() {
    int value = readVarUint() | 0;
    return (value & 1) == 1 ? ~(value >>> 1) : (value >>> 1);
  }

  String readString() {
    final sb = StringBuffer();

    while (true) {
      int codePoint;
      int a = readByte();
      if (a < 0xC0) {
        codePoint = a;
      } else {
        int b = readByte();
        if (a < 0xE0) {
          codePoint = ((a & 0x1F) << 6) | (b & 0x3F);
        } else {
          int c = readByte();
          if (a < 0xF0) {
            codePoint = ((a & 0x0F) << 12) | ((b & 0x3F) << 6) | (c & 0x3F);
          } else {
            int d = readByte();
            codePoint = ((a & 0x07) << 18) |
                ((b & 0x3F) << 12) |
                ((c & 0x3F) << 6) |
                (d & 0x3F);
          }
        }
      }

      if (codePoint == 0) {
        break;
      }

      if (codePoint < 0x10000) {
        sb.write(String.fromCharCode(codePoint));
      } else {
        codePoint -= 0x10000;
        sb.write(String.fromCharCodes([
          ((codePoint >> 10) + 0xD800),
          (codePoint & ((1 << 10) - 1)) + 0xDC00
        ]));
      }
    }

    return sb.toString();
  }

  void _growBy(int size) {
    if (length + size > _buffer.length) {
      final newBuffer = Uint8List(length + size);
      newBuffer.setRange(0, length, _buffer);
      _buffer = newBuffer;
    }

    length += size;
  }

  void writeByte(int value) {
    int index = length;
    _growBy(1);
    _buffer[index] = value;
  }

  void writeByteList(Uint8List value) {
    int index = length;
    _growBy(value.length);
    _buffer.setRange(index, index + value.length, value);
  }

  void writeVarFloat(double value) {
    int index = length;

    float32[0] = value;
    int bits = int32[0];

    bits = (bits >>> 23) | (bits << 9);

    if ((bits & 255) == 0) {
      writeByte(0);
      return;
    }

    _growBy(4);
    _buffer[index] = bits;
    _buffer[index + 1] = bits >> 8;
    _buffer[index + 2] = bits >> 16;
    _buffer[index + 3] = bits >> 24;
  }

  void writeVarUint(int value) {
    do {
      int byte = value & 0x7f;
      value >>>= 7;
      if (value != 0) {
        byte |= 0x80;
      }

      writeByte(byte);
    } while (value != 0);
  }

  void writeVarInt(int value) {
    writeVarUint(((value << 1) ^ (value >> 31)) >>> 0);
  }

  void writeString(String value) {
    int codePoint;

    for (int i = 0; i < value.length; i++) {
      int a = value.codeUnitAt(i);
      if (i + 1 == value.length || a < 0xD800 || a >= 0xDC00) {
        codePoint = a;
      } else {
        int b = value.codeUnitAt(++i);
        codePoint = (a << 10) + b + (0x10000 - (0xD800 << 10) - 0xDC00);
      }

      if (codePoint == 0) {
        throw ArgumentError('Invalid code point');
      }

      if (codePoint < 0x80) {
        writeByte(codePoint);
      } else {
        if (codePoint < 0x800) {
          writeByte(((codePoint >> 6) & 0x1F) | 0xC0);
        } else {
          if (codePoint < 0x10000) {
            writeByte(((codePoint >> 12) & 0x0F) | 0xE0);
          } else {
            writeByte(((codePoint >> 18) & 0x07) | 0xF0);
            writeByte(((codePoint >> 12) & 0x3F) | 0x80);
          }
          writeByte(((codePoint >> 6) & 0x3F) | 0x80);
        }
        writeByte((codePoint & 0x3F) | 0x80);
      }
    }

    writeByte(0);
  }
}
