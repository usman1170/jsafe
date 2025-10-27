// lib/jsafe.dart
// Hardened JSafe with strict-mode enforcement for list<T> primitive conversions.

/// A robust, fail-soft JSON helper for Dart/Flutter.
class JSafe {
  /// When true, log type mismatches and parse errors.
  static bool debugLogs = true;

  /// When true, rethrow parsing errors (useful in tests or local dev).
  static bool strictThrow = false;

  /// Convenience toggle to set both flags at once.
  static void setMode({required bool debug, required bool strict}) {
    debugLogs = debug;
    strictThrow = strict;
  }

  static T _wrap<T>(T Function() fn, T fallback, [String? hint]) {
    try {
      final value = fn();
      if (value is num) {
        if (value.isNaN || value.isInfinite) return fallback;
      }
      return value;
    } catch (e, st) {
      if (debugLogs) {
        // ignore: avoid_print
        print('JSafe($hint): $e\n$st');
      }
      if (strictThrow) rethrow;
      return fallback;
    }
  }

  // --------------------------------------------------------
  // Scalars (non-nullable with defaults)
  // --------------------------------------------------------

  static String string(dynamic value, {String orDefault = ''}) => _wrap(
        () {
          if (value == null) return orDefault;
          if (value is String) return value;
          return value.toString();
        },
        orDefault,
        'string',
      );

  static int integer(dynamic value, {int orDefault = 0}) => _wrap(
        () {
          if (value == null) return orDefault;
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) return int.tryParse(value.trim()) ?? orDefault;
          if (value is bool) return value ? 1 : 0;
          return orDefault;
        },
        orDefault,
        'integer',
      );

  static double double_(dynamic value, {double orDefault = 0.0}) => _wrap(
        () {
          if (value == null) return orDefault;
          if (value is double) return value;
          if (value is int) return value.toDouble();
          if (value is String) {
            final s = value.trim().replaceAll(',', '');
            return double.tryParse(s) ?? orDefault;
          }
          if (value is bool) return value ? 1.0 : 0.0;
          return orDefault;
        },
        orDefault,
        'double_',
      );

  static bool boolean(dynamic value, {bool orDefault = false}) => _wrap(
        () {
          if (value == null) return orDefault;
          if (value is bool) return value;
          if (value is num) return value != 0;
          if (value is String) {
            final s = value.trim().toLowerCase();
            return ['true', '1', 'yes', 'y', 'on'].contains(s);
          }
          return orDefault;
        },
        orDefault,
        'boolean',
      );

  static num number(dynamic value, {num orDefault = 0}) => _wrap(
        () {
          if (value == null) return orDefault;
          if (value is num) {
            return (value.isNaN || value.isInfinite) ? orDefault : value;
          }
          if (value is String) {
            final s = value.trim().replaceAll(',', '');
            final n = num.tryParse(s);
            return (n == null || ((n.isNaN || n.isInfinite))) ? orDefault : n;
          }
          if (value is bool) return value ? 1 : 0;
          return orDefault;
        },
        orDefault,
        'number',
      );

  // --------------------------------------------------------
  // Nullable variants
  // --------------------------------------------------------

  static String? stringN(dynamic v) => v == null ? null : string(v);
  static int? integerN(dynamic v) => v == null ? null : integer(v);
  static double? doubleN(dynamic v) => v == null ? null : double_(v);
  static bool? booleanN(dynamic v) => v == null ? null : boolean(v);
  static num? numberN(dynamic v) => v == null ? null : number(v);

  // --------------------------------------------------------
  // DateTime parsing (seconds vs ms heuristic)
  // --------------------------------------------------------

  static DateTime dateTime(dynamic value, {DateTime? orDefault}) => _wrap(
        () {
          final def = orDefault ?? DateTime.fromMillisecondsSinceEpoch(0);
          if (value == null) return def;
          if (value is DateTime) return value;

          if (value is int) {
            if (value.abs() < 100000000000) {
              return DateTime.fromMillisecondsSinceEpoch(value * 1000);
            } else {
              return DateTime.fromMillisecondsSinceEpoch(value);
            }
          }

          if (value is String) {
            final s = value.trim();

            // Try integer-epoch first (numeric-only string)
            final n = int.tryParse(s);
            if (n != null) {
              if (n.abs() < 100000000000) {
                return DateTime.fromMillisecondsSinceEpoch(n * 1000);
              } else {
                return DateTime.fromMillisecondsSinceEpoch(n);
              }
            }

            // Fall back to ISO parse
            try {
              return DateTime.parse(s);
            } catch (_) {
              final alt = double.tryParse(s.replaceAll(',', ''));
              if (alt != null) {
                final millis = alt.toInt();
                if (millis.abs() < 100000000000) {
                  return DateTime.fromMillisecondsSinceEpoch(millis * 1000);
                } else {
                  return DateTime.fromMillisecondsSinceEpoch(millis);
                }
              }
            }
          }

          return def;
        },
        orDefault ?? DateTime.fromMillisecondsSinceEpoch(0),
        'dateTime',
      );

  static DateTime? dateTimeN(dynamic v) => v == null ? null : dateTime(v);

  // --------------------------------------------------------
  // Map & List helpers (improved and strict-aware)
  // --------------------------------------------------------

  static Map<String, dynamic> map(dynamic value) => _wrap(
        () {
          if (value is Map<String, dynamic>) return value;
          if (value is Map) {
            return value.map((k, v) => MapEntry(k.toString(), v));
          }
          return <String, dynamic>{};
        },
        <String, dynamic>{},
        'map',
      );

  // helper: check whether primitive conversion is actually valid for strict mode
  static bool _primitiveConversionValidForStrict<T>(dynamic original) {
    if (original == null) return false;

    if (T == String) {
      // Any non-null original can be turned into a String
      return true;
    }

    if (T == int) {
      if (original is int) return true;
      if (original is double) return true;
      if (original is bool) return true;
      if (original is String) {
        return int.tryParse(original.trim()) != null;
      }
      return false;
    }

    if (T == double) {
      if (original is double) return true;
      if (original is int) return true;
      if (original is bool) return true;
      if (original is String) {
        final s = original.trim().replaceAll(',', '');
        return double.tryParse(s) != null;
      }
      return false;
    }

    if (T == bool) {
      if (original is bool) return true;
      if (original is num) return true;
      if (original is String) {
        final s = original.trim().toLowerCase();
        return ['true', '1', 'yes', 'y', 'on', 'false', '0', 'no', 'off']
            .contains(s);
      }
      return false;
    }

    if (T == num) {
      if (original is num) return true;
      if (original is String) {
        final s = original.trim().replaceAll(',', '');
        return num.tryParse(s) != null;
      }
      return false;
    }

    // For other generic/complex T we can't validate here.
    return false;
  }

  static List<T> list<T>(dynamic value) => _wrap(
        () {
          if (value is List<T>) return List<T>.from(value);

          if (value is List) {
            // Fast path: if every element is already T, return a copy.
            var allMatch = true;
            for (final e in value) {
              if (e is! T) {
                allMatch = false;
                break;
              }
            }
            if (allMatch) {
              return value.map((e) => e as T).toList();
            }

            // Otherwise element-wise conversion for primitives; skip complex types.
            final out = <T>[];
            for (final e in value) {
              if (e is T) {
                out.add(e);
                continue;
              }

              // Primitive conversions:
              try {
                if (T == String) {
                  final v = string(e);
                  if (strictThrow &&
                      !_primitiveConversionValidForStrict<T>(e)) {
                    throw FormatException(
                        'strict mode: cannot convert to String: $e');
                  }
                  out.add(v as T);
                  continue;
                }

                if (T == int) {
                  final v = integer(e);
                  if (strictThrow &&
                      !_primitiveConversionValidForStrict<T>(e)) {
                    throw FormatException(
                        'strict mode: cannot convert to int: $e');
                  }
                  out.add(v as T);
                  continue;
                }

                if (T == double) {
                  final v = double_(e);
                  if (strictThrow &&
                      !_primitiveConversionValidForStrict<T>(e)) {
                    throw FormatException(
                        'strict mode: cannot convert to double: $e');
                  }
                  out.add(v as T);
                  continue;
                }

                if (T == bool) {
                  final v = boolean(e);
                  if (strictThrow &&
                      !_primitiveConversionValidForStrict<T>(e)) {
                    throw FormatException(
                        'strict mode: cannot convert to bool: $e');
                  }
                  out.add(v as T);
                  continue;
                }

                if (T == num) {
                  final v = number(e);
                  if (strictThrow &&
                      !_primitiveConversionValidForStrict<T>(e)) {
                    throw FormatException(
                        'strict mode: cannot convert to num: $e');
                  }
                  out.add(v as T);
                  continue;
                }

                // complex types (models): can't auto-convert here — skip
              } catch (e) {
                // If conversion threw and strictThrow set, bubble up
                if (strictThrow) rethrow;
                // otherwise skip this element
              }
            }
            return out;
          }
          return <T>[];
        },
        <T>[],
        'list',
      );

  static List<String> stringList(dynamic v) =>
      list<dynamic>(v).map((e) => string(e)).toList();

  static List<int> intList(dynamic v) =>
      list<dynamic>(v).map((e) => integer(e)).toList();

  static List<double> doubleList(dynamic v) =>
      list<dynamic>(v).map((e) => double_(e)).toList();

  static List<T> mapList<T>(dynamic v, T Function(dynamic) convert) {
    final raw = list<dynamic>(v);
    final out = <T>[];
    for (final e in raw) {
      final converted = _wrap<T?>(() => convert(e), null, 'mapList');
      if (converted != null) out.add(converted);
    }
    return out;
  }

  // --------------------------------------------------------
  // Enum helpers
  // --------------------------------------------------------

  static T enumValue<T>(
    dynamic v,
    List<T> values,
    T orDefault, {
    String Function(T)? toKey,
    bool caseInsensitive = true,
  }) {
    final key = string(v);
    if (key.isEmpty) return orDefault;
    final norm = caseInsensitive ? key.toLowerCase() : key;
    for (final val in values) {
      final k = toKey != null ? toKey(val) : val.toString().split('.').last;
      final kn = caseInsensitive ? k.toLowerCase() : k;
      if (kn == norm) return val;
    }
    return orDefault;
  }

  // --------------------------------------------------------
  // Deep getter (broader key support)
  // --------------------------------------------------------

  static dynamic getAt(Map<String, dynamic> m, String path) {
    dynamic cur = m;
    for (final seg in path.split('.')) {
      if (cur is Map) {
        final matchIndex = RegExp(r'([^.\[\]]+)(\[(\d+)\])?').firstMatch(seg);
        if (matchIndex == null) return null;
        final key = matchIndex.group(1)!;
        cur = cur[key];
        final idxStr = matchIndex.group(3);
        if (idxStr != null) {
          if (cur is List) {
            final idx = int.tryParse(idxStr);
            if (idx == null || idx < 0 || idx >= cur.length) return null;
            cur = cur[idx];
          } else {
            return null;
          }
        }
      } else {
        return null;
      }
    }
    return cur;
  }

  // --------------------------------------------------------
  // JSON cleanup
  // --------------------------------------------------------

  static Map<String, dynamic> omitNulls(Map<String, dynamic> map) {
    final out = <String, dynamic>{};
    map.forEach((k, v) {
      if (v == null) return;
      if (v is Map<String, dynamic>) {
        final nested = omitNulls(v);
        if (nested.isNotEmpty) out[k] = nested;
      } else if (v is List) {
        final cleaned = <dynamic>[];
        for (final e in v) {
          if (e == null) continue;
          if (e is Map<String, dynamic>) {
            final nested = omitNulls(e);
            if (nested.isNotEmpty) cleaned.add(nested);
          } else if (e is List) {
            cleaned.add(_cleanListRecursively(e));
          } else {
            cleaned.add(e);
          }
        }
        out[k] = cleaned;
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  static List<dynamic> _cleanListRecursively(List list) {
    final out = <dynamic>[];
    for (final e in list) {
      if (e == null) continue;
      if (e is Map<String, dynamic>) {
        final nested = omitNulls(e);
        if (nested.isNotEmpty) out.add(nested);
      } else if (e is List) {
        out.add(_cleanListRecursively(e));
      } else {
        out.add(e);
      }
    }
    return out;
  }
}
