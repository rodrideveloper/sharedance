import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_model.g.dart';

@JsonSerializable()
class ReportModel extends Equatable {
  final String reportId;
  final String month; // "2024-01"
  final String professorId;
  final int totalStudents;
  final double amountToPay;
  final DateTime createdAt;

  const ReportModel({
    required this.reportId,
    required this.month,
    required this.professorId,
    required this.totalStudents,
    required this.amountToPay,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) =>
      _$ReportModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReportModelToJson(this);

  ReportModel copyWith({
    String? reportId,
    String? month,
    String? professorId,
    int? totalStudents,
    double? amountToPay,
    DateTime? createdAt,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      month: month ?? this.month,
      professorId: professorId ?? this.professorId,
      totalStudents: totalStudents ?? this.totalStudents,
      amountToPay: amountToPay ?? this.amountToPay,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    reportId,
    month,
    professorId,
    totalStudents,
    amountToPay,
    createdAt,
  ];
}
