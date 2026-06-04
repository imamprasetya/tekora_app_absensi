import 'dart:developer';
import '../../models/user_model.dart';
import '../storage/preference.dart';

Future<UserModel?> getUser() async {
  try {
    final token = await PreferenceHandler.getToken();

    // pura-puranya nembak API get_user (kasih delay dikit biar kerasa)
    await Future.delayed(const Duration(milliseconds: 500));
    log("GET USER: MOCK DEMO SUCCESS");

    return UserModel.fromJson({
      "id": 1,
      "name": "Demo User",
      "email": "demo@example.com",
      "profile_photo": "",
      "jenis_kelamin": "Laki-laki"
    });
  } catch (e) {
    log("ERROR GET USER: $e");
    rethrow;
  }
}
