/// A robust, fail-soft JSON helper for Dart/Flutter.
///
/// - Tolerates nulls and type mismatches
/// - Nullable and non-nullable getters (with defaults)
/// - DateTime parsing (ISO or epoch millis)
/// - Enum parsing with fallback
/// - Deep path getter (e.g., "a.b[0].c")
/// - List mapping helpers
/// - Null-omitting toJson helper
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
      final v = fn();
      if (v is num && (v.isNaN || v.isInfinite)) return fallback;
      return v;
    } catch (e) {
      if (debugLogs) {
        // ignore: avoid_print
        print('JSafe($hint): $e');
      }
      if (strictThrow) rethrow;
      return fallback;
    }
  }

  // ---------- Scalars (non-nullable with default) ----------
  static String str(dynamic v, {String orDefault = ''}) => _wrap(
    () {
      if (v == null) return orDefault;
      if (v is String) return v;
      return v.toString();
    },
    orDefault,
    'str',
  );

  static int int_(dynamic v, {int orDefault = 0}) => _wrap(
    () {
      if (v == null) return orDefault;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? orDefault;
      if (v is bool) return v ? 1 : 0;
      return orDefault;
    },
    orDefault,
    'int_',
  );

  static double dbl(dynamic v, {double orDefault = 0.0}) => _wrap(
    () {
      if (v == null) return orDefault;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) {
        final s = v.trim().replaceAll(',', '');
        return double.tryParse(s) ?? orDefault;
      }
      if (v is bool) return v ? 1.0 : 0.0;
      return orDefault;
    },
    orDefault,
    'dbl',
  );

  static bool bool_(dynamic v, {bool orDefault = false}) => _wrap(
    () {
      if (v == null) return orDefault;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.trim().toLowerCase();
        return s == 'true' || s == '1' || s == 'yes' || s == 'y';
      }
      return orDefault;
    },
    orDefault,
    'bool_',
  );

  static num num_(dynamic v, {num orDefault = 0}) => _wrap(
    () {
      if (v == null) return orDefault;
      if (v is num) return (v.isNaN || v.isInfinite) ? orDefault : v;
      if (v is String) {
        final s = v.trim().replaceAll(',', '');
        final n = num.tryParse(s);
        return (n == null || n.isNaN || n.isInfinite) ? orDefault : n;
      }
      if (v is bool) return v ? 1 : 0;
      return orDefault;
    },
    orDefault,
    'num_',
  );
  // ---------- Nullable variants ----------
  static String? strN(dynamic v) => v == null ? null : str(v);
  static int? intN(dynamic v) => v == null ? null : int_(v);
  static double? dblN(dynamic v) => v == null ? null : dbl(v);
  static bool? boolN(dynamic v) => v == null ? null : bool_(v);

  // ---------- DateTime ----------
  static DateTime dt(dynamic v, {DateTime? orDefault}) => _wrap(
    () {
      if (v == null) return orDefault ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          final n = int.tryParse(v);
          if (n != null) return DateTime.fromMillisecondsSinceEpoch(n);
        }
      }
      return orDefault ?? DateTime.fromMillisecondsSinceEpoch(0);
    },
    orDefault ?? DateTime.fromMillisecondsSinceEpoch(0),
    'dt',
  );

  static DateTime? dtN(dynamic v) => v == null ? null : dt(v);

  // ---------- Map & List ----------
  static Map<String, dynamic> map(dynamic v) => _wrap(
    () {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val));
      }
      return <String, dynamic>{};
    },
    <String, dynamic>{},
    'map',
  );

  static List<T> list<T>(dynamic v) => _wrap(
    () {
      if (v is List<T>) return v;
      if (v is List) {
        return v.map((e) => e as T).toList();
      }
      return <T>[];
    },
    <T>[],
    'list',
  );

  /// Map a list of dynamic items to models.
  static List<T> mapList<T>(dynamic v, T Function(dynamic) convert) {
    final raw = list<dynamic>(v);
    final out = <T>[];
    for (final e in raw) {
      out.add(_wrap(() => convert(e), (null as T), 'mapList'));
    }
    return out.where((e) => e != null).toList();
  }

  // ---------- Enum ----------
  static T enum_<T>(
    dynamic v,
    List<T> values,
    T orDefault, {
    String Function(T)? toKey,
    bool caseInsensitive = true,
  }) {
    final key = str(v);
    if (key.isEmpty) return orDefault;
    final norm = caseInsensitive ? key.toLowerCase() : key;
    for (final val in values) {
      final k = toKey != null ? toKey(val) : val.toString().split('.').last;
      final kn = caseInsensitive ? k.toLowerCase() : k;
      if (kn == norm) return val;
    }
    return orDefault;
  }

  static dynamic getAt(Map<String, dynamic> m, String path) {
    dynamic cur = m;
    for (final seg in path.split('.')) {
      if (cur is Map) {
        final matchIndex = RegExp(r'(\w+)(\[(\d+)\])?').firstMatch(seg);
        if (matchIndex == null) return null;
        final key = matchIndex.group(1)!;
        cur = (cur)[key];
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

  /// Remove nulls recursively for `toJson`.
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
