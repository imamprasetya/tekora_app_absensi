import 'dart:convert';
import 'package:http/http.dart' as http;
import 'endpoint.dart';

Future<Map<String, dynamic>> updateProfile(
  String token,
  String name,
  String email,
) async {
  final url = Uri.parse(Endpoint.editProfile);

  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'email': email}),
    );

    print('Update Profile Response Status: ${response.statusCode}');
    print('Update Profile Response Body: ${response.body}');

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 422) {
      return data;
    } else {
      return {'error': true, 'message': data['message'] ?? 'Gagal mengupdate profil'};
    }
  } catch (e) {
    print('Update Profile Error: $e');
    return {'error': true, 'message': 'Terjadi kesalahan: $e'};
  }
}
