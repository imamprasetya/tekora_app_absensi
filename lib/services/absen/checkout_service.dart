// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../api/endpoint.dart';

// Future<Map<String, dynamic>> checkOut({
//   required String token,
//   required String attendanceDate,
//   required String checkOutTime,
//   required double lat,
//   required double lng,
//   required String address,
// }) async {
//   final response = await http.post(
//     Uri.parse(Endpoint.checkOut),
//     headers: {
//       "Authorization": "Bearer $token",
//       "Content-Type": "application/json",
//       "Accept": "application/json",
//     },
//     body: jsonEncode({
//       "attendance_date": attendanceDate,
//       "check_out": checkOutTime,
//       "check_out_lat": lat,
//       "check_out_lng": lng,
//       "check_out_location": "$lat,$lng",
//       "check_out_address": address,
//     }),
//   );

//   print("CHECKOUT STATUS: ${response.statusCode}");
//   print("CHECKOUT BODY: ${response.body}");

//   final data = jsonDecode(response.body);

//   if (response.statusCode == 200 || response.statusCode == 201) {
//     return data;
//   } else {
//     throw Exception(data['message'] ?? "Gagal melakukan check-out");
//   }
// }
