import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekora_app_absensi/models/attendence_model.dart';
import 'package:tekora_app_absensi/services/api/attendence.dart';
import 'package:tekora_app_absensi/services/storage/preference.dart';
import 'package:tekora_app_absensi/services/api/get_profile.dart';
import 'package:tekora_app_absensi/services/storage/profile_photo_service.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';
import 'package:tekora_app_absensi/utils/theme_notifier.dart';
import 'package:tekora_app_absensi/views/edit_profile_screen.dart';
import 'package:tekora_app_absensi/views/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Loading...";
  String userEmail = "Loading...";
  String userJabatan = "KARYAWAN";
  String? _profilePhotoPath;

  // Data statistik nyata
  String attendanceRate = "...";
  String avgClockIn = "...";
  bool _isLoadingStats = true;

  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    loadProfile();
    _loadProfilePhoto();
    _loadAttendanceStats();
  }

  Future<void> loadProfile() async {
    try {
      final token = await PreferenceHandler.getToken();
      if (token == null) return;

      final profile = await getProfile(token);
      if (!mounted) return;

      setState(() {
        userName = profile['name'] ?? "User";
        userEmail = profile['email'] ?? "user@example.com";
      });

      // Simpan email ke prefs agar bisa digunakan sebagai Key Unik di CheckInScreen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_user_email', userEmail);

      final savedJabatan = prefs.getString('user_jabatan');
      if (savedJabatan != null && savedJabatan.isNotEmpty) {
        setState(() {
          userJabatan = savedJabatan.toUpperCase();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = "User";
          userEmail = "user@example.com";
        });
      }
    }
  }

  Future<void> _loadProfilePhoto() async {
    final path = await ProfilePhotoService.getPhotoPath();
    if (mounted) {
      setState(() => _profilePhotoPath = path);
    }
  }

  Future<void> _loadAttendanceStats() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setState(() {
          attendanceRate = "N/A";
          avgClockIn = "N/A";
          _isLoadingStats = false;
        });
        return;
      }

      final List<AttendanceModel> history =
          await _attendanceService.fetchHistory(token);

      if (!mounted) return;

      // === Hitung Attendance Rate ===
      // Attendance rate = (jumlah hari masuk / total hari absen) * 100
      final int totalDays = history.length;
      final int presentDays =
          history.where((e) => e.status.toLowerCase() == 'masuk').length;

      if (totalDays > 0) {
        final double rate = (presentDays / totalDays) * 100;
        attendanceRate = "${rate.toStringAsFixed(1)}%";
      } else {
        attendanceRate = "0%";
      }

      // === Hitung Rata-rata Clock In ===
      // Ambil semua checkInTime yang valid, parse jam:menit, lalu rata-rata
      final List<Duration> checkInDurations = [];
      for (final item in history) {
        if (item.checkInTime != null && item.checkInTime!.isNotEmpty) {
          final parsed = _parseTimeString(item.checkInTime!);
          if (parsed != null) {
            checkInDurations.add(parsed);
          }
        }
      }

      if (checkInDurations.isNotEmpty) {
        final int totalMinutes = checkInDurations.fold<int>(
          0,
          (sum, d) => sum + d.inMinutes,
        );
        final int avgMinutes = totalMinutes ~/ checkInDurations.length;
        final int hours = avgMinutes ~/ 60;
        final int minutes = avgMinutes % 60;

        // Format ke AM/PM
        final now = DateTime.now();
        final avgTime = DateTime(now.year, now.month, now.day, hours, minutes);
        avgClockIn = DateFormat('hh:mm a').format(avgTime);
      } else {
        avgClockIn = "N/A";
      }

      setState(() => _isLoadingStats = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          attendanceRate = "N/A";
          avgClockIn = "N/A";
          _isLoadingStats = false;
        });
      }
    }
  }

  /// Parse string waktu (HH:mm:ss atau HH:mm) menjadi Duration
  Duration? _parseTimeString(String timeStr) {
    try {
      // Bersihkan string
      timeStr = timeStr.trim();

      // Coba parse format HH:mm:ss
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hours = int.tryParse(parts[0]);
        final minutes = int.tryParse(parts[1]);
        if (hours != null && minutes != null) {
          return Duration(hours: hours, minutes: minutes);
        }
      }
      return null;
    } catch (_) {
      return null;
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                    setState(() => _profilePhotoPath = null);
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
      final savedPath = await ProfilePhotoService.pickAndSavePhoto(source: source);

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog

      if (savedPath != null) {
        setState(() => _profilePhotoPath = savedPath);
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

  Future<void> handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // Hapus token dan email user agar sesi benar-benar bersih
    await prefs.remove('token');
    await prefs.remove('active_user_email');

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: _showPhotoPickerBottomSheet,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _profilePhotoPath != null
                  ? FileImage(File(_profilePhotoPath!)) as ImageProvider
                  : null,
              child: _profilePhotoPath == null
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network(
            'https://cdn-icons-png.flaticon.com/512/6009/6009864.png',
          ),
        ),
        title: Text(
          "Tekora",
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColor.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: AppColor.secondaryText,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(child: _buildProfileAvatar()),
            const SizedBox(height: 15),
            Text(
              userName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              userEmail,
              style: const TextStyle(color: AppColor.secondaryText),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : AppColor.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: Colors.orange, size: 8),
                  const SizedBox(width: 8),
                  Text(
                    userJabatan,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColor.accentText,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                _buildStatCard(
                  "Attendance Rate",
                  _isLoadingStats ? "..." : attendanceRate,
                  Icons.calendar_today_outlined,
                  false,
                ),
                const SizedBox(width: 15),
                _buildStatCard(
                  "Avg. Clock In",
                  _isLoadingStats ? "..." : avgClockIn,
                  Icons.timer_outlined,
                  true,
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "ACCOUNT SETTINGS",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColor.secondaryText,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _menuItem(
              Icons.person_outline,
              "Edit Profile",
              "Update your personal information",
              () {
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                ).then((isUpdated) {
                  if (isUpdated == true) {
                    loadProfile();
                  }
                });
              },
            ),
            _menuItem(
              Icons.lock_outline,
              "Change Password",
              "Secure your account with a new pass",
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("This feature is currently under development"),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _menuItem(
              Icons.notifications_none_outlined,
              "Notifications",
              "Manage your alert preferences",
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("This feature is currently under development"),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeNotifier.themeModeNotifier,
              builder: (context, mode, child) {
                final isDark = mode == ThemeMode.dark;
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: isDark ? Colors.white70 : Colors.blue,
                      ),
                    ),
                    title: const Text(
                      "Dark Mode",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      "Toggle application wide theme",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: isDark,
                    activeColor: Colors.blue,
                    onChanged: (val) {
                      ThemeNotifier.toggleTheme();
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.red.withOpacity(0.2) 
                      : AppColor.logoutBg,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.redAccent 
                      : AppColor.logoutText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Logout"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (!mounted) return;
                    await handleLogout(context);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  "Logout Account",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "App Version 2.4.1 (Stable Build)",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    bool isPrimary,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isPrimary 
        ? (isDark ? Colors.blueGrey.shade900 : AppColor.primary) 
        : Theme.of(context).cardColor;
        
    final iconColor = isPrimary ? Colors.white : (isDark ? Colors.white70 : Colors.blue);
    final titleColor = isPrimary ? Colors.white70 : AppColor.secondaryText;
    final valueColor = isPrimary ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    String subtitle, [
    VoidCallback? onTap,
  ]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColor.secondaryText),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
