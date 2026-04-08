import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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

  // Data history mingguan
  List<Map<String, dynamic>> weeklyHistory = [];
  bool isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadTodayAbsen();
    loadWeeklyHistory();

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
          // Reset data untuk hari baru - mulai dari nol
          setState(() {
            status = "none";
            checkInTime = "--:--";
            checkOutTime = "--:--";
            checkInLocation = "-";
            checkOutLocation = "-";
          });
          // Reload data absen untuk hari baru
          loadTodayAbsen();
          loadWeeklyHistory();
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

      // Periksa apakah data dari API adalah untuk hari ini
      bool isDataForToday = false;
      if (hasData && rawData is Map) {
        String? apiDate =
            rawData['attendance_date'] ?? rawData['date'] ?? rawData['tanggal'];
        if (apiDate != null) {
          // Pastikan format tanggal sama
          String normalizedApiDate = apiDate.toString().substring(0, 10);
          isDataForToday = normalizedApiDate == todayKey;
        }
      }

      // Jika data tidak untuk hari ini, anggap tidak ada data
      if (!isDataForToday) {
        hasData = false;
      }

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

          // Prioritas: local storage untuk status real-time
          if (savedCheckOutDate == todayKey && isValidTime(savedCheckOut)) {
            status = "checkout";
            checkOutTime = savedCheckOut;
            checkOutLocation = savedCheckOutLocation;
            if (savedCheckInDate == todayKey && isValidTime(savedCheckIn)) {
              checkInTime = savedCheckIn;
              checkInLocation = savedCheckInLocation;
            }
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
          // API data sebagai prioritas utama untuk display
          checkInTime = isValidTime(apiCheckIn)
              ? apiCheckIn.toString()
              : (savedCheckInDate == todayKey && isValidTime(savedCheckIn)
                    ? savedCheckIn
                    : "--:--");
          checkOutTime = isValidTime(apiCheckOut)
              ? apiCheckOut.toString()
              : (savedCheckOutDate == todayKey && isValidTime(savedCheckOut)
                    ? savedCheckOut
                    : "--:--");
          checkInLocation = isValidTime(apiCheckInLocation)
              ? apiCheckInLocation.toString()
              : (savedCheckInDate == todayKey ? savedCheckInLocation : "-");
          checkOutLocation = isValidTime(apiCheckOutLocation)
              ? apiCheckOutLocation.toString()
              : (savedCheckOutDate == todayKey ? savedCheckOutLocation : "-");

          // Logika status: API first, then local storage
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

  /// ================= AMBIL DATA HISTORY MINGGUAN =================
  Future<void> loadWeeklyHistory() async {
    setState(() => isLoadingHistory = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final res = await http.get(
        Uri.parse(Endpoint.history),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final data = jsonDecode(res.body);
      if (data['data'] != null && data['data'] is List) {
        // Filter data untuk minggu ini saja
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        List<Map<String, dynamic>> weekData = [];
        for (var item in data['data']) {
          if (item is Map) {
            final attendanceDate = item['attendance_date'];
            if (attendanceDate != null) {
              try {
                final date = DateTime.parse(attendanceDate);
                if (date.isAfter(
                      startOfWeek.subtract(const Duration(days: 1)),
                    ) &&
                    date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
                  weekData.add(Map<String, dynamic>.from(item));
                }
              } catch (_) {
                // Skip invalid date format
              }
            }
          }
        }

        setState(() {
          weeklyHistory = weekData;
        });
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) setState(() => isLoadingHistory = false);
    }
  }

  /// ================= NAVIGASI KE HALAMAN ABSEN =================
  Future<void> handleNavigation() async {
    // Simpan status sebelum navigasi
    String previousStatus = status;

    // Menunggu hasil dari halaman CheckInScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInScreen(currentStatus: status),
      ),
    );

    // Jika result adalah true, berarti user baru saja melakukan CheckIn/Out
    if (result == true) {
      // Update status secara langsung berdasarkan aksi yang dilakukan
      if (previousStatus == "none") {
        // Jika sebelumnya "none", maka user baru check in, status jadi "checkin"
        setState(() => status = "checkin");
      } else if (previousStatus == "checkin") {
        // Jika sebelumnya "checkin", maka user baru check out, status jadi "checkout"
        setState(() => status = "checkout");
      }

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

              // Weekly History Section
              if (isLoadingHistory)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                  ),
                )
              else if (weeklyHistory.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Weekly Attendance History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: weeklyHistory.length,
                        itemBuilder: (context, index) {
                          final dayData = weeklyHistory[index];
                          final date = DateTime.parse(dayData['tanggal']);
                          final checkIn = dayData['jam_masuk'] ?? '--:--';
                          final checkOut = dayData['jam_keluar'] ?? '--:--';
                          final locationIn =
                              dayData['lokasi_masuk'] ?? 'Not recorded';
                          final locationOut =
                              dayData['lokasi_keluar'] ?? 'Not recorded';

                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE, dd MMM').format(date),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Check In",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            checkIn,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            locationIn,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 50,
                                      color: Colors.grey.withOpacity(0.3),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Check Out",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            checkOut,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            locationOut,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "No attendance history available for this week",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
