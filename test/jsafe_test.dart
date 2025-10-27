// test/jsafe_full_test.dart
import 'package:test/test.dart';
import 'package:jsafe/jsafe.dart';

enum SampleEnum { alpha, beta, gamma }

class SampleModel {
  final String id;
  final int value;

  SampleModel({required this.id, required this.value});

  factory SampleModel.fromJson(Map<String, dynamic> json) {
    return SampleModel(
      id: JSafe.string(json['id']),
      value: JSafe.integer(json['value']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'value': value};

  @override
  bool operator ==(Object other) =>
      other is SampleModel && other.id == id && other.value == value;

  @override
  int get hashCode => id.hashCode ^ value.hashCode;
}

void main() {
  // Default to forgiving mode for most tests
  setUp(() => JSafe.setMode(debug: false, strict: false));

  group('Scalars & basic conversions', () {
    test('String conversions and fallbacks', () {
      expect(JSafe.string('x'), 'x');
      expect(JSafe.string(123), '123');
      expect(JSafe.string(null), '');
      expect(JSafe.stringN(null), isNull);
      expect(JSafe.stringN(12), '12');
    });

    test('Integer parsing from various inputs', () {
      expect(JSafe.integer(5), 5);
      expect(JSafe.integer(5.9), 5);
      expect(JSafe.integer('42'), 42);
      expect(JSafe.integer('bad'), 0);
      expect(JSafe.integer(null), 0);
      expect(JSafe.integer(true), 1);
      expect(JSafe.integer(false), 0);
    });

    test('Double parsing including commas and booleans', () {
      expect(JSafe.double_(123.5), 123.5);
      expect(JSafe.double_('1,234.5'), 1234.5);
      expect(JSafe.double_('bad'), 0.0);
      expect(JSafe.double_(true), 1.0);
      expect(JSafe.double_(false), 0.0);
    });

    test('Number (num) accepts int/double/strings', () {
      expect(JSafe.number('7'), 7);
      expect(JSafe.number('1.5'), 1.5);
      expect(JSafe.number('1e3'), 1000);
      expect(JSafe.number('bad'), 0);
    });

    test('Boolean variants', () {
      expect(JSafe.boolean('true'), true);
      expect(JSafe.boolean('True'), true);
      expect(JSafe.boolean('1'), true);
      expect(JSafe.boolean('yes'), true);
      expect(JSafe.boolean('on'), true); // included in updates
      expect(JSafe.boolean('no'), false);
      expect(JSafe.boolean(1), true);
      expect(JSafe.boolean(0), false);
      expect(JSafe.boolean(null), false);
    });
  });

  group('Nullable variants', () {
    test('nullable scalar helpers', () {
      expect(JSafe.integerN(null), isNull);
      expect(JSafe.integerN('12'), 12);
      expect(JSafe.doubleN(null), isNull);
      expect(JSafe.doubleN('2.5'), 2.5);
      expect(JSafe.booleanN(null), isNull);
    });
  });

  group('DateTime parsing', () {
    test('ISO string parsing', () {
      final dt = JSafe.dateTime('2025-10-22T00:00:00Z');
      expect(dt.toUtc().year, 2025);
    });

    test('milliseconds epoch parsing', () {
      final ms = 1730784000000;
      final dt = JSafe.dateTime(ms);
      expect(dt.millisecondsSinceEpoch, ms);
    });

    test('seconds epoch parsing heuristics', () {
      // 10-digit seconds value (approx year 2024/2025)
      final seconds = 1730784000; // seconds
      final dt = JSafe.dateTime(seconds);
      expect(dt.millisecondsSinceEpoch, seconds * 1000);
    });

    test('string epoch parsing and fallback', () {
      expect(JSafe.dateTime('1730784000').millisecondsSinceEpoch,
          1730784000 * 1000);
      // malformed -> default epoch 0
      final fallback =
          JSafe.dateTime('not-a-date', orDefault: DateTime.utc(2000));
      expect(fallback.year, 2000);
    });
  });

  group('Map & List helpers', () {
    test('map() returns empty map for non-map inputs', () {
      expect(JSafe.map(null), {});
      expect(JSafe.map(123), {});
      expect(JSafe.map({'a': 1}), {'a': 1});
    });

    test('list<T> does element-wise conversion for primitives', () {
      final raw = [1, 'two', null, 3.5, true];
      final strings = JSafe.list<String>(raw);
      // string conversion: 1 -> '1', 'two' -> 'two', null -> '', 3.5 -> '3.5', true -> 'true'
      expect(strings, ['1', 'two', '', '3.5', 'true']);

      final ints = JSafe.list<int>(['1', 2.0, null, 'bad']);
      expect(ints, [1, 2, 0, 0]);
    });

    test('typed list helpers', () {
      expect(JSafe.stringList(['a', null, 1]), ['a', '', '1']);
      expect(JSafe.intList(['1', 2, 3.5]), [1, 2, 3]);
      expect(JSafe.doubleList(['1.5', 2]), [1.5, 2.0]);
    });

    test('mapList converts using converter and skips failed conversions', () {
      final raw = [
        {'id': 'a', 'value': 1},
        null,
        {'bad': true}, // converter will throw if it expects 'id'/'value'
        {'id': 'b', 'value': '2'}
      ];

      // converter that throws if required keys missing
      SampleModel? convert(dynamic e) {
        if (e == null) return null;
        final m = JSafe.map(e);
        if (m['id'] == null || m['value'] == null) {
          throw Exception('missing fields');
        }
        return SampleModel.fromJson(m);
      }

      final list = JSafe.mapList<SampleModel>(raw, (e) => convert(e)!);
      // should contain two successful conversions (a and b)
      expect(list.length, 2);
      expect(list[0], SampleModel(id: 'a', value: 1));
      expect(list[1], SampleModel(id: 'b', value: 2));
    });
  });

  group('getAt deep getter', () {
    test('simple deep access with indices', () {
      final m = {
        'user': {
          'addresses': [
            {'city': 'X'},
            {'city': 'Y'}
          ]
        }
      };
      expect(JSafe.getAt(JSafe.map(m), 'user.addresses[0].city'), 'X');
      expect(JSafe.getAt(JSafe.map(m), 'user.addresses[1].city'), 'Y');
      expect(JSafe.getAt(JSafe.map(m), 'user.addresses[2].city'), isNull);
    });

    test('hyphenated and non-ascii keys', () {
      final m = {
        'user-data': {
          'addr-list': [
            {'city-name': 'HyphenTown'}
          ]
        }
      };
      expect(JSafe.getAt(JSafe.map(m), 'user-data.addr-list[0].city-name'),
          'HyphenTown');
    });
  });

  group('omitNulls behavior', () {
    test('removes nulls from maps and nested lists/maps recursively', () {
      final input = {
        'a': null,
        'b': 1,
        'c': {
          'x': null,
          'y': {'z': null, 'k': 3}
        },
        'd': [
          1,
          null,
          {'m': null, 'n': 2},
          [null, 5]
        ]
      };

      final out = JSafe.omitNulls(input);
      expect(out.containsKey('a'), false);
      expect(out['b'], 1);
      expect(out['c'], {
        'y': {'k': 3}
      });
      expect(out['d'], [
        1,
        {'n': 2},
        [5]
      ]);
    });
  });

  group('enumValue helper', () {
    test('matches case-insensitively and falls back', () {
      expect(
        JSafe.enumValue('Alpha', SampleEnum.values, SampleEnum.beta),
        SampleEnum.alpha,
      );
      expect(
        JSafe.enumValue('unknown', SampleEnum.values, SampleEnum.beta),
        SampleEnum.beta,
      );

      // using toKey converter
      expect(
        JSafe.enumValue('A', SampleEnum.values, SampleEnum.beta,
            toKey: (v) => v == SampleEnum.alpha ? 'A' : v.toString()),
        SampleEnum.alpha,
      );
    });
  });

  group('strict mode behavior', () {
    test('strictThrow = true rethrows internal conversion exceptions', () {
      // enable strict (rethrow) to assert we get an error on bad cast
      JSafe.setMode(debug: false, strict: true);

      // list<int> with non-convertible value will cause an exception from cast or conversion
      expect(() => JSafe.list<int>(['not-int']), throwsA(isA<Object>()));

      // restore forgiving mode for other tests
      JSafe.setMode(debug: false, strict: false);
    });
  });

  group('edge cases and regressions', () {
    test('mapList with converter that returns null should skip element', () {
      final raw = [
        {'id': '1', 'value': 1},
        {'id': null, 'value': 0},
      ];

      SampleModel? converter(dynamic e) {
        final m = JSafe.map(e);
        if (JSafe.stringN(m['id']) == null || JSafe.string(m['id']).isEmpty) {
          return null; // intentional: treat missing id as skip
        }
        return SampleModel.fromJson(m);
      }

      final res =
          JSafe.mapList<SampleModel>(raw, (e) => converter(e) as SampleModel);
      expect(res.length, 1);
      expect(res[0], SampleModel(id: '1', value: 1));
    });

    test('list<Model> cannot auto-convert complex objects (skips them)', () {
      final complex = [
        {'id': 'x', 'value': 9}
      ];
      // list<SampleModel> uses cast and will not convert maps -> models automatically
      final asModels = JSafe.list<SampleModel>(complex);
      // should be empty (complex types not auto-converted)
      expect(asModels, isEmpty);
    });
  });
}
