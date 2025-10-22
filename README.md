# safe_json


Resilient JSON parsing utilities and `json_serializable` converters for Dart/Flutter.


## Why
Backends drift. Fields go null, types flip ("1" vs 1), arrays become singletons, etc. `safe_json` makes your parsing forgiving without hiding problems.


## Highlights
- Safe scalar parsing: `str/int_/dbl/bool_/num_` (+ nullable `strN/intN/...`)
- ISO & epoch-millis DateTime parsing
- Enum parsing with fallback
- Deep getter: `JSafe.getAt(map, 'a.b[0].c')`
- `mapList` for nested lists
- `omitNulls` for clean `toJson`
- Debug/strict flags to surface backend regressions in dev
- `json_serializable` converters included


## Quick start
```dart
import 'package:safe_json/safe_json.dart';


final map = {
'id': '42',
'price': '1,299.95',
'ok': 'true',
'createdAt': '2025-10-22T08:15:30Z',
};


final id = JSafe.int_(map['id']); // 42
final price = JSafe.dbl(map['price']); // 1299.95
final ok = JSafe.bool_(map['ok']); // true
final ts = JSafe.dt(map['createdAt']);