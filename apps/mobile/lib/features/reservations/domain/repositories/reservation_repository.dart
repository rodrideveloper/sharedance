import 'package:shared_models/shared_models.dart';

abstract class ReservationRepository {
  Stream<List<ReservationModel>> getReservationsStream(String userId);

  Future<List<ReservationModel>> getUserReservations(String userId);

  Stream<List<ReservationModel>> getClassReservations(String classId);

  Future<void> createReservation(ReservationModel reservation);

  Future<void> cancelReservation(String reservationId);

  Future<void> updateReservationStatus(
    String reservationId,
    ReservationStatus status,
  );

  Future<bool> hasUserReservedClass(
    String userId,
    String classId,
    DateTime date,
  );

  Future<int> getReservationCount(String classId, DateTime date);

  Future<List<ReservationModel>> getReservationsForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
}
