import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../api/endpoint.dart';
import '../storage/preference.dart';

Future<void> login({required String email, required String password}) async {
  try {
    final response = await http.post(
      Uri.parse(Endpoint.login),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"email": email, "password": password}),
    );

    log("LOGIN: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await PreferenceHandler.saveToken(data["data"]["token"]);
      await PreferenceHandler.saveUserEmail(email); // Simpan email user
    } else {
      throw Exception(data["message"]);
    }
  } catch (e) {
    log("ERROR LOGIN: $e");
    rethrow;
  }
}
