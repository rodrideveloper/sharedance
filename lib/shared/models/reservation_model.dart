import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reservation_model.g.dart';

enum ReservationStatus {
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('completed')
  completed,
}

@JsonSerializable()
class ReservationModel extends Equatable {
  final String reservationId;
  final String userId;
  final String classId;
  final DateTime date;
  final ReservationStatus status;
  final DateTime createdAt;

  const ReservationModel({
    required this.reservationId,
    required this.userId,
    required this.classId,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) =>
      _$ReservationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReservationModelToJson(this);

  ReservationModel copyWith({
    String? reservationId,
    String? userId,
    String? classId,
    DateTime? date,
    ReservationStatus? status,
    DateTime? createdAt,
  }) {
    return ReservationModel(
      reservationId: reservationId ?? this.reservationId,
      userId: userId ?? this.userId,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    reservationId,
    userId,
    classId,
    date,
    status,
    createdAt,
  ];
}
