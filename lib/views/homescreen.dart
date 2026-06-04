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
import 'package:tekora_app_absensi/utils/profile_notifier.dart';

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
  Timer? scrollTimer;
  bool isLoading = false;
  ScrollController historyScrollController = ScrollController();

  /// Status absen: "none", "checkin", "checkout"
  String status = "none";
  bool hasIzinToday = false;

  String checkInTime = "--:--";
  String checkOutTime = "--:--";
  String checkInLocation = "-";
  String checkOutLocation = "-";

  List<Map<String, dynamic>> weeklyHistory = [];
  bool isLoadingHistory = false;

  Map<String, dynamic>? statsData;
  bool isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _startAutoScroll();

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
      hasIzinToday = false;
      checkInTime = "--:--";
      checkOutTime = "--:--";
      checkInLocation = "-";
      checkOutLocation = "-";
    });
  }

  void _showIzinBlockedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Action Blocked"),
        content: const Text(
          "You have already taken a leave today. You can only check in or take another leave tomorrow.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showCheckInBlockedDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Attendance Denied"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _initialLoad() async {
    await loadProfile();
    await loadTodayAbsen();
    await loadWeeklyHistory();
    await loadStats();
  }

  void _startAutoScroll() {
    scrollTimer?.cancel();
    scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      if (historyScrollController.hasClients) {
        final maxScroll = historyScrollController.position.maxScrollExtent;
        final currentScroll = historyScrollController.offset;
        final isScrolling =
            historyScrollController.position.isScrollingNotifier.value;

        // Auto-scroll jika maxScroll valid dan belum mentok
        if (!isScrolling && maxScroll > 0 && currentScroll < maxScroll) {
          historyScrollController.jumpTo(currentScroll + 1.0);
        } else if (!isScrolling &&
            currentScroll >= maxScroll &&
            maxScroll > 0) {
          // Putar balik ke awal
          historyScrollController.jumpTo(0.0);
        }
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    scrollTimer?.cancel();
    historyScrollController.dispose();
    super.dispose();
  }

  // AMBIL DATA PROFIL
  Future<void> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final profile = await getProfile(token);
      if (mounted) {
        setState(() => userName = profile['name'] ?? "User");
        ProfileNotifier.userNameNotifier.value = userName;
      }
    } catch (e) {
      if (mounted) setState(() => userName = "User");
    }
  }

  ///  CEK STATUS ABSEN HARI INI
  Future<void> loadTodayAbsen() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      // pura-puranya fetch data hari ini (simulasi delay API)
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        checkInTime = "08:00";
        checkOutTime = "--:--";
        checkInLocation = "Office";
        checkOutLocation = "-";
        hasIzinToday = false;
        status = "checkin"; // simulate already checked in
      });
    } catch (e) {
      debugPrint("Error loadTodayAbsen: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  ///  AMBIL DATA HISTORY MINGGUAN
  Future<void> loadWeeklyHistory() async {
    if (!mounted) return;
    setState(() => isLoadingHistory = true);
    try {
      // pura-puranya fetch data history 5 hari terakhir
      await Future.delayed(const Duration(milliseconds: 500));
      
      final today = DateTime.now();
      List<Map<String, dynamic>> rawList = [];
      for (int i = 0; i < 5; i++) {
        final date = today.subtract(Duration(days: i));
        rawList.add({
          "attendance_date": DateFormat('yyyy-MM-dd').format(date),
          "check_in": "08:00",
          "check_out": i == 0 ? "--:--" : "17:00", // simulate today not checked out yet
          "status": "masuk",
          "check_in_address": "Office",
          "check_out_address": i == 0 ? "-" : "Office",
        });
      }

      setState(() {
        weeklyHistory = rawList;
      });
    } catch (e) {
      debugPrint("Error loadWeeklyHistory: $e");
    } finally {
      if (mounted) setState(() => isLoadingHistory = false);
    }
  }

  ///  AMBIL DATA STATISTIK BULANAN
  Future<void> loadStats() async {
    if (!mounted) return;
    setState(() => isLoadingStats = true);
    try {
      // pura-puranya fetch stats bulanan
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        statsData = {
          "total_hadir": 20,
          "total_izin": 1,
          "total_sakit": 0,
          "total_absen": 0, // maybe alpha
        };
      });
    } catch (e) {
      debugPrint("Error loadStats: $e");
    } finally {
      if (mounted) setState(() => isLoadingStats = false);
    }
  }

  Future<void> handleNavigation() async {
    if (hasIzinToday) {
      _showIzinBlockedDialog();
      return;
    }

    if (status == "none") {
      final now = DateTime.now();
      if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
        _showCheckInBlockedDialog(
          "Attendance denied. Today is a weekend (non-working day).",
        );
        return;
      }
      if (now.hour >= 17) {
        _showCheckInBlockedDialog(
          "Check in denied because office hours have ended (17:00).",
        );
        return;
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInScreen(currentStatus: status),
      ),
    );

    if (result == true) {
      loadTodayAbsen();
      loadWeeklyHistory();
      loadStats();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning,";
    } else if (hour >= 12 && hour < 15) {
      return "Good Afternoon,";
    } else if (hour >= 15 && hour < 18) {
      return "Good Evening,";
    } else {
      return "Good Night,";
    }
  }

  String formatTime(DateTime time) => DateFormat('HH:mm:ss').format(time);
  String formatDate(DateTime date) => DateFormat('EEEE, dd MMMM').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).scaffoldBackgroundColor
            : AppColor.primary,
        title: Text(
          "TEKORA",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadTodayAbsen();
          await loadWeeklyHistory();
          await loadStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 4),
              ValueListenableBuilder<String>(
                valueListenable: ProfileNotifier.userNameNotifier,
                builder: (context, name, child) {
                  return Text(
                    name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  );
                },
              ),
              const SizedBox(height: 25),

              /// CARD WAKTU & TOMBOL UTAMA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).cardColor
                      : AppColor.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (Theme.of(context).brightness != Brightness.dark)
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
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.blueGrey.shade800
                                  : Colors.white,
                              foregroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : AppColor.primary,
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: handleNavigation,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                status == "none"
                                    ? "Check In Now"
                                    : status == "checkin"
                                    ? "Check Out Now"
                                    : "View Attendance",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : AppColor.primary,
                                ),
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
                          if (hasIzinToday) {
                            _showIzinBlockedDialog();
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const IzinScreen(),
                            ),
                          ).then((value) {
                            if (value == true) {
                              loadTodayAbsen();
                              loadWeeklyHistory();
                              loadStats();
                            }
                          });
                        },
                        child: Text(
                          "Submit Leave Request",
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              ///  WEEKLY HISTORY SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  "Weekly History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
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
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notif) {
                      if (notif is ScrollStartNotification &&
                          notif.dragDetails != null) {
                        scrollTimer?.cancel();
                      } else if (notif is ScrollEndNotification) {
                        _startAutoScroll();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: historyScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: weeklyHistory.length,
                      itemBuilder: (context, index) {
                        final dayData = weeklyHistory[index];
                        final dateStr =
                            dayData['attendance_date']?.toString() ??
                            dayData['tanggal']?.toString() ??
                            dayData['date']?.toString() ??
                            '';
                        final date =
                            DateTime.tryParse(dateStr) ?? DateTime.now();

                        final checkInTime =
                            dayData['check_in']?.toString() ??
                            dayData['check_in_time']?.toString() ??
                            dayData['jam_masuk']?.toString() ??
                            "--:--";
                        final checkOutTime =
                            dayData['check_out']?.toString() ??
                            dayData['check_out_time']?.toString() ??
                            dayData['jam_keluar']?.toString() ??
                            "--:--";

                        final computedStatus = _getComputedStatus(
                          dayData['status']?.toString() ?? 'masuk',
                          checkInTime,
                          checkOutTime,
                        );

                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 16, bottom: 5),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      DateFormat('EEE, dd MMM').format(date),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : AppColor.primary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        computedStatus,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      computedStatus.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(computedStatus),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (computedStatus.toLowerCase().contains(
                                    "izin",
                                  ) ||
                                  computedStatus.toLowerCase().contains(
                                    "sakit",
                                  ) ||
                                  computedStatus.toLowerCase().contains(
                                    "leave",
                                  ) ||
                                  computedStatus.toLowerCase().contains(
                                    "sick",
                                  )) ...[
                                const Text(
                                  "Leave Reason:",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    dayData['alasan_izin']?.toString() ??
                                        "No reason provided",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                _buildHistoryRow(
                                  "In",
                                  checkInTime,
                                  Colors.green,
                                ),
                                const SizedBox(height: 8),
                                _buildHistoryRow(
                                  "Out",
                                  checkOutTime,
                                  Colors.red,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 30),

              ///  STATISTIK
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  "Monthly Statistics",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isLoadingStats)
                const Center(child: CircularProgressIndicator())
              else if (statsData == null)
                const Center(
                  child: Text(
                    "Failed to load statistics",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        Icons.check_circle_outline,
                        "Present",
                        statsData!['total_masuk']?.toString() ?? "0",
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        Icons.calendar_month_outlined,
                        "Total Attendance",
                        statsData!['total_absen']?.toString() ?? "0",
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        Icons.warning_amber_rounded,
                        "Leave/Sick",
                        statsData!['total_izin']?.toString() ?? "0",
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbsenInfo(String label, String time, String location) {
    String cleanLocation = location;
    String modeTag = "";
    if (location.startsWith("[WFO]")) {
      cleanLocation = location.substring(5);
      modeTag = "WFO";
    } else if (location.startsWith("[WFH]")) {
      cleanLocation = location.substring(5);
      modeTag = "WFH";
    } else if (location.startsWith("[Dinas Luar]")) {
      cleanLocation = location.substring(12);
      modeTag = "Field Work";
    } else if (location.startsWith("[Field Work]")) {
      cleanLocation = location.substring(12);
      modeTag = "Field Work";
    }

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
          if (modeTag.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                modeTag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            cleanLocation,
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

  Widget _buildStatItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
    if (status.contains('izin') ||
        status.contains('sakit') ||
        status.contains('cepat'))
      return Colors.orange;
    if (status.contains('telat') || status.contains('terlambat'))
      return Colors.red;
    return Colors.green;
  }

  String _getComputedStatus(
    String originalStatus,
    String? checkIn,
    String? checkOut,
  ) {
    String status = originalStatus.toLowerCase();
    if (status.contains('izin') ||
        status.contains('sakit') ||
        status.contains('telat')) {
      return originalStatus;
    }

    bool isLate = false;
    bool isEarlyLeave = false;

    if (checkIn != null && checkIn != "--:--" && checkIn.isNotEmpty) {
      try {
        final parts = checkIn.split(':');
        if (parts.length >= 2) {
          final hours = int.tryParse(parts[0]) ?? 0;
          final mins = int.tryParse(parts[1]) ?? 0;
          if (hours > 8 || (hours == 8 && mins > 0)) {
            isLate = true;
          }
        }
      } catch (_) {}
    }

    if (checkOut != null && checkOut != "--:--" && checkOut.isNotEmpty) {
      try {
        final parts = checkOut.split(':');
        if (parts.length >= 2) {
          final hours = int.tryParse(parts[0]) ?? 0;
          if (hours < 17) {
            isEarlyLeave = true;
          }
        }
      } catch (_) {}
    }

    if (isLate) return "Late";
    if (isEarlyLeave) return "Early Leave";
    return "On Time";
  }
}
