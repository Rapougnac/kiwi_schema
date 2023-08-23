class SyntaxError extends Error {
  final String message;
  final String source;
  final String found;
  final int offset;
  final int line;
  final int column;

  SyntaxError(this.message, this.source, this.found, this.offset, this.line, this.column);

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('$message at $line:$column');
    buffer.write(source);
    buffer.writeln('${column == 1 ? '' : ' ' * column}^');

    return buffer.toString();
  }
}