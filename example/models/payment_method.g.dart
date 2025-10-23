// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentMethod _$PaymentMethodFromJson(Map<String, dynamic> json) =>
    PaymentMethod(
      paymentMethodId: const SafeInt().fromJson(json['paymentMethodId']),
      paymentMethodCode: const SafeString().fromJson(json['paymentMethodCode']),
      totalAmount: const SafeInt().fromJson(json['totalAmount']),
      imageUrl: const SafeString().fromJson(json['imageUrl']),
    );

Map<String, dynamic> _$PaymentMethodToJson(
  PaymentMethod instance,
) =>
    <String, dynamic>{
      'paymentMethodId': const SafeInt().toJson(instance.paymentMethodId),
      'paymentMethodCode':
          const SafeString().toJson(instance.paymentMethodCode),
      'totalAmount': const SafeInt().toJson(instance.totalAmount),
      'imageUrl': const SafeString().toJson(instance.imageUrl),
    };
