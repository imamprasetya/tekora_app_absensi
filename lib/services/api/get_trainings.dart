Future<List<dynamic>> getTraining() async {
  // MOCK DEMO MODE
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {"id": 1, "name": "Flutter Development"},
    {"id": 2, "name": "UI/UX Design"},
  ];
}
