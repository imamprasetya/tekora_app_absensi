import 'package:image_picker/image_picker.dart';

Future<String> updateProfilePhoto(String token, XFile imageFile) async {
  // MOCK DEMO MODE: Instead of uploading to server, just return the local path
  // For web, imageFile.path is a blob: URL which can be displayed directly by NetworkImage
  // For mobile, it's a local file path which can be displayed by FileImage
  await Future.delayed(const Duration(seconds: 1)); // simulate network delay
  return imageFile.path;
}
