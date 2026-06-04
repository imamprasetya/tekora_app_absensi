import 'dart:developer';
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
    // MOCK DEMO MODE: Simulate network delay and always succeed
    await Future.delayed(const Duration(seconds: 1));

    log("REGISTER: MOCK DEMO SUCCESS");

    await PreferenceHandler.saveToken("mock_demo_token_12345");
  } catch (e) {
    log("ERROR REGISTER: $e");
    rethrow;
  }
}
