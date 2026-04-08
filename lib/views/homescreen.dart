import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Import service & util punyamu
import 'package:tekora_app_absensi/services/api/endpoint.dart';
import 'package:tekora_app_absensi/services/api/get_profile.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';
import 'package:tekora_app_absensi/views/checkin_screen.dart';
import 'package:tekora_app_absensi/views/izin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Loading...";
  DateTime now = DateTime.now();
  DateTime lastCheckDate = DateTime.now();
  Timer? timer;
  bool isLoading = false;

  /// Status absen: "none" (belum), "checkin" (sudah masuk), "checkout" (selesai)
  String status = "none";

  // Variabel untuk menampung jam absen dari API
  String checkInTime = "--:--";
  String checkOutTime = "--:--";
  String checkInLocation = "-";
  String checkOutLocation = "-";

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

        // Cek apakah tanggal sudah berubah
        if (now.day != lastCheckDate.day ||
            now.month != lastCheckDate.month ||
            now.year != lastCheckDate.year) {
          lastCheckDate = now;
          // Reload data absen untuk hari baru
          loadTodayAbsen();
        }
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
      if (mounted) setState(() => userName = "User");
    }
  }

  /// ================= CEK STATUS ABSEN HARI INI =================
  Future<void> loadTodayAbsen() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userKey = prefs.getString('active_user_email') ?? "default";
      final todayKey = DateTime.now().toIso8601String().substring(0, 10);

      String savedCheckIn =
          prefs.getString('saved_checkin_$userKey') ?? "--:--";
      String savedCheckOut =
          prefs.getString('saved_checkout_$userKey') ?? "--:--";
      String savedCheckInDate =
          prefs.getString('saved_checkin_date_$userKey') ?? "";
      String savedCheckOutDate =
          prefs.getString('saved_checkout_date_$userKey') ?? "";
      String savedCheckInLocation =
          prefs.getString('saved_checkin_location_$userKey') ?? "-";
      String savedCheckOutLocation =
          prefs.getString('saved_checkout_location_$userKey') ?? "-";

      final res = await http.get(
        Uri.parse(Endpoint.absenToday),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final data = jsonDecode(res.body);

      bool isValidTime(dynamic value) {
        return value != null &&
            value.toString().trim().isNotEmpty &&
            value.toString() != "--:--";
      }

      dynamic rawData = data['data'];
      bool hasData =
          rawData != null &&
          !(rawData is List && rawData.isEmpty) &&
          !(rawData is Map && rawData.isEmpty);

      dynamic apiCheckIn;
      dynamic apiCheckOut;
      dynamic apiCheckInLocation;
      dynamic apiCheckOutLocation;
      if (hasData && rawData is Map) {
        apiCheckIn =
            rawData['check_in'] ??
            rawData['checkin'] ??
            rawData['check_in_time'] ??
            rawData['checkIn'] ??
            rawData['checkInTime'];
        apiCheckOut =
            rawData['check_out'] ??
            rawData['checkout'] ??
            rawData['check_out_time'] ??
            rawData['checkOut'] ??
            rawData['checkOutTime'];
        apiCheckInLocation =
            rawData['check_in_address'] ??
            rawData['check_in_location'] ??
            rawData['checkin_address'] ??
            rawData['checkInAddress'] ??
            rawData['checkInLocation'];
        apiCheckOutLocation =
            rawData['check_out_address'] ??
            rawData['check_out_location'] ??
            rawData['checkout_address'] ??
            rawData['checkOutAddress'] ??
            rawData['checkOutLocation'];
      }

      if (!hasData) {
        setState(() {
          checkInTime = "--:--";
          checkOutTime = "--:--";
          checkInLocation = "-";
          checkOutLocation = "-";

          if (savedCheckOutDate == todayKey && isValidTime(savedCheckOut)) {
            status = "checkout";
            checkOutTime = savedCheckOut;
            checkOutLocation = savedCheckOutLocation;
          } else if (savedCheckInDate == todayKey &&
              isValidTime(savedCheckIn)) {
            status = "checkin";
            checkInTime = savedCheckIn;
            checkInLocation = savedCheckInLocation;
          } else {
            status = "none";
          }
        });
      } else {
        setState(() {
          checkInTime = isValidTime(apiCheckIn)
              ? apiCheckIn.toString()
              : "--:--";
          checkOutTime = isValidTime(apiCheckOut)
              ? apiCheckOut.toString()
              : "--:--";
          checkInLocation = isValidTime(apiCheckInLocation)
              ? apiCheckInLocation.toString()
              : (savedCheckInDate == todayKey ? savedCheckInLocation : "-");
          checkOutLocation = isValidTime(apiCheckOutLocation)
              ? apiCheckOutLocation.toString()
              : (savedCheckOutDate == todayKey ? savedCheckOutLocation : "-");

          if (!isValidTime(apiCheckIn) &&
              savedCheckInDate == todayKey &&
              isValidTime(savedCheckIn)) {
            checkInTime = savedCheckIn;
          }
          if (!isValidTime(apiCheckOut) &&
              savedCheckOutDate == todayKey &&
              isValidTime(savedCheckOut)) {
            checkOutTime = savedCheckOut;
          }

          if (isValidTime(apiCheckOut) ||
              (savedCheckOutDate == todayKey && isValidTime(savedCheckOut))) {
            status = "checkout";
          } else if (isValidTime(apiCheckIn) ||
              (savedCheckInDate == todayKey && isValidTime(savedCheckIn))) {
            status = "checkin";
          } else {
            status = "none";
          }
        });
      }
    } catch (e) {
      setState(() {
        status = "none";
        checkInTime = "--:--";
        checkOutTime = "--:--";
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// ================= NAVIGASI KE HALAMAN ABSEN =================
  Future<void> handleNavigation() async {
    // Menunggu hasil dari halaman CheckInScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInScreen(currentStatus: status),
      ),
    );

    // Jika result adalah true, berarti user baru saja melakukan CheckIn/Out
    if (result == true) {
      // Memanggil ulang data dari API untuk memperbarui jam di UI HomeScreen
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
                    const SizedBox(height: 35),

                    /// INFO JAM ABSEN (BERDAMPINGAN) - DI ATAS TOMBOL CHECK OUT
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  "Check In",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  checkInTime,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  checkInLocation,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1.5,
                            height: 90,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  "Check Out",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  checkOutTime,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  checkOutLocation,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

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
                            onPressed: handleNavigation,
                            child: Text(
                              status == "none"
                                  ? "Check In Now"
                                  : status == "checkin"
                                  ? "Check Out Now"
                                  : "View Attendance",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
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
            ],
          ),
        ),
      ),
    );
  }
}
