Future<Map<String, dynamic>> getProfile(String token) async {
  // pura-puranya nembak API get profile, mock aja data delay
  await Future.delayed(const Duration(milliseconds: 500));

  return {
    "name": "Demo User",
    "email": "demo@example.com",
    "profile_photo": "" 
  };
}
