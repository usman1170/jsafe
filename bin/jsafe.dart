import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:jsafe/src/model_generator.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) {
  final parser = ArgParser();
  parser.addCommand('create');

  final argResults = parser.parse(arguments);

  if (argResults.command?.name == 'create') {
    final rest = argResults.command?.rest;
    if (rest == null || rest.isEmpty) {
      print('Usage: jsafe create <file_path>');
      exit(1);
    }

    final filePath = rest[0];
    createModel(filePath);
  } else {
    print('Usage: jsafe create <file_path>');
  }
}

void createModel(String filePath) {
  final file = File(filePath);

  if (!file.existsSync()) {
    print('File not found: $filePath');
    exit(1);
  }

  final content = file.readAsStringSync();

  Map<String, dynamic> jsonMap;
  try {
    jsonMap = json.decode(content) as Map<String, dynamic>;
  } catch (e) {
    print('Invalid JSON in file: $filePath');
    exit(1);
  }

  final className = _getClassNameFromFile(filePath);

  final modelCode = ModelGenerator.generate(className, jsonMap);

  file.writeAsStringSync(modelCode);
  print('Model generated: $filePath');
}

/// Converts the file name to PascalCase for class naming
String _getClassNameFromFile(String path) {
  final name = p.basenameWithoutExtension(path);

  // Convert to PascalCase
  final words = name.split(RegExp(r'[_\s]+'));
  final pascalCase = words
      .map(
        (w) => w.isNotEmpty
            ? w[0].toUpperCase() + w.substring(1).toLowerCase()
            : '',
      )
      .join();

  return pascalCase;
}
