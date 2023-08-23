interface class Schema {
  final String? package;
  final List<Definition> definitions;

  const Schema({
    this.package,
    required this.definitions,
  });
}

interface class Definition {
  final String name;
  final int line;
  final int column;
  final DefinitionKind kind;
  final List<Field> fields;

  const Definition({
    required this.name,
    required this.line,
    required this.column,
    required this.kind,
    required this.fields,
  });
}

enum DefinitionKind {
  enum_('enum'),
  struct('struct'),
  message('message');

  final String rname;

  const DefinitionKind(this.rname);
}

interface class Field {
  final String name;
  final int line;
  final int column;
  final String? type;
  final bool isList;
  final bool isDeprecated;
  final int value;

  const Field({
    required this.name,
    required this.line,
    required this.column,
    required this.isList,
    required this.isDeprecated,
    required this.value,
    this.type,
  });
}