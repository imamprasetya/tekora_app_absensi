import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tekora_app_absensi/services/storage/preference.dart';
import 'package:tekora_app_absensi/services/api/get_profile.dart';
import 'package:tekora_app_absensi/services/api/edit_profile_service.dart';
import 'package:tekora_app_absensi/services/storage/profile_photo_service.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _jabatanController = TextEditingController();

  bool _loading = true;
  bool _isSaving = false;
  String? _userEmail;
  String? _profilePhotoPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    final path = await ProfilePhotoService.getPhotoPath();
    if (mounted) {
      setState(() => _profilePhotoPath = path);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jabatanController.dispose();
    super.dispose();
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

      final prefs = await SharedPreferences.getInstance();
      final savedJabatan = prefs.getString('user_jabatan') ?? "Karyawan";

      setState(() {
        _nameController.text = profile['name'] ?? "";
        _userEmail = profile['email'] ?? "";
        _jabatanController.text = savedJabatan;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load profile data")),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final token = await PreferenceHandler.getToken();
      if (token == null) return;

      final response = await updateProfile(
        token,
        _nameController.text.trim(),
        _userEmail ?? "",
      );

      if (!mounted) return;

      setState(() => _isSaving = false);

      // Simpan jabatan ke lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_jabatan', _jabatanController.text.trim());

      if (response['errors'] != null) {
        String errorMsg =
            response['errors']['name']?.first ?? "Terjadi kesalahan";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        return;
      } else if (response['error'] == true) {
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

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan, coba lagi")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Edit Profil",
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
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColor.primary.withOpacity(0.3),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _profilePhotoPath != null
                                  ? FileImage(File(_profilePhotoPath!)) as ImageProvider
                                  : null,
                              child: _profilePhotoPath == null
                                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColor.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      "Informasi Pribadi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ubah nama tampilan Anda di bawah ini",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Nama (editable)
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
                        fillColor: Theme.of(context).cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Nama tidak boleh kosong";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Jabatan (editable)
                    TextFormField(
                      controller: _jabatanController,
                      decoration: InputDecoration(
                        labelText: "Jabatan / Posisi",
                        hintText: "Contoh: Senior Developer",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.work_outline),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Jabatan tidak boleh kosong";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email (read-only)
                    if (_userEmail != null)
                      TextFormField(
                        initialValue: _userEmail,
                        readOnly: true,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Theme.of(context).cardColor.withOpacity(0.5),
                          helperText: "Email tidak dapat diubah",
                          helperStyle: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: AppColor.primary.withOpacity(0.6),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Simpan Nama Baru",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
