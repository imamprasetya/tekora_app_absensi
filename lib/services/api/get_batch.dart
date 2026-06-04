Future<List<dynamic>> getBatch() async {
  // pura-puranya ambil data batch dari API (pakai list statis)
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {"id": 1, "name": "Batch 1 (Morning)"},
    {"id": 2, "name": "Batch 2 (Afternoon)"},
  ];
}
