import 'package:flutter/material.dart';
import 'package:tekora_app_absensi/services/storage/preference.dart';
import 'package:tekora_app_absensi/services/api/get_profile.dart';
import 'package:tekora_app_absensi/services/api/edit_profile_service.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  bool _loading = true;
  String? _userEmail; // Disimpan hanya untuk tampilan (read-only)

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final token = await PreferenceHandler.getToken();
      if (token == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final profile = await getProfile(token);

      if (!mounted) return;

      setState(() {
        _nameController.text = profile['name'] ?? "";
        _userEmail =
            profile['email'] ?? ""; // Email tidak diedit, hanya disimpan
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memuat data profil")),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final token = await PreferenceHandler.getToken();
      if (token == null) return;

      // Hanya mengirimkan Nama sesuai permintaan
      final response = await updateProfile(
        token,
        _nameController.text.trim(),
        _userEmail ?? "", // Kirim email yang lama agar tidak error di backend
      );

      if (!mounted) return;

      setState(() => _loading = false);

      if (response['errors'] != null) {
        String errorMsg =
            response['errors']['name']?.first ?? "Terjadi kesalahan";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        return;
      } else if (response['error'] == true) {
        // Fallback jika message error bukan berupa dict (mungkin API down atau message khusus)
        String errorMsg = response['message'] ?? "Terjadi kesalahan";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nama berhasil diperbarui"),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke layar sebelumnya (Profile) dan beritahu ada perubahan
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan, coba lagi")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text(
          "Edit Nama Profil",
          style: TextStyle(
            color: AppColor.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.primary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ubah nama tampilan Anda di bawah ini:",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Nama Lengkap",
                        hintText: "Masukkan nama baru",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Nama tidak boleh kosong";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),
                    // Informasi tambahan agar user tahu email tidak bisa diubah di sini
                    if (_userEmail != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          "Email: $_userEmail (Tidak dapat diubah)",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Simpan Nama Baru",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
