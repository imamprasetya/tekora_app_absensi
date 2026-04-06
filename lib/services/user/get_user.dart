import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../api/endpoint.dart';
import '../storage/preference.dart';

Future<UserModel?> getUser() async {
  try {
    final token = await PreferenceHandler.getToken();

    final response = await http.get(
      Uri.parse(Endpoint.profile),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer ${token ?? ''}",
      },
    );

    log("GET USER: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserModel.fromJson(data["data"]);
    } else {
      throw Exception(data["message"]);
    }
  } catch (e) {
    log("ERROR GET USER: $e");
    rethrow;
  }
}
