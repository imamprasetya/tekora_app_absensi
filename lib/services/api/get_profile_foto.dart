import 'package:image_picker/image_picker.dart';

Future<String> updateProfilePhoto(String token, XFile imageFile) async {
  // pura-puranya load foto dari server, padahal cuma fetch local path
  // For web, imageFile.path is a blob: URL which can be displayed directly by NetworkImage
  // For mobile, it's a local file path which can be displayed by FileImage
  await Future.delayed(const Duration(seconds: 1)); // simulate network delay
  return imageFile.path;
}
