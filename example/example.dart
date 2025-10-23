import 'dart:convert';
import 'package:jsafe/jsafe.dart';

void main() {
  JSafe.setMode(debug: true, strict: false);

  final payload = jsonDecode('''
{
"statusCode": 200,
"isSuccess": "true",
"message": "ok",
"paymentMethods": [
{
"PaymentMethodId": "101",
"PaymentMethodCode": 7,
"TotalAmount": 1299,
"ImageUrl": null,
}
]
}
''');

  final model = GetPaymentMethodsModel.fromJson(payload);
  print(model.paymentMethods.first.paymentMethodId);
}

class GetPaymentMethodsModel {
  final int statusCode;
  final bool isSuccess;
  final String message;
  final List<PaymentMethod> paymentMethods;

  const GetPaymentMethodsModel({
    required this.statusCode,
    required this.isSuccess,
    required this.message,
    required this.paymentMethods,
  });
  factory GetPaymentMethodsModel.fromJson(Map<String, dynamic> json) {
    final map = JSafe.map(json);
    return GetPaymentMethodsModel(
      statusCode: JSafe.integer(map['statusCode']),
      isSuccess: JSafe.boolean(map['isSuccess']),
      message: JSafe.string(map['message']),
      paymentMethods: JSafe.mapList(
        map['paymentMethods'],
        (e) => PaymentMethod.fromJson(JSafe.map(e)),
      ),
    );
  }

  Map<String, dynamic> toJson() => JSafe.omitNulls({
        'statusCode': statusCode,
        'isSuccess': isSuccess,
        'message': message,
        'paymentMethods': paymentMethods.map((x) => x.toJson()).toList(),
      });
}

class PaymentMethod {
  final int paymentMethodId;
  final String paymentMethodCode;
  final int totalAmount;
  final String imageUrl;

  const PaymentMethod({
    required this.paymentMethodId,
    required this.paymentMethodCode,
    required this.totalAmount,
    required this.imageUrl,
  });
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final m = JSafe.map(json);
    return PaymentMethod(
      paymentMethodId: JSafe.integer(m['PaymentMethodId']),
      paymentMethodCode: JSafe.string(m['PaymentMethodCode']),
      totalAmount: JSafe.integer(m['TotalAmount']),
      imageUrl: JSafe.string(m['ImageUrl']),
    );
  }

  Map<String, dynamic> toJson() => JSafe.omitNulls({
        'PaymentMethodId': paymentMethodId,
        'PaymentMethodCode': paymentMethodCode,
        'TotalAmount': totalAmount,
        'ImageUrl': imageUrl,
      });
}
