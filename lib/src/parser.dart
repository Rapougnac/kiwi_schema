import 'package:kiwi_schema/src/error.dart';
import 'package:kiwi_schema/src/schema.dart';

const nativeTypes = [
  'bool',
  'byte',
  'float',
  'int',
  'int64',
  'string',
  'uint',
  'uint64',
];

final regex = RegExp(
    r'((?:-|\b)\d+\b|[=;{}]|\[\]|\[deprecated\]|\b[A-Za-z_][A-Za-z0-9_]*\b|\/\/.*|\s+)');
final identifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
final whitespace = RegExp(r'^\/\/.*|\s+$');
final equals = RegExp(r'^=$');
final eof = RegExp(r'^$');
final semicolon = RegExp(r'^;$');
final integer = RegExp(r'^-?\d+$');
final leftBrace = RegExp(r'^\{$');
final rightBrace = RegExp(r'^\}$');
final arrayToken = RegExp(r'^\[\]$');
final enumKeyword = RegExp(r'^enum$');
final structKeyword = RegExp(r'^struct$');
final messageToken = RegExp(r'^message$');
final packageKeyword = RegExp(r'^package$');
final deprecatedToken = RegExp(r'^\[deprecated\]$');

interface class Token {
  final String text;
  final int line;
  final int column;

  const Token({
    required this.text,
    required this.line,
    required this.column,
  });

  @override
  String toString() {
    return 'Token(text: $text, line: $line, column: $column)';
  }
}

extension on RegExp {
  List<String> allMatchesWithSep(String input, [int start = 0]) {
    var result = <String>[];
    for (var match in allMatches(input, start)) {
      result.add(input.substring(start, match.start));
      result.add(match[0]!);
      start = match.end;
    }
    result.add(input.substring(start));
    return result;
  }
}

final class Parser {
  late final String source;

  List<Token> tokenize(final String text) {
    source = text;
    final parts = regex.allMatchesWithSep(text);
    final tokens = <Token>[];
    var line = 0;
    var column = 0;

    for (final (i, part) in parts.indexed) {
      // Keep non-whitespace tokens
      if (i & 1 != 0) {
        if (!whitespace.hasMatch(part)) {
          tokens.add(Token(text: part, line: line + 1, column: column + 1));
        }
      } else if (part.isNotEmpty) {
        throw SyntaxError('Unexpected token', source, text, i, line + 1, column + 1);
      }

      final lines = part.split('\n');
      if (lines.length > 1) {
        column = 0;
      }
      line += lines.length - 1;
      column += lines.last.length;
    }

    tokens.add(Token(text: '', line: line, column: column));
    return tokens;
  }

  Schema parse(List<Token> tokens) {
    int index = 0;
    Token curr() {
      return tokens[index];
    }

    bool eat(RegExp pattern) {
      if (pattern.hasMatch(curr().text)) {
        index++;
        return true;
      }
      return false;
    }

    void expect(RegExp pattern, String expected) {
      if (!eat(pattern)) {
        Token token = curr();
        throw SyntaxError(
          'Expected $expected but found ${token.text}',
          source,
          token.text,
          index,
          token.line,
          token.column,
        );
      }
    }

    void unexpectedToken() {
      Token token = curr();
      throw SyntaxError(
        'Unexpected token ${token.text}',
        source,
        token.text,
        index,
        token.line,
        token.column,
      );
    }

    final definitions = <Definition>[];
    String? packageText;
    if (eat(packageKeyword)) {
      packageText = curr().text;
      expect(identifier, 'identifier');
      expect(semicolon, ';');
    }

    while (index < tokens.length && !eat(eof)) {
      final fields = <Field>[];
      late DefinitionKind kind;

      if (eat(enumKeyword)) {
        kind = DefinitionKind.enum_;
      } else if (eat(structKeyword)) {
        kind = DefinitionKind.struct;
      } else if (eat(messageToken)) {
        kind = DefinitionKind.message;
      } else {
        unexpectedToken();
      }

      Token name = curr();
      expect(identifier, 'identifier');
      expect(leftBrace, '{');

      while (!eat(rightBrace)) {
        String? type;
        bool isList = false;
        bool isDeprecated = false;

        if (kind != DefinitionKind.enum_) {
          type = curr().text;
          expect(identifier, 'identifier');
          isList = eat(arrayToken);
        }

        Token field = curr();
        expect(identifier, 'identifier');

        Token? value;
        if (kind != DefinitionKind.struct) {
          expect(equals, '"="');
          value = curr();
          expect(integer, 'integer');

          if ((int.parse(value.text) | 0).toString() != value.text) {
            throw SyntaxError(
              'Invalid integer',
              source,
              value.text,
              index,
              value.line,
              value.column,
            );
          }
        }

        Token deprecated = curr();
        if (eat(deprecatedToken)) {
          if (kind != DefinitionKind.message) {
            throw SyntaxError(
              'Cannot deprecate this field',
              deprecated.text,
              source,
              index,
              deprecated.line,
              deprecated.column,
            );
          }

          isDeprecated = true;
        }

        expect(semicolon, '";"');

        fields.add(Field(
          name: field.text,
          line: field.line,
          column: field.column,
          isList: isList,
          isDeprecated: isDeprecated,
          value: value == null ? 0 : int.parse(value.text),
          type: type,
        ));
      }

      definitions.add(Definition(
        name: name.text,
        line: name.line,
        column: name.column,
        kind: kind,
        fields: fields,
      ));
    }

    return Schema(
      package: packageText,
      definitions: definitions,
    );
  }
}
