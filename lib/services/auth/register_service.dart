import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../api/endpoint.dart';
import '../storage/preference.dart';

Future<void> register({
  required String name,
  required String email,
  required String password,
  required String jenisKelamin,
  required int batchId,
  required int trainingId,
}) async {
  try {
    final response = await http.post(
      Uri.parse(Endpoint.register),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "jenis_kelamin": jenisKelamin,
        "profile_photo": "", // sementara kosong
        "batch_id": batchId,
        "training_id": trainingId,
      }),
    );

    log("REGISTER RESPONSE: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await PreferenceHandler.saveToken(data["data"]["token"]);
    } else {
      throw Exception(data["message"] ?? "Register gagal");
    }
  } catch (e) {
    log("ERROR REGISTER: $e");
    rethrow;
  }
}
