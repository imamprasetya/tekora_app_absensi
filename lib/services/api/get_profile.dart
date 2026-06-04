Future<Map<String, dynamic>> getProfile(String token) async {
  // MOCK DEMO MODE: Simulate network delay and return mock data
  await Future.delayed(const Duration(milliseconds: 500));

  return {
    "name": "Demo User",
    "email": "demo@example.com",
    "profile_photo": "" 
  };
}
