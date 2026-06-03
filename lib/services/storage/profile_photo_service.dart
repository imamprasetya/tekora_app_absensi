import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tekora_app_absensi/services/api/get_profile_foto.dart';

class ProfilePhotoService {
  static const String _photoPathKey = 'profile_photo_path';
  static final ImagePicker _picker = ImagePicker();

  /// Menampilkan bottom sheet untuk memilih sumber foto (kamera/galeri)
  /// dan mengupload foto ke API, lalu menyimpan URL ke local storage.
  /// Mengembalikan URL foto yang berhasil disimpan, atau null jika proses dibatalkan.
  static Future<String?> pickAndSavePhoto({
    required ImageSource source,
    required String token,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final file = File(pickedFile.path);

      // Upload ke API
      final imageUrl = await updateProfilePhoto(token, file);

      // Hapus foto lama jika ada dan jika berupa file lokal
      final oldPath = await getPhotoPath();
      if (oldPath != null && !oldPath.startsWith('http')) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      // Simpan URL foto baru ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoPathKey, imageUrl);

      return imageUrl;
    } catch (e) {
      print("Error picking/uploading photo: $e");
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  /// Mengambil path/URL foto profil yang tersimpan
  static Future<String?> getPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_photoPathKey);
    if (path != null) {
      if (path.startsWith('http')) {
        return path;
      } else if (await File(path).exists()) {
        return path;
      }
    }
    return null;
  }

  /// Menghapus foto profil dari storage lokal
  static Future<void> deletePhoto() async {
    final path = await getPhotoPath();
    if (path != null && !path.startsWith('http')) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoPathKey);
  }
}
