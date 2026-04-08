import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tekora_app_absensi/models/attendence_model.dart';
import 'package:tekora_app_absensi/services/api/endpoint.dart';

class AttendanceService {
  Future<List<AttendanceModel>> fetchHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse(Endpoint.history),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> historyList = decodedData['data'];
        return historyList
            .map((item) => AttendanceModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Gagal memuat riwayat');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> postCheckIn({
    required String token,
    required String attendanceDate,
    required String checkInTime,
    required double lat,
    required double lng,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse(Endpoint.checkIn),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "attendance_date": attendanceDate,
        "check_in": checkInTime,
        "check_in_lat": lat.toString(),
        "check_in_lng": lng.toString(),
        "check_in_location": "$lat,$lng",
        "check_in_address": address,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw jsonDecode(response.body)['message'] ?? "Gagal Check In";
    }
  }

  Future<void> postCheckOut({
    required String token,
    required String attendanceDate,
    required String checkOutTime,
    required double lat,
    required double lng,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse(Endpoint.checkOut),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "attendance_date": attendanceDate,
        "check_out": checkOutTime,
        "check_out_lat": lat.toString(),
        "check_out_lng": lng.toString(),
        "check_out_location": "$lat,$lng",
        "check_out_address": address,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw jsonDecode(response.body)['message'] ?? "Gagal Check Out";
    }
  }
}
