// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: constant_identifier_names
library;

import 'dart:typed_data';
// ignore: implementation_imports
import 'package:kiwi_schema/src/byte_buffer.dart';

class Payload {
  Uint8List encode<T>(T value) {
    final encoders = {
      'Type': Type.encode,
      'Color': Color.encode,
      'Example': Example.encode,
      'Foo': Foo.encode,
    };

    final encoder = encoders[T.toString()];
    if (encoder == null) {
      throw Exception('Unknown type null');
    }

    return encoder(value);
  }

  T decode<T>(Uint8List buffer) {
    final decoders = {
      'Type': Type.decode,
      'Color': Color.decode,
      'Example': Example.decode,
      'Foo': Foo.decode,
    };

    final decoder = decoders[T.toString()];
    if (decoder == null) {
      throw Exception('Unknown type null');
    }

    return decoder(ByteBuffer(buffer)) as T;
  }
}

enum Type {
  FLAT,
  ROUND,
  POINTED;

  factory Type.decode(ByteBuffer buffer) {
    return values[buffer.readVarUint()];
  }
  static Uint8List encode(Type type, ByteBuffer buffer) {
    buffer.writeVarUint(type.index);
    return buffer.toUint8List();
  }
}

class Color {
  int red;
  int green;
  int blue;
  int alpha;

  Color({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  factory Color.decode(ByteBuffer buffer) {
    int red = buffer.readByte();
    int green = buffer.readByte();
    int blue = buffer.readByte();
    int alpha = buffer.readByte();
    return Color(
      red: red,
      green: green,
      blue: blue,
      alpha: alpha,
    );
  }

  static Uint8List encode(Color color, [ByteBuffer? buffer]) {
    buffer ??= ByteBuffer();
    dynamic value = color.red;
    if (value != null) {
      buffer.writeByte(value);
    } else {
      throw Exception('Missing required field red');
    }
    value = color.green;
    if (value != null) {
      buffer.writeByte(value);
    } else {
      throw Exception('Missing required field green');
    }
    value = color.blue;
    if (value != null) {
      buffer.writeByte(value);
    } else {
      throw Exception('Missing required field blue');
    }
    value = color.alpha;
    if (value != null) {
      buffer.writeByte(value);
    } else {
      throw Exception('Missing required field alpha');
    }

    return buffer.toUint8List();
  }
}

class Example {
  int? clientID;
  Type? type;
  List<Color>? colors;
  Foo? foo;

  Example({
    this.clientID,
    this.type,
    this.colors,
    this.foo,
  });

  factory Example.decode(ByteBuffer buffer) {
    int? clientID;
    Type? type;
    List<Color>? colors;
    Foo? foo;
    while (true) {
      switch (buffer.readVarUint()) {
        case 0:
          return Example(
            clientID: clientID,
            type: type,
            colors: colors,
            foo: foo,
          );

        case 1:
          clientID = buffer.readVarUint();
        case 2:
          type = Type.decode(buffer);
        case 3:
          var length = buffer.readVarUint();
          colors = <Color>[];
          for (var i = 0; i < length; i++) {
            colors.add(Color.decode(buffer));
          }
        case 4:
          foo = Foo.decode(buffer);
        default:
          throw Exception('Attempted to parse invalid message');
      }
    }
  }

  static Uint8List encode(Example example, [ByteBuffer? buffer]) {
    buffer ??= ByteBuffer();
    dynamic value = example.clientID;
    if (value != null) {
      buffer.writeVarUint(1);
      buffer.writeVarUint(value);
    }
    value = example.type;
    if (value != null) {
      buffer.writeVarUint(2);
      Type.encode(value, buffer);
    }
    value = example.colors;
    if (value != null) {
      buffer.writeVarUint(3);
      buffer.writeVarUint(value.length);
      var oldVal = value;
      for (var value in oldVal) {
        Color.encode(value, buffer);
      }
    }
    value = example.foo;
    if (value != null) {
      buffer.writeVarUint(4);
      Foo.encode(value, buffer);
    }
    buffer.writeVarUint(0);

    return buffer.toUint8List();
  }
}

class Foo {
  int bar;

  Foo({
    required this.bar,
  });

  factory Foo.decode(ByteBuffer buffer) {
    int bar = buffer.readVarInt();
    return Foo(
      bar: bar,
    );
  }

  static Uint8List encode(Foo foo, [ByteBuffer? buffer]) {
    buffer ??= ByteBuffer();
    dynamic value = foo.bar;
    if (value != null) {
      buffer.writeVarInt(value);
    } else {
      throw Exception('Missing required field bar');
    }

    return buffer.toUint8List();
  }
}
