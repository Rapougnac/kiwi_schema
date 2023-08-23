import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_style/dart_style.dart';
import 'package:kiwi_schema/kiwi_schema.dart';

void main(List<String> args) async {
  late final argsParser = ArgParser();
  argsParser.addOption(
    'schema',
    abbr: 's',
    defaultsTo: 'schema.kiwi',
    help: 'The path of the schema to generate',
  );
  argsParser.addOption(
    'output',
    abbr: 'o',
    defaultsTo: 'kiwi_schema.g.dart',
    help: 'The path of the file where it will be generated',
  );
  argsParser.addFlag(
    'format',
    abbr: 'f',
    defaultsTo: false,
    help: 'Format the generated file (might take more time generate)',
  );
  argsParser.addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Print help and exit',
  );

  final results = argsParser.parse(args);

  final schema = results['schema'] as String;
  final output = results['output'] as String;
  final format = results['format'] as bool;
  final help = results['help'] as bool;

  if (help) {
    print('''
Generate code from a Kiwi schema to properly encode/decode it.
Usage: kiwi_schema [options]

Options:
''');
    print(argsParser.usage);
    return;
  }

  final fileSchema = await File(schema).readAsString();

  final parser = Parser();
  final tokenized = parser.tokenize(fileSchema);
  final parsed = parser.parse(tokenized);
  String compiled = Compiler().compile(parsed);
  if (format) {
    compiled = DartFormatter().format(compiled);
  }

  await File(output).writeAsString(compiled);
}
