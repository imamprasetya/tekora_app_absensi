Future<List<dynamic>> getBatch() async {
  // MOCK DEMO MODE
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {"id": 1, "name": "Batch 1 (Morning)"},
    {"id": 2, "name": "Batch 2 (Afternoon)"},
  ];
}
