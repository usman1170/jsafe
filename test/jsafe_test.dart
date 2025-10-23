import 'package:jsafe/jsafe.dart';
import 'package:test/test.dart';

void main() {
  setUp(() => JSafe.setMode(debug: false, strict: true));

  test('parses numbers from strings and ints', () {
    expect(JSafe.integer('12'), 12);
    expect(JSafe.double_('1,234.5'), 1234.5);
    expect(JSafe.number('7'), 7);
  });

  test('parses bool-ish strings/numbers', () {
    expect(JSafe.boolean('true'), true);
    expect(JSafe.boolean(1), true);
    expect(JSafe.boolean('no'), false);
  });

  test('date parsing', () {
    final iso = JSafe.dateTime('2025-10-22T00:00:00Z');
    expect(iso.year, 2025);

    final epoch = JSafe.dateTime(1730784000000);
    expect(epoch.millisecondsSinceEpoch, 1730784000000);
  });
}
