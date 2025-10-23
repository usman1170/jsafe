# Changelog

All notable changes to this project will be documented in this file.

## 1.1.0 - 2025-10-23

### Added
- Fully resilient JSON parsing utilities for Dart/Flutter.
- Safe scalar parsing methods:
  - Non-nullable: `string`, `integer`, `double_`, `boolean`, `number`
  - Nullable: `stringN`, `integerN`, `doubleN`, `booleanN`, `numberN`
- DateTime parsing: `dateTime` and `dateTimeN` (supports ISO & epoch-millis)
- Enum parsing helper: `enumValue` with fallback
- Deep getter for nested maps/lists: `JSafe.getAt(map, 'a.b[0].c')`
- List mapping helper: `JSafe.mapList` for nested objects
- Recursive null-omitting helper: `JSafe.omitNulls`
- Debug & strict mode toggles: `JSafe.debugLogs` and `JSafe.strictThrow`
- CLI JSON-to-Dart model generator:
  - Generate nested Dart models automatically from JSON
  - Handles lists, nested objects, and non-nullable fields
  - Ensures fully serializable `toJson` output

### Changed
- Method names updated from old aliases (`str/int_/dbl/bool_/num_`) to more descriptive names.
- Updated README and docs to highlight CLI usage.
- **Dart SDK requirement updated** to `>=3.6.0 <4.0.0` to support Flutter 3.24 onward.
- Version-solving issues with older Flutter/Dart versions addressed.

### Fixed
- Improved parsing of numeric strings with commas (e.g., `"1,234.56"`)
- Safe handling of nulls, type mismatches, and malformed JSON
