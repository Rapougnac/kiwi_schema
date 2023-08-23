// After running dart run kiwi_schema -s example/example.kiwi -o example/example_schema.g.dart -f

import 'example_schema.g.dart';

void main(List<String> args) {
  final payload = Payload();
  final encoded = payload.encode(
    Example(
      clientID: 100,
      type: Type.FLAT,
      colors: [
        Color(red: 255, green: 0, blue: 0, alpha: 255),
        Color(red: 0, green: 255, blue: 0, alpha: 255),
        Color(red: 0, green: 0, blue: 255, alpha: 255),
      ],
      foo: Foo(bar: 3),
    ),
  );
  print(encoded);
  final decoded = payload.decode<Example>(encoded);
  print(decoded);
}
