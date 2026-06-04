import 'dart:developer';
import '../storage/preference.dart';

Future<void> login({required String email, required String password}) async {
  try {
    // MOCK DEMO MODE: Simulate network delay and always succeed
    await Future.delayed(const Duration(seconds: 1));

    log("LOGIN: MOCK DEMO SUCCESS");

    await PreferenceHandler.saveToken("mock_demo_token_12345");
    await PreferenceHandler.saveUserEmail(email); // Simpan email user
  } catch (e) {
    log("ERROR LOGIN: $e");
    rethrow;
  }
}
