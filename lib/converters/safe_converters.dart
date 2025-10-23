import 'package:jsafe/jsafe.dart';
import 'package:json_annotation/json_annotation.dart';

/// Non-nullable converters using JSafe defaults
class SafeInt implements JsonConverter<int, Object?> {
  const SafeInt();
  @override
  int fromJson(Object? json) => JSafe.integer(json);
  @override
  Object? toJson(int object) => object;
}

class SafeString implements JsonConverter<String, Object?> {
  const SafeString();
  @override
  String fromJson(Object? json) => JSafe.string(json);
  @override
  Object? toJson(String object) => object;
}

class SafeBool implements JsonConverter<bool, Object?> {
  const SafeBool();
  @override
  bool fromJson(Object? json) => JSafe.boolean(json);
  @override
  Object? toJson(bool object) => object;
}

class SafeDouble implements JsonConverter<double, Object?> {
  const SafeDouble();
  @override
  double fromJson(Object? json) => JSafe.double_(json);
  @override
  Object? toJson(double object) => object;
}

class SafeDateTime implements JsonConverter<DateTime, Object?> {
  const SafeDateTime();
  @override
  DateTime fromJson(Object? json) => JSafe.dateTime(json);
  @override
  Object? toJson(DateTime object) => object.toIso8601String();
}

/// Nullable variants
class SafeIntN implements JsonConverter<int?, Object?> {
  const SafeIntN();
  @override
  int? fromJson(Object? json) => JSafe.integerN(json);
  @override
  Object? toJson(int? object) => object;
}

class SafeStringN implements JsonConverter<String?, Object?> {
  const SafeStringN();
  @override
  String? fromJson(Object? json) => JSafe.stringN(json);
  @override
  Object? toJson(String? object) => object;
}

class SafeBoolN implements JsonConverter<bool?, Object?> {
  const SafeBoolN();
  @override
  bool? fromJson(Object? json) => JSafe.booleanN(json);
  @override
  Object? toJson(bool? object) => object;
}

class SafeDoubleN implements JsonConverter<double?, Object?> {
  const SafeDoubleN();
  @override
  double? fromJson(Object? json) => JSafe.doubleN(json);
  @override
  Object? toJson(double? object) => object;
}

class SafeDateTimeN implements JsonConverter<DateTime?, Object?> {
  const SafeDateTimeN();
  @override
  DateTime? fromJson(Object? json) => JSafe.dateTimeN(json);
  @override
  Object? toJson(DateTime? object) => object?.toIso8601String();
}
