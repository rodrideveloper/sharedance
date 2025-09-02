import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'class_model.g.dart';

@JsonSerializable()
class ClassSchedule extends Equatable {
  final String dayOfWeek; // "monday", "tuesday", etc.
  final String startTime; // "10:00"
  final String endTime; // "11:30"

  const ClassSchedule({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) =>
      _$ClassScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$ClassScheduleToJson(this);

  @override
  List<Object?> get props => [dayOfWeek, startTime, endTime];
}

@JsonSerializable()
class ClassModel extends Equatable {
  final String classId;
  final String name;
  final String professorId;
  final String roomId;
  final List<ClassSchedule> schedule;
  final int maxStudents;
  final bool isActive;
  final DateTime createdAt;
  final String? description;
  final String? imageUrl;

  const ClassModel({
    required this.classId,
    required this.name,
    required this.professorId,
    required this.roomId,
    required this.schedule,
    required this.maxStudents,
    required this.isActive,
    required this.createdAt,
    this.description,
    this.imageUrl,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) =>
      _$ClassModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClassModelToJson(this);

  ClassModel copyWith({
    String? classId,
    String? name,
    String? professorId,
    String? roomId,
    List<ClassSchedule>? schedule,
    int? maxStudents,
    bool? isActive,
    DateTime? createdAt,
    String? description,
    String? imageUrl,
  }) {
    return ClassModel(
      classId: classId ?? this.classId,
      name: name ?? this.name,
      professorId: professorId ?? this.professorId,
      roomId: roomId ?? this.roomId,
      schedule: schedule ?? this.schedule,
      maxStudents: maxStudents ?? this.maxStudents,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
    classId,
    name,
    professorId,
    roomId,
    schedule,
    maxStudents,
    isActive,
    createdAt,
    description,
    imageUrl,
  ];
}
