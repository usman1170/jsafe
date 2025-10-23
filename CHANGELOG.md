# Changelog

All notable changes to this project will be documented in this file.

## 0.2.0 - 2025-10-23

### Added
- Fully resilient JSON parsing utilities for Dart/Flutter.
- Safe scalar parsing methods:
  - Non-nullable: `string`, `integer`, `double_`, `boolean`, `number`
  - Nullable: `stringN`, `integerN`, `doubleN`, `booleanN`, `numberN`
- DateTime parsing: `dateTime` and `dateTimeN` (supports ISO & epoch-millis)
- Enum parsing helper: `enumValue` with fallback
- Deep getter for nested maps/lists: `JSafe.getAt(map, 'a.b[0].c')`
- List mapping helper: `JSafe.mapList`
- Recursive null-omitting helper: `JSafe.omitNulls`
- Debug & strict mode toggles: `JSafe.debugLogs` and `JSafe.strictThrow`

### Changed
- Method names updated from old aliases (`str/int_/dbl/bool_/num_`) to more descriptive names.

### Fixed
- Improved parsing of numeric strings with commas (e.g., `"1,234.56"`)
- Safe handling of nulls, type mismatches, and malformed JSON
