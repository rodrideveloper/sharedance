import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'purchase_model.g.dart';

@JsonSerializable()
class PurchaseModel extends Equatable {
  final String purchaseId;
  final String userId;
  final String packId;
  final int creditsAdded;
  final double pricePaid;
  final DateTime createdAt;

  const PurchaseModel({
    required this.purchaseId,
    required this.userId,
    required this.packId,
    required this.creditsAdded,
    required this.pricePaid,
    required this.createdAt,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) =>
      _$PurchaseModelFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseModelToJson(this);

  PurchaseModel copyWith({
    String? purchaseId,
    String? userId,
    String? packId,
    int? creditsAdded,
    double? pricePaid,
    DateTime? createdAt,
  }) {
    return PurchaseModel(
      purchaseId: purchaseId ?? this.purchaseId,
      userId: userId ?? this.userId,
      packId: packId ?? this.packId,
      creditsAdded: creditsAdded ?? this.creditsAdded,
      pricePaid: pricePaid ?? this.pricePaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    purchaseId,
    userId,
    packId,
    creditsAdded,
    pricePaid,
    createdAt,
  ];
}
