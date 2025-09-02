import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_model.g.dart';

@JsonSerializable()
class PackModel extends Equatable {
  final String packId;
  final String name;
  final int credits;
  final double price;
  final DateTime createdAt;
  final String? description;

  const PackModel({
    required this.packId,
    required this.name,
    required this.credits,
    required this.price,
    required this.createdAt,
    this.description,
  });

  factory PackModel.fromJson(Map<String, dynamic> json) =>
      _$PackModelFromJson(json);

  Map<String, dynamic> toJson() => _$PackModelToJson(this);

  PackModel copyWith({
    String? packId,
    String? name,
    int? credits,
    double? price,
    DateTime? createdAt,
    String? description,
  }) {
    return PackModel(
      packId: packId ?? this.packId,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
    packId,
    name,
    credits,
    price,
    createdAt,
    description,
  ];
}
