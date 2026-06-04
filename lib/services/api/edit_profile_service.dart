Future<Map<String, dynamic>> updateProfile(
  String token,
  String name,
  String email,
) async {
  try {
    // MOCK DEMO MODE: Simulate network delay and always succeed
    await Future.delayed(const Duration(seconds: 1));

    print('Update Profile: MOCK DEMO SUCCESS');

    return {
      'message': 'Profile updated successfully',
      'data': {
        'name': name,
        'email': email,
      }
    };
  } catch (e) {
    print('Update Profile Error: $e');
    return {'error': true, 'message': 'Terjadi kesalahan: $e'};
  }
}
