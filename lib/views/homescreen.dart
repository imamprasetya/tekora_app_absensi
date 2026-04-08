import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Status absen: "none", "checkin", "checkout"
  String status = "none";

  String checkInTime = "--:--";
  String checkOutTime = "--:--";
  String checkInLocation = "-";
  String checkOutLocation = "-";

  List<Map<String, dynamic>> weeklyHistory = [];
  bool isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _initialLoad();

    // Timer untuk jam digital running
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        now = DateTime.now();

        // Cek apakah tanggal sudah berubah untuk reset otomatis
        if (now.day != lastCheckDate.day ||
            now.month != lastCheckDate.month ||
            now.year != lastCheckDate.year) {
          lastCheckDate = now;
          _resetTodayData();
          _initialLoad();
        }
      });
    });
  }

  void _resetTodayData() {
    setState(() {
      status = "none";
      checkInTime = "--:--";
      checkOutTime = "--:--";
      checkInLocation = "-";
      checkOutLocation = "-";
    });
  }

  Future<void> _initialLoad() async {
    await loadProfile();
    await loadTodayAbsen();
    await loadWeeklyHistory();
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
      if (mounted) {
        setState(() {
          userName = profile['name'] ?? "User";
        });
      }
    } catch (e) {
      if (mounted) setState(() => userName = "User");
    }
  }

  /// ================= CEK STATUS ABSEN HARI INI =================
  Future<void> loadTodayAbsen() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userKey = prefs.getString('active_user_email') ?? "default";
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final res = await http.get(
        Uri.parse(Endpoint.absenToday),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final data = jsonDecode(res.body);
      bool hasApiData = data['data'] != null && data['data'] is Map;
      var apiData = hasApiData ? data['data'] : null;

      setState(() {
        // 1. Ambil Jam & Lokasi (Prioritas API, lalu Local Storage)
        checkInTime =
            apiData?['check_in'] ??
            (prefs.getString('saved_checkin_date_$userKey') == todayKey
                ? prefs.getString('saved_checkin_$userKey')
                : "--:--");

        checkOutTime =
            apiData?['check_out'] ??
            (prefs.getString('saved_checkout_date_$userKey') == todayKey
                ? prefs.getString('saved_checkout_$userKey')
                : "--:--");

        checkInLocation =
            apiData?['check_in_address'] ??
            (prefs.getString('saved_checkin_date_$userKey') == todayKey
                ? prefs.getString('saved_checkin_location_$userKey')
                : "-");

        checkOutLocation =
            apiData?['check_out_address'] ??
            (prefs.getString('saved_checkout_date_$userKey') == todayKey
                ? prefs.getString('saved_checkout_location_$userKey')
                : "-");

        // 2. Tentukan Status
        if (checkOutTime != "--:--") {
          status = "checkout";
        } else if (checkInTime != "--:--") {
          status = "checkin";
        } else {
          status = "none";
        }
      });
    } catch (e) {
      debugPrint("Error loadTodayAbsen: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// ================= AMBIL DATA HISTORY MINGGUAN =================
  Future<void> loadWeeklyHistory() async {
    if (!mounted) return;
    setState(() => isLoadingHistory = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.get(
        Uri.parse(Endpoint.history),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final data = jsonDecode(res.body);
      if (data['data'] != null && data['data'] is List) {
        List<Map<String, dynamic>> rawList = List<Map<String, dynamic>>.from(
          data['data'],
        );

        // Sorting: Tanggal terbaru di atas/depan dengan validasi nullable
        rawList.sort((a, b) {
          String dateAStr =
              a['attendance_date']?.toString() ??
              a['tanggal']?.toString() ??
              a['date']?.toString() ??
              '';
          String dateBStr =
              b['attendance_date']?.toString() ??
              b['tanggal']?.toString() ??
              b['date']?.toString() ??
              '';
          DateTime? dateA = DateTime.tryParse(dateAStr);
          DateTime? dateB = DateTime.tryParse(dateBStr);

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });

        setState(() {
          weeklyHistory = rawList;
        });
      }
    } catch (e) {
      debugPrint("Error loadWeeklyHistory: $e");
    } finally {
      if (mounted) setState(() => isLoadingHistory = false);
    }
  }

  Future<void> handleNavigation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInScreen(currentStatus: status),
      ),
    );

    if (result == true) {
      loadTodayAbsen();
      loadWeeklyHistory();
    }
  }

  String formatTime(DateTime time) => DateFormat('HH:mm:ss').format(time);
  String formatDate(DateTime date) => DateFormat('EEEE, dd MMMM').format(date);

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
        onRefresh: () async {
          await loadTodayAbsen();
          await loadWeeklyHistory();
        },
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

                    /// INFO JAM ABSEN
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
                          _buildAbsenInfo(
                            "Check In",
                            checkInTime,
                            checkInLocation,
                          ),
                          Container(
                            width: 1.5,
                            height: 90,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          _buildAbsenInfo(
                            "Check Out",
                            checkOutTime,
                            checkOutLocation,
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const IzinScreen()),
                        ),
                        child: const Text("Request Permission (Izin)"),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// ================= WEEKLY HISTORY SECTION =================
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  "Weekly History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (isLoadingHistory)
                const Center(child: CircularProgressIndicator())
              else if (weeklyHistory.isEmpty)
                const Center(
                  child: Text(
                    "No history available",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                SizedBox(
                  height: 170,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: weeklyHistory.length,
                    itemBuilder: (context, index) {
                      final dayData = weeklyHistory[index];
                      final dateStr =
                          dayData['attendance_date']?.toString() ??
                          dayData['tanggal']?.toString() ??
                          dayData['date']?.toString() ??
                          '';
                      final date = DateTime.tryParse(dateStr) ?? DateTime.now();

                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 16, bottom: 5),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('EEEE, dd MMM').format(date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.primary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(dayData['status']?.toString() ?? 'masuk').withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (dayData['status']?.toString() ?? 'Masuk').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(dayData['status']?.toString() ?? 'masuk'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            _buildHistoryRow(
                              "In",
                              dayData['check_in']?.toString() ??
                                  dayData['check_in_time']?.toString() ??
                                  dayData['jam_masuk']?.toString() ??
                                  "--:--",
                              Colors.green,
                            ),
                            const SizedBox(height: 8),
                            _buildHistoryRow(
                              "Out",
                              dayData['check_out']?.toString() ??
                                  dayData['check_out_time']?.toString() ??
                                  dayData['jam_keluar']?.toString() ??
                                  "--:--",
                              Colors.red,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbsenInfo(String label, String time, String location) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            location,
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
    );
  }

  Widget _buildHistoryRow(String label, String time, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          time,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('izin') || status.contains('sakit')) return Colors.orange;
    if (status.contains('telat') || status.contains('terlambat')) return Colors.red;
    return Colors.green;
  }
}
