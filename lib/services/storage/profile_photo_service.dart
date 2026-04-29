import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePhotoService {
  static const String _photoPathKey = 'profile_photo_path';
  static final ImagePicker _picker = ImagePicker();

  /// Menampilkan bottom sheet untuk memilih sumber foto (kamera/galeri)
  /// dan menyimpan foto ke local storage.
  /// Returns path foto yang disimpan, atau null jika dibatalkan.
  static Future<String?> pickAndSavePhoto({
    required ImageSource source,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Simpan foto ke direktori aplikasi agar persisten
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      // Hapus foto lama jika ada
      final oldPath = await getPhotoPath();
      if (oldPath != null) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      // Simpan path foto baru ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoPathKey, savedFile.path);

      return savedFile.path;
    } catch (e) {
      print("Error picking photo: $e");
      throw Exception("Gagal membuka galeri/kamera: $e");
    }
  }

  /// Mengambil path foto profil yang tersimpan
  static Future<String?> getPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_photoPathKey);
    if (path != null && await File(path).exists()) {
      return path;
    }
    return null;
  }

  /// Menghapus foto profil
  static Future<void> deletePhoto() async {
    final path = await getPhotoPath();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoPathKey);
  }
}
