# jsafe

Resilient JSON parsing utilities, `json_serializable` converters, and a **CLI JSON-to-Dart model generator** for Dart/Flutter.

---

## Why
Backends drift. Fields go null, types flip ("1" vs 1), arrays become singletons, etc. `jsafe` makes your parsing forgiving without hiding problems.  

`jsafe` is perfect for Flutter and Dart projects that need **robust JSON parsing** with deep nesting, lists of objects, enums, and safe `DateTime` handling.  
It also comes with a **CLI generator** to create Dart models from JSON automatically, saving time and avoiding boilerplate.

---

## Highlights
- **Safe scalar parsing**:
  - Non-nullable: `string`, `integer`, `double_`, `boolean`, `number`
  - Nullable: `stringN`, `integerN`, `doubleN`, `booleanN`, `numberN`
- **ISO & epoch-millis `DateTime` parsing**: `dateTime` / `dateTimeN`
- **Enum parsing** with fallback: `enumValue`
- **Deep getter**: `JSafe.getAt(map, 'a.b[0].c')`
- **Nested lists**: `mapList` for nested lists of objects
- **Clean `toJson`**: `omitNulls` to remove nulls recursively
- **Debug & strict flags**: 
  - `JSafe.debugLogs` → prints parsing warnings
  - `JSafe.strictThrow` → throws exceptions on unexpected types
- **`json_serializable` converters** included
- **CLI support**: Generate Dart models from JSON with `jsafe` generator

---

## Quick Start

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
