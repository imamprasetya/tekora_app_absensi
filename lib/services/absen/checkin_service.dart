// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../api/endpoint.dart';

// Future<Map<String, dynamic>> checkIn({
//   required String token,
//   required String attendanceDate,
//   required String checkInTime,
//   required double lat,
//   required double lng,
//   required String address,
// }) async {
//   final response = await http.post(
//     Uri.parse(Endpoint.checkIn),
//     headers: {
//       "Authorization": "Bearer $token",
//       "Content-Type": "application/json",
//       "Accept": "application/json",
//     },
//     body: jsonEncode({
//       "attendance_date": attendanceDate,
//       "check_in": checkInTime,
//       "check_in_lat": lat,
//       "check_in_lng": lng,
//       "check_in_address": address,
//       "status": "masuk",
//     }),
//   );

//   print("CHECKIN STATUS: ${response.statusCode}");
//   print("CHECKIN BODY: ${response.body}");

//   final data = jsonDecode(response.body);

//   if (response.statusCode == 200 || response.statusCode == 201) {
//     return data;
//   } else {
//     throw Exception(data['message'] ?? "Gagal Check-in");
//   }
// }
