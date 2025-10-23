/// A robust, fail-soft JSON helper for Dart/Flutter.
///
/// JSafe provides resilient JSON parsing utilities to safely extract values
/// without crashing on type mismatches, nulls, or malformed data.
///
/// ✅ Safe parsing for all primitives
/// ✅ Null and default fallbacks
/// ✅ Deep path access (e.g. `"user.address[0].city"`)
/// ✅ DateTime, Enum, and List mapping utilities
/// ✅ Recursive null-omitting `toJson` helper
class JSafe {
  /// When true, log type mismatches.
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
      if (value is num && (value.isNaN || value.isInfinite)) return fallback;
      return value;
    } catch (e) {
      if (debugLogs) {
        // ignore: avoid_print
        print('JSafe($hint): $e');
      }
      if (strictThrow) rethrow;
      return fallback;
    }
  }

  // --------------------------------------------------------
  // 🧩 Scalars (non-nullable with defaults)
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
            return ['true', '1', 'yes', 'y'].contains(s);
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
            return (n == null || n.isNaN || n.isInfinite) ? orDefault : n;
          }
          if (value is bool) return value ? 1 : 0;
          return orDefault;
        },
        orDefault,
        'number',
      );

  // --------------------------------------------------------
  // 🌫️ Nullable variants
  // --------------------------------------------------------

  static String? stringN(dynamic v) => v == null ? null : string(v);
  static int? integerN(dynamic v) => v == null ? null : integer(v);
  static double? doubleN(dynamic v) => v == null ? null : double_(v);
  static bool? booleanN(dynamic v) => v == null ? null : boolean(v);
  static num? numberN(dynamic v) => v == null ? null : number(v);

  // --------------------------------------------------------
  // 🕒 DateTime parsing
  // --------------------------------------------------------

  static DateTime dateTime(dynamic value, {DateTime? orDefault}) => _wrap(
        () {
          if (value == null) {
            return orDefault ?? DateTime.fromMillisecondsSinceEpoch(0);
          }
          if (value is DateTime) return value;
          if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
          if (value is String) {
            try {
              return DateTime.parse(value);
            } catch (_) {
              final n = int.tryParse(value);
              if (n != null) return DateTime.fromMillisecondsSinceEpoch(n);
            }
          }
          return orDefault ?? DateTime.fromMillisecondsSinceEpoch(0);
        },
        orDefault ?? DateTime.fromMillisecondsSinceEpoch(0),
        'dateTime',
      );

  static DateTime? dateTimeN(dynamic v) => v == null ? null : dateTime(v);

  // --------------------------------------------------------
  // 🗺️ Map & List helpers
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

  static List<T> list<T>(dynamic value) => _wrap(
        () {
          if (value is List<T>) return value;
          if (value is List) return value.cast<T>();
          return <T>[];
        },
        <T>[],
        'list',
      );

  static List<T> mapList<T>(dynamic v, T Function(dynamic) convert) {
    final raw = list<dynamic>(v);
    final out = <T>[];
    for (final e in raw) {
      out.add(_wrap(() => convert(e), (null as T), 'mapList'));
    }
    return out.where((e) => e != null).toList();
  }

  // --------------------------------------------------------
  // 🧱 Enum helpers
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
  // 🔍 Deep getter
  // --------------------------------------------------------

  static dynamic getAt(Map<String, dynamic> m, String path) {
    dynamic cur = m;
    for (final seg in path.split('.')) {
      if (cur is Map) {
        final matchIndex = RegExp(r'(\w+)(\[(\d+)\])?').firstMatch(seg);
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
  // 🧹 JSON cleanup
  // --------------------------------------------------------

  /// Removes all null values recursively from the given map.
  static Map<String, dynamic> omitNulls(Map<String, dynamic> map) {
    final out = <String, dynamic>{};
    map.forEach((k, v) {
      if (v == null) return;
      if (v is Map<String, dynamic>) {
        final nested = omitNulls(v);
        if (nested.isNotEmpty) out[k] = nested;
      } else if (v is List) {
        out[k] = v.where((e) => e != null).toList();
      } else {
        out[k] = v;
      }
    });
    return out;
  }
}
