import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekora_app_absensi/services/api/endpoint.dart';
import 'package:tekora_app_absensi/utils/location_helper.dart';
import 'package:tekora_app_absensi/services/absen/checkin_service.dart';
import 'package:tekora_app_absensi/services/absen/checkout_service.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';

class AbsenScreen extends StatefulWidget {
  const AbsenScreen({super.key});

  @override
  State<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<AbsenScreen> {
  bool isLoading = false;
  String status = "none"; // none, checkin, checkout

  String lat = "-";
  String lng = "-";

  @override
  void initState() {
    super.initState();
    loadTodayStatus();
  }

  /// ================= CEK STATUS =================
  Future<void> loadTodayStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.get(
        Uri.parse(Endpoint.absenToday),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);

      if (data['data'] == null) {
        status = "none";
      } else if (data['data']['check_out'] != null) {
        status = "checkout";
      } else {
        status = "checkin";
      }

      setState(() {});
    } catch (e) {}
  }

  /// ================= HANDLE ABSEN =================
  Future<void> handleAbsen() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final pos = await getCurrentLocation();

      lat = pos.latitude.toString();
      lng = pos.longitude.toString();

      String attendanceDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String checkTime = DateFormat('HH:mm:ss').format(DateTime.now());

      Map<String, dynamic> res;

      if (status == "none") {
        res = await checkIn(
          token: token!,
          attendanceDate: attendanceDate,
          checkInTime: checkTime,
          lat: pos.latitude,
          lng: pos.longitude,
          address: "Lokasi Anda",
        );
      } else {
        res = await checkOut(
          token: token!,
          attendanceDate: attendanceDate,
          checkOutTime: checkTime,
          lat: pos.latitude,
          lng: pos.longitude,
          address: "Lokasi Anda",
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'])));

      await loadTodayStatus();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => isLoading = false);
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text("Absen"),
        backgroundColor: AppColor.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// CARD INFO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    "Status Hari Ini",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// LOKASI
                  Text(
                    "Lat: $lat",
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    "Lng: $lng",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// BUTTON ABSEN
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: status == "checkout" ? null : handleAbsen,
                    child: Text(
                      status == "none"
                          ? "Check In"
                          : status == "checkin"
                          ? "Check Out"
                          : "Sudah Absen",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            /// INFO STATUS
            Text(
              status == "none"
                  ? "Silakan lakukan absen masuk"
                  : status == "checkin"
                  ? "Jangan lupa absen pulang"
                  : "Anda sudah menyelesaikan absen hari ini",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
