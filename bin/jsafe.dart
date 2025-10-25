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

    String? className;
    String filePath;

    if (rest == null || rest.isEmpty) {
      print('Usage: jsafe create [ClassName] <file_path>');
      exit(1);
    }

    if (rest.length == 1) {
      // No class name provided, infer from file path
      filePath = rest[0];
      className = _getClassNameFromFile(filePath);
    } else {
      // Class name is provided as the first argument
      className = _formatClassName(rest[0]);
      filePath = rest[1];
    }

    createModel(filePath, className);
  } else {
    print('Usage: jsafe create [ClassName] <file_path>');
  }
}

void createModel(String filePath, String className) {
  final file = File(filePath);

  if (!file.existsSync()) {
    print('File not found: $filePath');
    exit(1);
  }

  final content = file.readAsStringSync();

  // --- START OF MODIFIED LOGIC ---

  Map<String, dynamic> jsonMap; // The map we'll use to generate the model
  dynamic decodedJson;

  try {
    decodedJson = json.decode(content);
  } catch (e) {
    print('Invalid JSON in file: $filePath');
    print('Error: $e');
    exit(1);
  }

  if (decodedJson is Map<String, dynamic>) {
    // Standard case: JSON file is a map
    jsonMap = decodedJson;
  } else if (decodedJson is List) {
    // New case: JSON file is a list
    if (decodedJson.isEmpty) {
      print('Error: JSON file contains an empty list. Cannot infer model.');
      exit(1);
    }

    final firstElement = decodedJson.first;
    if (firstElement is Map<String, dynamic>) {
      print(
          'Note: JSON root is a list. Using first element to generate model...');
      jsonMap = firstElement;
    } else {
      print(
          'Error: JSON file is a list, but its items are not maps (e.g., List<String>).');
      exit(1);
    }
  } else {
    // Error case: JSON is just a string, number, etc.
    print(
        'Error: JSON file must contain a Map ({...}) or a List of Maps ([{...}]).');
    exit(1);
  }

  // --- END OF MODIFIED LOGIC ---

  // Pass the determined className and jsonMap to the generator
  final modelCode = ModelGenerator.generate(className, jsonMap);

  file.writeAsStringSync(modelCode);
  print('Model generated: $filePath');
}

/// Gets the class name from the file path.
String _getClassNameFromFile(String path) {
  final baseName =
      p.basenameWithoutExtension(path); // e.g., "user_model" or "user"
  return _formatClassName(baseName);
}

/// Formats a base string (from arg or file) into a valid PascalCase class name.
String _formatClassName(String baseName) {
  String tempName = baseName;

  // Pre-process the name to fix cases like 'usermodel'
  // If the name is all lowercase and ends with 'model' (but isn't just 'model')
  // convert it to snake_case, so 'usermodel' becomes 'user_model'.
  if (tempName == tempName.toLowerCase() &&
      tempName.endsWith('model') &&
      tempName.length > 5) {
    // 5 == 'model'.length
    tempName =
        '${tempName.substring(0, tempName.length - 5)}_model'; // 'user' + '_model'
  }

  // Convert snake_case or pre-processed name to PascalCase
  final words = tempName.split(RegExp(r'[_\s]+'));
  final pascalCase = words
      .map(
        // Capitalize first letter, but DON'T lowercase the rest
        // This correctly handles "userModel" -> "UserModel"
        (w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '',
      )
      .join();

  final lowerBase = baseName.toLowerCase();

  // If the original name didn't end with '_model' or 'model'
  // and the new name doesn't end with 'Model', append it.
  if (!lowerBase.endsWith('_model') &&
      !lowerBase.endsWith('model') &&
      !pascalCase.endsWith('Model')) {
    return '${pascalCase}Model'; // e.g., "User" -> "UserModel"
  }

  return pascalCase; // e.g., "UserModel", "PostModel"
}
