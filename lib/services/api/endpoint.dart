class Endpoint {
  static const String baseUrl = "https://appabsensi.mobileprojp.com/api";

  // AUTH
  static const String register = "$baseUrl/register";
  static const String login = "$baseUrl/login";

  // USER
  static const String profile = "$baseUrl/profile";
  static const String editProfile = "$baseUrl/edit-profile";

  // ABSEN
  static const String checkIn = "$baseUrl/absen/check-in";
  static const String checkOut = "$baseUrl/absen/check-out";
  static const String absenToday = "$baseUrl/absen/today";
  static const String absenStats = "$baseUrl/absen/stats";

  // IZIN
  static const String izin = "$baseUrl/izin";

  // HISTORY
  static const String history = "$baseUrl/history-absen";

  // TRAINING & BATCH
  static const String trainings = "$baseUrl/trainings";
  static const String batches = "$baseUrl/batches";
}
