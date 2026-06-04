Future<List<dynamic>> getTraining() async {
  // pura-puranya ambil data training dari API (data statis aja)
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {"id": 1, "name": "Flutter Development"},
    {"id": 2, "name": "UI/UX Design"},
  ];
}
