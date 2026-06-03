import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tekora_app_absensi/services/storage/preference.dart';
import 'package:tekora_app_absensi/services/api/get_profile.dart';
import 'package:tekora_app_absensi/services/api/edit_profile_service.dart';
import 'package:tekora_app_absensi/services/storage/profile_photo_service.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekora_app_absensi/utils/profile_notifier.dart';

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
  bool _photoUpdated = false;

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

  Future<void> _showPhotoPickerBottomSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Change Profile Photo",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text(
                "Take from Camera",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Take a photo directly from camera",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              title: const Text(
                "Choose from Gallery",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Select a photo from device gallery",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_profilePhotoPath != null) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text(
                  "Remove Photo",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                subtitle: const Text(
                  "Revert to default photo",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ProfilePhotoService.deletePhoto();
                  if (mounted) {
                    setState(() {
                      _profilePhotoPath = null;
                      _photoUpdated = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Profile photo removed"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColor.primary),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final savedPath = await ProfilePhotoService.pickAndSavePhoto(
        source: source,
        token: token,
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog

      if (savedPath != null) {
        setState(() {
          _profilePhotoPath = savedPath;
          _photoUpdated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile photo updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi Perubahan"),
        content: const Text("Apakah Anda yakin ingin menyimpan perubahan profil Anda?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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

      // Simpan jabatan ke lokal storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_jabatan', _jabatanController.text.trim());
      ProfileNotifier.userNameNotifier.value = _nameController.text.trim();

      if (response['errors'] != null) {
        String errorMsg =
            response['errors']['name']?.first ?? "An error occurred";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        return;
      } else if (response['error'] == true) {
        String errorMsg = response['message'] ?? "An error occurred";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred, please try again")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _photoUpdated || result == true);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            "Edit Profile",
            style: TextStyle(
              color: AppColor.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColor.primary),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _photoUpdated),
          ),
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
                    // Bagian foto profil
                    Center(
                      child: GestureDetector(
                        onTap: _showPhotoPickerBottomSheet,
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
                                    ? (_profilePhotoPath!.startsWith('http')
                                        ? NetworkImage(_profilePhotoPath!)
                                        : FileImage(File(_profilePhotoPath!)))
                                            as ImageProvider
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
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      "Personal Information",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Update your display name below",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Inputan untuk nama (bisa diedit)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        hintText: "Enter your new name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Name cannot be empty";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Inputan untuk jabatan (bisa diedit)
                    TextFormField(
                      controller: _jabatanController,
                      decoration: InputDecoration(
                        labelText: "Job Title / Position",
                        hintText: "Example: Senior Developer",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.work_outline),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Job title cannot be empty";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Inputan email (hanya untuk dibaca)
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
                          helperText: "Email cannot be changed",
                          helperStyle: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Tombol aksi untuk menyimpan
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
                                "Save Changes",
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
      ),
    );
  }
}
