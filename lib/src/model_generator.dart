// lib/src/model_generator.dart

class ModelGenerator {
  static final _generatedClasses = <String>{};

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
      buffer.writeln('  final $type $key;');
    });

    // Constructor
    buffer.writeln('\n  $className({');
    json.forEach((key, value) {
      buffer.writeln('    required this.$key,');
    });
    buffer.writeln('  });\n');

    // copyWith
    buffer.writeln('  $className copyWith({');
    json.forEach((key, value) {
      final type = _inferType(key, value, [], prefix: prefix);
      buffer.writeln('    $type? $key,');
    });
    buffer.writeln('  }) {');
    buffer.writeln('    return $className(');
    json.forEach((key, value) {
      buffer.writeln('      $key: $key ?? this.$key,');
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
      buffer.writeln('      $key: ${_fromJsonExpression(key, value, type)},');
    });
    buffer.writeln('    );');
    buffer.writeln('  }\n');

    // toJson
    buffer.writeln('  Map<String, dynamic> toJson() => {');
    json.forEach((key, value) {
      buffer.writeln('    \'$key\': $key,');
    });
    buffer.writeln('  };');

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
      ['int', 'double', 'String', 'bool', 'num'].contains(type);

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
}
