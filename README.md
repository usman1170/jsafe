# jsafe

Resilient JSON parsing utilities and `json_serializable` converters for Dart/Flutter.

## Why
Backends drift. Fields go null, types flip ("1" vs 1), arrays become singletons, etc. `jsafe` makes your parsing forgiving without hiding problems.

## Highlights
- Safe scalar parsing:
  - Non-nullable: `string`, `integer`, `double_`, `boolean`, `number`
  - Nullable: `stringN`, `integerN`, `doubleN`, `booleanN`, `numberN`
- ISO & epoch-millis `DateTime` parsing: `dateTime` / `dateTimeN`
- Enum parsing with fallback: `enumValue`
- Deep getter: `JSafe.getAt(map, 'a.b[0].c')`
- `mapList` for nested lists
- `omitNulls` for clean `toJson`
- Debug (`JSafe.debugLogs`) & strict (`JSafe.strictThrow`) flags to surface backend regressions in dev
- `json_serializable` converters included

## Quick start
```dart
import 'package:jsafe/jsafe.dart';

final map = {
  'id': '42',
  'price': '1,299.95',
  'ok': 'true',
  'createdAt': '2025-10-22T08:15:30Z',
  'tags': ['new', 'sale'],
};

// Scalars
final id = JSafe.integer(map['id']);       // 42
final price = JSafe.double_(map['price']); // 1299.95
final ok = JSafe.boolean(map['ok']);       // true
final ts = JSafe.dateTime(map['createdAt']);

// Nullable variants
final maybeId = JSafe.integerN(map['id']);
final maybePrice = JSafe.doubleN(map['price']);

// Deep getter
final firstTag = JSafe.getAt(map, 'tags[0]'); // 'new'

// Map & List helpers
final mapValue = JSafe.map(map);
final listValue = JSafe.list(map['tags']);
final mappedList = JSafe.mapList<String>(map['tags'], (v) => JSafe.string(v));

// Enum parsing
enum Status { active, inactive, pending }
final status = JSafe.enumValue(
  'Active', 
  Status.values, 
  Status.inactive,
  caseInsensitive: true,
);

// Omit nulls recursively
final cleaned = JSafe.omitNulls({
  'a': null,
  'b': {'x': 1, 'y': null},
  'c': [1, null, 2],
});
// Result: {'b': {'x': 1}, 'c': [1, 2]}
