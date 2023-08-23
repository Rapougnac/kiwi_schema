import 'package:kiwi_schema/src/schema.dart';

class Compiler {
  String _compileDecode(
      Definition definition, Map<String, Definition> definitions) {
    var indent = '  ';
    final buffer = StringBuffer();

    if (definition.kind == DefinitionKind.message) {
      for (final field in definition.fields) {
        buffer.writeln(
            '${indent * 2}${field.isList ? 'List<' : ''}${_kiwiTypeToDartType(field.type!)}${field.isList ? '>' : ''}? ${field.name};');
      }
      buffer.writeln('${indent * 2}while (true) {');
      buffer.writeln('${indent * 4}switch (buffer.readVarUint()) {');
      buffer.writeln('${indent * 5}case 0:');
      buffer.writeln('${indent * 6}return ${definition.name}(');
      for (final field in definition.fields) {
        buffer.writeln('${indent * 7}${field.name}: ${field.name},');
      }
      buffer.writeln('${indent * 6});');
      buffer.writeln();
      indent = '        ';
    }

    for (final field in definition.fields) {
      String code = switch (field.type) {
        'bool' => 'buffer.readByte() != 0',
        'byte' => 'buffer.readByte()',
        'int' => 'buffer.readVarInt()',
        'uint' => 'buffer.readVarUint()',
        'float' => 'buffer.readFloat()',
        'string' => 'buffer.readString()',
        'int64' => 'buffer.readVarUint()',
        'uint64' => 'buffer.readVarInt()',
        _ => (() {
            final type = definitions[field.type];
            if (type == null) {
              throw Exception(
                  'Unknown type ${field.type} for field ${field.name}');
            } else {
              return '${type.name}.decode(buffer)';
            }
          })()
      };

      if (definition.kind == DefinitionKind.message) {
        buffer.writeln('  ${indent}case ${field.value}:');
      }

      if (field.isList) {
        if (field.isDeprecated) {
          if (field.type == 'byte') {
            buffer.writeln('${indent}buffer.readByteList();');
          } else {
            buffer.writeln('${indent}var length = buffer.readVarUint();');
            buffer.writeln('${indent}while(length-- > 0) {');
            buffer.writeln('${indent * 2}$code;');
            buffer.writeln('$indent}');
          }
        } else {
          if (field.type == 'byte') {
            buffer.writeln('$indent${field.name} = buffer.readByteList();');
          } else {
            buffer.writeln('    ${indent}var length = buffer.readVarUint();');
            buffer.writeln(
                '    $indent${field.name} = <${_kiwiTypeToDartType(field.type!)}>[];');
            buffer.writeln('    ${indent}for (var i = 0; i < length; i++) {');
            buffer.writeln('      $indent${field.name}.add($code);');
            buffer.writeln('    $indent}');
          }
        }
      } else {
        if (field.isDeprecated) {
          buffer.writeln('$indent$code;');
        } else {
          buffer.writeln(
              '    $indent${definition.kind != DefinitionKind.message ? _kiwiTypeToDartType(field.type!) : ''} ${field.name} = $code;');
        }
      }
    }

    if (definition.kind == DefinitionKind.message) {
      buffer.writeln('  ${indent}default:');
      buffer.writeln(
          '    ${indent}throw Exception(\'Attempted to parse invalid message\');');
      buffer.writeln('$indent}');
      buffer.writeln('  }');
      buffer.writeln('}');
    } else {
      buffer.writeln('${indent}return ${definition.name}(');
      for (final field in definition.fields) {
        buffer.writeln('${indent * 2}${field.name}: ${field.name},');
      }
      buffer.writeln('$indent);');
      buffer.writeln('$indent}');
    }

    return buffer.toString();
  }

  String _compileEncode(
      Definition definition, Map<String, Definition> definitions) {
    final buffer = StringBuffer();
    // buffer.writeln('bool isTopLevel = buffer == null;');
    // buffer.writeln('if (isTopLevel) {');
    buffer.writeln('buffer ??= ByteBuffer();');
    // buffer.writeln('}');
    bool seen = false;

    for (final field in definition.fields) {
      String code = switch (field.type) {
        'bool' => 'buffer.writeByte(value ? 1 : 0);',
        'byte' => 'buffer.writeByte(value);',
        'int' => 'buffer.writeVarInt(value);',
        'uint' => 'buffer.writeVarUint(value);',
        'float' => 'buffer.writeFloat(value);',
        'string' => 'buffer.writeString(value);',
        'int64' => 'buffer.writeVarUint(value);',
        'uint64' => 'buffer.writeVarInt(value);',
        _ => (() {
            final type = definitions[field.type];
            if (type == null) {
              throw Exception(
                  'Unknown type ${field.type} for field ${field.name}');
            } else {
              return '${type.name}.encode(value, buffer);';
            }
          })(),
      };

      if (!seen) {
        buffer.writeln(
            'dynamic value = ${definition.name.toLowerCase()}.${field.name};');
        seen = true;
      } else {
        buffer
            .writeln('value = ${definition.name.toLowerCase()}.${field.name};');
      }
      buffer.writeln('if (value != null) {');
      if (definition.kind == DefinitionKind.message) {
        buffer.writeln('  buffer.writeVarUint(${field.value});');
      }

      if (field.isList) {
        if (field.type == 'byte') {
          buffer.writeln('  buffer.writeByteList(value);');
        } else {
          buffer.writeln('  buffer.writeVarUint(value.length);');
          buffer.writeln('  var oldVal = value;');
          buffer.writeln('  for (var value in oldVal) {');
          buffer.writeln('    $code');
          buffer.writeln('  }');
        }
      } else {
        buffer.writeln('  $code');
      }

      if (definition.kind == DefinitionKind.struct) {
        buffer.writeln('} else {');
        buffer.writeln(
            '  throw Exception(\'Missing required field ${field.name}\');');
      }

      buffer.writeln('  }');
    }

    if (definition.kind == DefinitionKind.message) {
      buffer.writeln('  buffer.writeVarUint(0);');
    }

    buffer.writeln();
    // buffer.writeln('if (isTopLevel) {');
    buffer.writeln('return buffer.toUint8List();');
    // buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }

  String compile(Schema schema) {
    final buffer = StringBuffer();
    final definitions = <String, Definition>{};
    final name = schema.package;
    const indent = '  ';

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// ignore_for_file: constant_identifier_names');
    buffer.writeln('library${name == null ? '' : ' $name'};');
    buffer.writeln();
    buffer.writeln('import \'dart:typed_data\';');
    buffer.writeln('// ignore: implementation_imports');
    buffer.writeln('import \'package:kiwi_schema/src/byte_buffer.dart\';');

    buffer.writeln();

    buffer.writeln('class Payload {');
    buffer.writeln('${indent}Uint8List encode<T>(T value) {');
    buffer.writeln('${indent * 2}final encoders = {');
    for (final definition in schema.definitions) {
      definitions[definition.name] = definition;
      buffer.writeln(
          "${indent * 3}'${definition.name}': ${definition.name}.encode,");
    }
    buffer.writeln('${indent * 2}};');
    buffer.writeln();
    buffer.writeln(
        '${indent * 2}final encoder = encoders[T.toString()];');
    buffer.writeln('${indent * 2}if (encoder == null) {');
    buffer.writeln(
        '${indent * 3}throw Exception(\'Unknown type ${schema.package}\');');
    buffer.writeln('${indent * 2}}');
    buffer.writeln();
    buffer.writeln('${indent * 2}return encoder(value);');
    buffer.writeln('$indent}');
    buffer.writeln();
    buffer.writeln('${indent}T decode<T>(Uint8List buffer) {');
    buffer.writeln('${indent * 2}final decoders = {');
    for (final definition in schema.definitions) {
      buffer.writeln(
          "${indent * 3}'${definition.name}': ${definition.name}.decode,");
    }
    buffer.writeln('${indent * 2}};');
    buffer.writeln();
    buffer.writeln('${indent * 2}final decoder = decoders[T.toString()];');
    buffer.writeln('${indent * 2}if (decoder == null) {');
    buffer.writeln(
        '${indent * 3}throw Exception(\'Unknown type ${schema.package}\');');
    buffer.writeln('${indent * 2}}');
    buffer.writeln();
    buffer.writeln('${indent * 2}return decoder(ByteBuffer(buffer)) as T;');
    buffer.writeln('$indent}');
    buffer.writeln('}');
    buffer.writeln();

    for (final definition in schema.definitions) {
      switch (definition.kind) {
        case DefinitionKind.enum_:
          buffer.writeln('enum ${definition.name} {');
          for (final (i, field) in definition.fields.indexed) {
            if (i == definition.fields.length - 1) {
              buffer.writeln('$indent${field.name};');
            } else {
              buffer.writeln('$indent${field.name},');
            }
          }
          buffer.writeln();

          buffer.writeln(
              '${indent}factory ${definition.name}.decode(ByteBuffer buffer) {');
          buffer.writeln('${indent * 2}return values[buffer.readVarUint()];');
          buffer.writeln('$indent}');

          buffer.writeln(
              '${indent}static Uint8List encode(${definition.name} ${definition.name.toLowerCase()}, ByteBuffer buffer) {');
          buffer.writeln(
              '${indent * 2}buffer.writeVarUint(${definition.name.toLowerCase()}.index);');
          buffer.writeln('${indent * 2}return buffer.toUint8List();');
          buffer.writeln('$indent}');
          buffer.writeln('}');
        case DefinitionKind.message:
        case DefinitionKind.struct:
          buffer.writeln();
          buffer.writeln('class ${definition.name} {');

          for (final field in definition.fields) {
            buffer.writeln(
                '$indent${field.isList ? 'List<' : ''}${_kiwiTypeToDartType(field.type!)}${definition.kind == DefinitionKind.message && !field.isList ? '?' : ''}${field.isList ? '>${definition.kind == DefinitionKind.message ? '?' : ''}' : ''} ${field.name};');
          }
          buffer.writeln();
          buffer.writeln('$indent${definition.name}({');
          for (final field in definition.fields) {
            buffer.writeln(
                '$indent$indent${definition.kind == DefinitionKind.message ? '' : 'required '}this.${field.name},');
          }
          buffer.writeln('$indent});');
          buffer.writeln();

          buffer.writeln(
              '${indent}factory ${definition.name}.decode(ByteBuffer buffer) {');
          buffer.writeln(_compileDecode(definition, definitions));
          buffer.writeln();
          buffer.writeln(
              '${indent}static Uint8List encode(${definition.name} ${definition.name.toLowerCase()}, [ByteBuffer? buffer]) {');
          buffer.writeln(_compileEncode(definition, definitions));
          buffer.writeln('${indent * 2}}');
          buffer.writeln('}');
      }
    }

    return buffer.toString();
  }

  String _kiwiTypeToDartType(String type) {
    return switch (type) {
      'bool' => 'bool',
      'byte' => 'int',
      'int' => 'int',
      'uint' => 'int',
      'float' => 'double',
      'int64' => 'int',
      'uint64' => 'int',
      _ => type,
    };
  }
}
