import 'package:jsafe/converters/safe_converters.dart';
import 'package:json_annotation/json_annotation.dart';
part 'payment_method.g.dart';

@JsonSerializable(explicitToJson: true)
class PaymentMethod {
  @SafeInt()
  final int paymentMethodId;
  @SafeString()
  final String paymentMethodCode;
  @SafeInt()
  final int totalAmount;
  @SafeString()
  final String imageUrl;

  const PaymentMethod({
    required this.paymentMethodId,
    required this.paymentMethodCode,
    required this.totalAmount,
    required this.imageUrl,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentMethodToJson(this);
}
