import 'package:jsafe/jsafe.dart';
import 'package:test/test.dart';

void main() {
  setUp(() => JSafe.setMode(debug: false, strict: true));

  test('parses numbers from strings and ints', () {
    expect(JSafe.int_('12'), 12);
    expect(JSafe.dbl('1,234.5'), 1234.5);
    expect(JSafe.num_('7'), 7);
  });

  test('parses bool-ish strings/numbers', () {
    expect(JSafe.bool_('true'), true);
    expect(JSafe.bool_(1), true);
    expect(JSafe.bool_('no'), false);
  });

  test('date parsing', () {
    final iso = JSafe.dt('2025-10-22T00:00:00Z');
    expect(iso.year, 2025);

    final epoch = JSafe.dt(1730784000000); // ms
    expect(epoch.millisecondsSinceEpoch, 1730784000000);
  });
}
