import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'endpoint.dart';

Future<String> updateProfilePhoto(String token, File imageFile) async {
  // Karena backend memvalidasi field ini sebagai "string" (dan menolak multipart form-data),
  // akan mengirim gambar sebagai Base64 string di dalam body JSON.
  final bytes = await imageFile.readAsBytes();
  final base64Image = base64Encode(bytes);

  String extension = imageFile.path.split('.').last.toLowerCase();
  if (extension == 'jpg') extension = 'jpeg';

  final base64String = 'data:image/$extension;base64,$base64Image';

  final response = await http.put(
    Uri.parse(Endpoint.profilePhoto),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'profile_photo': base64String}),
  );

  final responseData = response.body;

  if (response.statusCode == 200) {
    var jsonResponse = json.decode(responseData);
    String photoUrl = jsonResponse['data']['profile_photo'];

    // Workaround jika APP_URL backend masih mengarah ke localhost/127.0.0.1
    if (photoUrl.contains('127.0.0.1') || photoUrl.contains('localhost')) {
      final baseUri = Uri.parse(Endpoint.baseUrl);
      final domain = '${baseUri.scheme}://${baseUri.host}';
      photoUrl = photoUrl.replaceAll(
        RegExp(r'http://127\.0\.0\.1(:\d+)?'),
        domain,
      );
      photoUrl = photoUrl.replaceAll(
        RegExp(r'http://localhost(:\d+)?'),
        domain,
      );
    } else if (!photoUrl.startsWith('http') && !photoUrl.startsWith('/')) {
      final baseUri = Uri.parse(Endpoint.baseUrl);
      final domain = '${baseUri.scheme}://${baseUri.host}';
      final prefix = photoUrl.startsWith('public/') ? '' : '/public/';
      photoUrl = '$domain$prefix$photoUrl';
    }

    // Tambahkan parameter untuk mencegah Flutter melakukan cache secara berlebihan
    // jika URL yang dikembalikan sama.
    final separator = photoUrl.contains('?') ? '&' : '?';
    photoUrl =
        '$photoUrl${separator}v=${DateTime.now().millisecondsSinceEpoch}';

    return photoUrl;
  } else {
    var errorMsg = "Gagal mengupload foto profil";
    try {
      var jsonResponse = json.decode(responseData);
      if (jsonResponse['message'] != null) {
        errorMsg = jsonResponse['message'];
      }
    } catch (_) {}
    throw Exception(errorMsg);
  }
}
