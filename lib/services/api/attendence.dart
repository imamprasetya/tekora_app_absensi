import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tekora_app_absensi/services/api/endpoint.dart';

Future<void> postCheckIn({
  required String token,
  required String attendanceDate,
  required String checkInTime,
  required double lat,
  required double lng,
  required String address,
}) async {
  final url = Uri.parse(Endpoint.checkIn);

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
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
      final errorData = jsonDecode(response.body);
      throw errorData['message'] ?? "Gagal Check In";
    }
  } catch (e) {
    rethrow;
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
  final url = Uri.parse(Endpoint.checkOut);

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "attendance_date": attendanceDate,
        "check_out": checkOutTime, // Tetap gunakan check_out
        "check_out_lat": lat.toString(),
        "check_out_lng": lng.toString(),
        "check_out_location": "$lat,$lng",
        "check_out_address": address,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw errorData['message'] ?? "Gagal Check Out";
    }
  } catch (e) {
    rethrow;
  }
}
