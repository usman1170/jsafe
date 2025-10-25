# jsafe

Resilient JSON parsing utilities, `json_serializable` converters, and a **CLI JSON-to-Dart model generator** for Dart/Flutter.

---

## Why

Backends drift. Fields go null, types flip ("1" vs 1), arrays become singletons, etc. `jsafe` makes your parsing forgiving without hiding problems.

`jsafe` is perfect for Flutter and Dart projects that need **robust JSON parsing** with deep nesting, lists of objects, enums, and safe `DateTime` handling.  
It also comes with a **CLI generator** to create Dart models from JSON automatically, saving time and avoiding boilerplate.

---

## Highlights

- **Safe scalar parsing**:
  - Non-nullable: `string`, `integer`, `double_`, `boolean`, `number`
  - Nullable: `stringN`, `integerN`, `doubleN`, `booleanN`, `numberN`
- **ISO & epoch-millis `DateTime` parsing**: `dateTime` / `dateTimeN`
- **Enum parsing** with fallback: `enumValue`
- **Deep getter**: `JSafe.getAt(map, 'a.b[0].c')`
- **Nested lists**: `mapList` for nested lists of objects
- **Clean `toJson`**: `omitNulls` to remove nulls recursively
- **Debug & strict flags**: 
  - `JSafe.debugLogs` → prints parsing warnings
  - `JSafe.strictThrow` → throws exceptions on unexpected types
- **`json_serializable` converters** included
- **CLI support**: Generate Dart models from JSON with `jsafe` generator

---

# CLI Model Generator

A built-in **CLI tool** to automatically generate **Dart models from JSON** — included with `jsafe`.  
Easily convert raw JSON into clean, typed model classes with a single command.

---

## ⚙️ Installation

```bash
dart pub global activate jsafe
```

---

## ⚙️ CLI Usage

The `jsafe` CLI can generate Dart models directly from a Dart file that contains raw JSON data.

---

## 🧱 Basic Command

```bash
jsafe create path/to/file.dart
```

---

✅ Reads the JSON content inside input.dart  
✅ Automatically detects fields, lists, nested objects, etc.  
✅ Generates a new file in the same directory (e.g., input_model.dart)  
✅ Class name is derived from file name (InputModel)

---

## 🧩 CLI Examples

Below are all possible ways to use the `create` command — including the optional **model name** feature.

---

### Example 1 — Default usage (model name derived from file)

```bash
jsafe create path/to/user.dart
```

**Result:**
- File → `user_model.dart`
- Generated model class → `UserModel`

---

## 🎯 Example Output Models

Here's what the CLI generates - clean, typed Dart models with proper null safety and JSON serialization:

### 📱 User Model Example

**Input JSON in Dart file:**
```dart
{
  "id": "123",
  "name": "John Doe",
  "email": "john@example.com",
  "age": 28,
  "isActive": true,
  "profile": {
    "avatar": "https://example.com/avatar.jpg",
    "bio": "Software Developer"
  },
  "tags": ["developer", "flutter", "dart"],
  "lastLogin": "2024-01-15T10:30:00Z"
}
```

**Generated Model:**
```dart
// user_model.dart
import 'package:jsafe/jsafe.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final int age;
  final bool isActive;
  final UserProfileModel profile;
  final List<String> tags;
  final DateTime lastLogin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.isActive,
    required this.profile,
    required this.tags,
    required this.lastLogin,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    bool? isActive,
    UserProfileModel? profile,
    List<String>? tags,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      isActive: isActive ?? this.isActive,
      profile: profile ?? this.profile,
      tags: tags ?? this.tags,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: JSafe.string(json['id']),
      name: JSafe.string(json['name']),
      email: JSafe.string(json['email']),
      age: JSafe.integer(json['age']),
      isActive: JSafe.boolean(json['isActive']),
      profile: UserProfileModel.fromJson(JSafe.map(json['profile'])),
      tags: JSafe.mapList<String>(json['tags'], (e) => JSafe.string(e)),
      lastLogin: JSafe.dateTime(json['lastLogin']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'age': age,
    'isActive': isActive,
    'profile': profile.toJson(),
    'tags': tags,
    'lastLogin': lastLogin.toIso8601String(),
  };
}

class UserProfileModel {
  final String avatar;
  final String bio;

  UserProfileModel({
    required this.avatar,
    required this.bio,
  });

  UserProfileModel copyWith({
    String? avatar,
    String? bio,
  }) {
    return UserProfileModel(
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      avatar: JSafe.string(json['avatar']),
      bio: JSafe.string(json['bio']),
    );
  }

  Map<String, dynamic> toJson() => {
    'avatar': avatar,
    'bio': bio,
  };
}
```

---

## 🧭 CLI Help Reference

**Usage:**
```bash
jsafe create [ModelName] <input_file.dart>
```

**Arguments:**
- `ModelName` — Optional. Explicit model name for the generated class.
- `input_file.dart` — Path to Dart file containing JSON.

**Examples:**
```bash
jsafe create path/to/user.dart
jsafe create UserModel path/to/user.dart
jsafe create product path/to/product_data.dart
```

---

## More:

```dart
import 'package:jsafe/jsafe.dart';

final map = {
  'id': '42',
  'price': '1,299.95',
  'ok': 'true',
  'createdAt': '2025-10-22T08:15:30Z',
  'tags': ['new', 'sale'],
};

// Scalars
final id = JSafe.integer(map['id']);       // 42
final price = JSafe.double_(map['price']); // 1299.95
final ok = JSafe.boolean(map['ok']);       // true
final ts = JSafe.dateTime(map['createdAt']);

// Nullable variants
final maybeId = JSafe.integerN(map['id']);
final maybePrice = JSafe.doubleN(map['price']);

// Deep getter
final firstTag = JSafe.getAt(map, 'tags[0]'); // 'new'

// Map & List helpers
final mapValue = JSafe.map(map);
final listValue = JSafe.list(map['tags']);
final mappedList = JSafe.mapList<String>(map['tags'], (v) => JSafe.string(v));

// Enum parsing
enum Status { active, inactive, pending }
final status = JSafe.enumValue(
  'Active', 
  Status.values, 
  Status.inactive,
  caseInsensitive: true,
);

// Omit nulls recursively
final cleaned = JSafe.omitNulls({
  'a': null,
  'b': {'x': 1, 'y': null},
  'c': [1, null, 2],
});
// Result: {'b': {'x': 1}, 'c': [1, 2]}
```