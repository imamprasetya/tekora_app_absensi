import 'package:tekora_app_absensi/models/attendence_model.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  Future<List<AttendanceModel>> fetchHistory(String token) async {
    // pura-puranya ambil data history absensi dari server
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate some mock history for the last 5 days
    List<AttendanceModel> history = [];
    final today = DateTime.now();
    for (int i = 0; i < 5; i++) {
      final date = today.subtract(Duration(days: i));
      history.add(
        AttendanceModel(
          id: i + 1,
          attendanceDate: date,
          checkInTime: '08:00',
          checkOutTime: '17:00',
          status: 'Masuk',
        ),
      );
    }
    return history;
  }

  Future<void> postCheckIn({
    required String token,
    required String attendanceDate,
    required String checkInTime,
    required double lat,
    required double lng,
    required String address,
  }) async {
    // pura-puranya nembak API checkin sukses
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> postCheckOut({
    required String token,
    required String attendanceDate,
    required String checkOutTime,
    required double lat,
    required double lng,
    required String address,
  }) async {
    // pura-puranya nembak API checkout sukses
    await Future.delayed(const Duration(seconds: 1));
  }
}
