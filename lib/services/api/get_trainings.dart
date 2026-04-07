import 'dart:convert';
import 'package:http/http.dart' as http;
import 'endpoint.dart';

Future<List<dynamic>> getTraining() async {
  final response = await http.get(
    Uri.parse(Endpoint.trainings),
    headers: {"Accept": "application/json"},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception("Gagal ambil training");
  }
}
