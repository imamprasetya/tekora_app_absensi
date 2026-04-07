import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Import service & util punyamu
import 'package:tekora_app_absensi/services/api/endpoint.dart';
import 'package:tekora_app_absensi/services/api/get_profile.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';
import 'package:tekora_app_absensi/views/checkin_screen.dart'; // Pastikan path benar
import 'package:tekora_app_absensi/views/izin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Loading...";
  DateTime now = DateTime.now();
  Timer? timer;
  bool isLoading = false;

  /// Status absen: "none" (belum), "checkin" (sudah masuk), "checkout" (selesai)
  String status = "none";

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadTodayAbsen();

    // Timer untuk jam digital running
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  /// ================= AMBIL DATA PROFIL =================
  Future<void> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final profile = await getProfile(token);
      setState(() {
        userName = profile['name'] ?? "User";
      });
    } catch (e) {
      setState(() => userName = "User");
    }
  }

  /// ================= CEK STATUS ABSEN HARI INI =================
  Future<void> loadTodayAbsen() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.get(
        Uri.parse(Endpoint.absenToday),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final data = jsonDecode(res.body);

      if (data['data'] == null) {
        status = "none";
      } else if (data['data']['check_out'] != null) {
        status = "checkout";
      } else {
        status = "checkin";
      }
    } catch (e) {
      status = "none";
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= NAVIGASI KE HALAMAN ABSEN =================
  Future<void> handleNavigation() async {
    // Pindah ke halaman CheckInScreen sambil bawa status saat ini
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInScreen(currentStatus: status),
      ),
    );

    // Jika kembali dan membawa nilai 'true', artinya absen sukses, maka refresh
    if (result == true) {
      loadTodayAbsen();
    }
  }

  /// ================= FORMATTER WAKTU =================
  String formatTime(DateTime time) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(time.hour)}:${twoDigits(time.minute)}:${twoDigits(time.second)}";
  }

  String formatDate(DateTime date) {
    const days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return "${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        title: const Text(
          "TEKORA",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadTodayAbsen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Good Morning,",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              /// CARD WAKTU & TOMBOL UTAMA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      formatTime(now),
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      formatDate(now),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// TOMBOL DINAMIS
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColor.primary,
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            // Jika sudah checkout, tombol mati (null)
                            onPressed: status == "checkout"
                                ? null
                                : handleNavigation,
                            child: Text(
                              status == "none"
                                  ? "Check In Now"
                                  : status == "checkin"
                                  ? "Check Out Now"
                                  : "Attendance Completed",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                    const SizedBox(height: 12),

                    /// BUTTON IZIN (Hanya muncul jika belum absen sama sekali)
                    if (status == "none")
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const IzinScreen(),
                            ),
                          );
                        },
                        child: const Text("Request Permission (Izin)"),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Tambahkan widget lain seperti Riwayat Singkat di sini jika perlu
            ],
          ),
        ),
      ),
    );
  }
}
