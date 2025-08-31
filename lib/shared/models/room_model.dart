import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'room_model.g.dart';

@JsonSerializable()
class RoomModel extends Equatable {
  final String roomId;
  final String name;
  final int capacity;
  final DateTime createdAt;

  const RoomModel({
    required this.roomId,
    required this.name,
    required this.capacity,
    required this.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) =>
      _$RoomModelFromJson(json);

  Map<String, dynamic> toJson() => _$RoomModelToJson(this);

  RoomModel copyWith({
    String? roomId,
    String? name,
    int? capacity,
    DateTime? createdAt,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [roomId, name, capacity, createdAt];
}
