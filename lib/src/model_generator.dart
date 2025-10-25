// lib/src/model_generator.dart

class ModelGenerator {
  static final _generatedClasses = <String>{};

  /// Regex to detect ISO 8601 timestamps.
  static final _iso8601Regex = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|([+-]\d{2}:\d{2}))?$',
  );

  /// Generates Dart code for the given className and JSON map
  static String generate(String className, Map<String, dynamic> json) {
    _generatedClasses.clear();
    final buffer = StringBuffer();

    // Add import at the very top (only once)
    buffer.writeln("import 'package:jsafe/jsafe.dart';\n");

    // Determine base prefix (strip 'Model' if present)
    final basePrefix = className.endsWith('Model')
        ? className.substring(0, className.length - 'Model'.length)
        : className;

    // Generate main class and nested classes recursively
    _generateClass(
      buffer,
      className,
      json,
      isTopLevel: true,
      prefix: basePrefix, // Use base prefix for nested models
    );

    return buffer.toString();
  }

  static void _generateClass(
    StringBuffer buffer,
    String className,
    Map<String, dynamic> json, {
    bool isTopLevel = false,
    required String prefix, // top-level prefix for nested models
  }) {
    if (_generatedClasses.contains(className)) return;
    _generatedClasses.add(className);

    final nestedBuffers = <StringBuffer>[];

    buffer.writeln('class $className {');

    // Fields
    json.forEach((key, value) {
      final type = _inferType(key, value, nestedBuffers, prefix: prefix);
      final dartField = _toCamelCase(key); // Convert to camelCase
      buffer.writeln('  final $type $dartField;');
    });

    // Constructor
    buffer.writeln('\n  $className({');
    json.forEach((key, value) {
      final dartField = _toCamelCase(key); // Convert to camelCase
      buffer.writeln('    required this.$dartField,');
    });
    buffer.writeln('  });\n');

    // copyWith
    buffer.writeln('  $className copyWith({');
    json.forEach((key, value) {
      final type = _inferType(key, value, [], prefix: prefix);
      final dartField = _toCamelCase(key); // Convert to camelCase
      buffer.writeln('    $type? $dartField,');
    });
    buffer.writeln('  }) {');
    buffer.writeln('    return $className(');
    json.forEach((key, value) {
      final dartField = _toCamelCase(key); // Convert to camelCase
      buffer.writeln('      $dartField: $dartField ?? this.$dartField,');
    });
    buffer.writeln('    );');
    buffer.writeln('  }\n');

    // fromJson
    buffer.writeln(
      '  factory $className.fromJson(Map<String, dynamic> json) {',
    );
    buffer.writeln('    return $className(');
    json.forEach((key, value) {
      final type = _inferType(key, value, [], prefix: prefix);
      final dartField = _toCamelCase(key); // Convert to camelCase
      // Use original 'key' for json lookup, but 'dartField' for assignment
      buffer.writeln(
          '      $dartField: ${_fromJsonExpression(key, value, type)},');
    });
    buffer.writeln('    );');
    buffer.writeln('  }\n');

    // --- START: MODIFIED toJson ---
    buffer.writeln('  Map<String, dynamic> toJson() => {');
    json.forEach((key, value) {
      final dartField = _toCamelCase(key);
      final type = _inferType(key, value, [], prefix: prefix);

      String toJsonExpression;
      if (type.startsWith('List<')) {
        final innerType = type.substring(5, type.length - 1);
        if (_isPrimitive(innerType)) {
          if (innerType == 'DateTime') {
            toJsonExpression =
                '$dartField.map((e) => e.toIso8601String()).toList()';
          } else {
            // Primitive lists (List<String>, List<int>) are fine as-is
            toJsonExpression = dartField;
          }
        } else {
          // List of custom objects
          toJsonExpression = '$dartField.map((e) => e.toJson()).toList()';
        }
      } else if (_isPrimitive(type)) {
        if (type == 'DateTime') {
          // Convert DateTime back to ISO 8601 string
          toJsonExpression = '$dartField.toIso8601String()';
        } else {
          // Primitives (String, int, bool, double) are fine as-is
          toJsonExpression = dartField;
        }
      } else if (type == 'dynamic') {
        toJsonExpression = dartField;
      } else {
        // Single custom object
        toJsonExpression = '$dartField.toJson()';
      }

      buffer.writeln('    \'$key\': $toJsonExpression,');
    });
    buffer.writeln('  };');
    // --- END: MODIFIED toJson ---

    buffer.writeln('}');

    // Append all nested classes after this class
    for (var b in nestedBuffers) {
      buffer.writeln('\n${b.toString()}');
    }
  }

  static String _inferType(
    String key,
    dynamic value,
    List<StringBuffer> nestedBuffers, {
    required String prefix,
  }) {
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';

    // Check for DateTime string BEFORE general String
    if (value is String && _iso8601Regex.hasMatch(value)) {
      return 'DateTime';
    }

    if (value is String) return 'String';

    if (value is Map<String, dynamic>) {
      final nestedClassName = _toPascalCase(
        '${prefix}_${key}Model',
      ); // Use base prefix
      final buf = StringBuffer();
      _generateClass(buf, nestedClassName, value, prefix: prefix);
      nestedBuffers.add(buf);
      return nestedClassName;
    }

    if (value is List) {
      if (value.isEmpty) return 'List<dynamic>';
      final first = value.first;

      if (first is Map<String, dynamic>) {
        final nestedClassName = _toPascalCase(
          '${prefix}_${key}Model',
        ); // Use base prefix
        final buf = StringBuffer();
        // Pass the first item to generate the class structure
        _generateClass(buf, nestedClassName, first, prefix: prefix);
        nestedBuffers.add(buf);
        return 'List<$nestedClassName>';
      } else {
        final itemType = _inferType(key, first, nestedBuffers, prefix: prefix);
        return 'List<$itemType>';
      }
    }

    return 'dynamic';
  }

  static String _fromJsonExpression(String key, dynamic value, String type) {
    if (type.startsWith('List<')) {
      final innerType = type.substring(5, type.length - 1);
      if (innerType == 'dynamic') return 'JSafe.list(json[\'$key\'])';
      if (_isPrimitive(innerType)) {
        return 'JSafe.mapList<$innerType>(json[\'$key\'], (e) => JSafe.${_jsafeMethod(innerType)}(e))';
      }
      return 'JSafe.mapList<$innerType>(json[\'$key\'], (e) => $innerType.fromJson(JSafe.map(e)))';
    } else if (_isPrimitive(type)) {
      return 'JSafe.${_jsafeMethod(type)}(json[\'$key\'])';
    } else if (type == 'dynamic') {
      return 'json[\'$key\']';
    } else {
      return '$type.fromJson(JSafe.map(json[\'$key\']))';
    }
  }

  static bool _isPrimitive(String type) =>
      ['int', 'double', 'String', 'bool', 'num', 'DateTime'].contains(type);

  static String _jsafeMethod(String type) {
    switch (type) {
      case 'int':
        return 'integer';
      case 'double':
        return 'double_';
      case 'bool':
        return 'boolean';
      case 'num':
        return 'number';
      case 'String':
        return 'string';
      case 'DateTime':
        return 'dateTime';
      default:
        return 'string';
    }
  }

  static String _toPascalCase(String input) {
    final words = input.split(RegExp(r'[_\s]+'));
    return words
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
        .join();
  }

  /// Converts a snake_case string to camelCase.
  static String _toCamelCase(String snakeCase) {
    if (snakeCase.isEmpty) {
      return snakeCase;
    }

    List<String> parts = snakeCase.split('_');

    if (parts.length == 1) {
      return snakeCase;
    }

    // Start with the first part (which is already lowercase)
    String camelCase = parts[0];

    // Iterate from the second part onwards
    for (int i = 1; i < parts.length; i++) {
      String part = parts[i];
      if (part.isNotEmpty) {
        // Capitalize the first letter and add the rest
        camelCase += part[0].toUpperCase() + part.substring(1);
      }
    }
    return camelCase;
  }
}
