import 'package:jsafe/jsafe.dart';

extension JsonX on Map<String, dynamic> {
  String s(String k, {String orDefault = ''}) =>
      JSafe.string(this[k], orDefault: orDefault);
  int i(String k, {int orDefault = 0}) =>
      JSafe.integer(this[k], orDefault: orDefault);
  double d(String k, {double orDefault = 0.0}) =>
      JSafe.double_(this[k], orDefault: orDefault);
  bool b(String k, {bool orDefault = false}) =>
      JSafe.boolean(this[k], orDefault: orDefault);
  Map<String, dynamic> m(String k) => JSafe.map(this[k]);
  List<T> l<T>(String k) => JSafe.list<T>(this[k]);
  DateTime t(String k, {DateTime? orDefault}) =>
      JSafe.dateTime(this[k], orDefault: orDefault);
}
