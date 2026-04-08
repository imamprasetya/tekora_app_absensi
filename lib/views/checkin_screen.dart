import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Tambahkan ini
import 'package:http/http.dart' as http;
import 'package:tekora_app_absensi/services/api/attendence.dart';
import 'package:tekora_app_absensi/services/api/endpoint.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';

class CheckInScreen extends StatefulWidget {
  final String currentStatus;

  const CheckInScreen({super.key, required this.currentStatus});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String checkInTimeDisplay = "--:--";
  String checkOutTimeDisplay = "--:--";
  String checkInLocationDisplay = "-";
  String checkOutLocationDisplay = "-";
  String currentAddress = "Mencari lokasi...";
  Position? myPos;
  bool isLoading = false;
  DateTime lastCheckDate = DateTime.now();
  Timer? timer;

  // Controller untuk Google Maps
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
    _determinePosition();

    // Timer untuk mendeteksi perubahan tanggal
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();

      // Cek apakah tanggal sudah berubah
      if (now.day != lastCheckDate.day ||
          now.month != lastCheckDate.month ||
          now.year != lastCheckDate.year) {
        lastCheckDate = now;
        // Reset data untuk hari baru
        setState(() {
          checkInTimeDisplay = "--:--";
          checkOutTimeDisplay = "--:--";
          checkInLocationDisplay = "-";
          checkOutLocationDisplay = "-";
        });
        // Reload data absen untuk hari baru
        _loadAttendanceData();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    final prefs = await SharedPreferences.getInstance();
    String userKey = prefs.getString('active_user_email') ?? "default";
    String todayKey = DateTime.now().toIso8601String().substring(0, 10);

    String savedCheckIn = prefs.getString('saved_checkin_$userKey') ?? "--:--";
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

    setState(() {
      checkInTimeDisplay = savedCheckInDate == todayKey
          ? savedCheckIn
          : "--:--";
      checkOutTimeDisplay = savedCheckOutDate == todayKey
          ? savedCheckOut
          : "--:--";
      checkInLocationDisplay = savedCheckInDate == todayKey
          ? savedCheckInLocation
          : "-";
      checkOutLocationDisplay = savedCheckOutDate == todayKey
          ? savedCheckOutLocation
          : "-";
    });

    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse(Endpoint.absenToday),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(res.body);
      if (data['data'] == null) return;

      dynamic raw = data['data'];
      if (raw is! Map) return;

      // Periksa apakah data dari API adalah untuk hari ini
      String? apiDate = raw['attendance_date'] ?? raw['date'] ?? raw['tanggal'];
      bool isDataForToday = false;
      if (apiDate != null) {
        String normalizedApiDate = apiDate.toString().substring(0, 10);
        isDataForToday = normalizedApiDate == todayKey;
      }

      // Jika data tidak untuk hari ini, skip
      if (!isDataForToday) return;

      bool isValidTime(dynamic value) {
        return value != null &&
            value.toString().trim().isNotEmpty &&
            value.toString() != "--:--";
      }

      String apiCheckIn =
          raw['check_in'] ??
          raw['checkin'] ??
          raw['check_in_time'] ??
          raw['checkIn'] ??
          raw['checkInTime'] ??
          "--:--";
      String apiCheckOut =
          raw['check_out'] ??
          raw['checkout'] ??
          raw['check_out_time'] ??
          raw['checkOut'] ??
          raw['checkOutTime'] ??
          "--:--";
      String apiCheckInLocation =
          raw['check_in_address'] ??
          raw['check_in_location'] ??
          raw['checkin_address'] ??
          raw['checkInAddress'] ??
          raw['checkInLocation'] ??
          "-";
      String apiCheckOutLocation =
          raw['check_out_address'] ??
          raw['check_out_location'] ??
          raw['checkout_address'] ??
          raw['checkOutAddress'] ??
          raw['checkOutLocation'] ??
          "-";

      setState(() {
        if (isValidTime(apiCheckIn)) {
          checkInTimeDisplay = apiCheckIn.toString();
          checkInLocationDisplay = apiCheckInLocation.toString();
        } else if (savedCheckInDate == todayKey && isValidTime(savedCheckIn)) {
          checkInTimeDisplay = savedCheckIn;
          checkInLocationDisplay = savedCheckInLocation;
        }

        if (isValidTime(apiCheckOut)) {
          checkOutTimeDisplay = apiCheckOut.toString();
          checkOutLocationDisplay = apiCheckOutLocation.toString();
        } else if (savedCheckOutDate == todayKey &&
            isValidTime(savedCheckOut)) {
          checkOutTimeDisplay = savedCheckOut;
          checkOutLocationDisplay = savedCheckOutLocation;
        }
      });
    } catch (_) {
      // Jika API gagal, data lokal tetap dipakai.
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => currentAddress = "GPS tidak aktif");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => currentAddress = "Izin lokasi ditolak");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      setState(() {
        myPos = position;
        Placemark place = placemarks[0];
        currentAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}";

        // Gerakkan kamera map ke lokasi baru
        mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      });
    }
  }

  Future<void> processAbsen() async {
    if (myPos == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Menunggu lokasi GPS...")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      String userKey = prefs.getString('active_user_email') ?? "default";

      String attendanceDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String checkTime = DateFormat('HH:mm').format(DateTime.now());

      if (widget.currentStatus == "none") {
        // Check In - pastikan belum pernah check in hari ini
        String existingCheckInDate =
            prefs.getString('saved_checkin_date_$userKey') ?? "";
        if (existingCheckInDate == attendanceDate &&
            checkInTimeDisplay != "--:--") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Anda sudah check in hari ini")),
          );
          return;
        }

        await postCheckIn(
          token: token!,
          attendanceDate: attendanceDate,
          checkInTime: checkTime,
          lat: myPos!.latitude,
          lng: myPos!.longitude,
          address: currentAddress,
        );
        await prefs.setString('saved_checkin_$userKey', checkTime);
        await prefs.setString('saved_checkin_date_$userKey', attendanceDate);
        await prefs.setString(
          'saved_checkin_location_$userKey',
          currentAddress,
        );
        setState(() {
          checkInTimeDisplay = checkTime;
          checkInLocationDisplay = currentAddress;
        });
      } else if (widget.currentStatus == "checkin") {
        // Check Out - pastikan sudah check in dan belum check out
        String existingCheckInDate =
            prefs.getString('saved_checkin_date_$userKey') ?? "";
        String existingCheckOutDate =
            prefs.getString('saved_checkout_date_$userKey') ?? "";

        if (existingCheckInDate != attendanceDate) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Anda belum check in hari ini")),
          );
          return;
        }

        if (existingCheckOutDate == attendanceDate &&
            checkOutTimeDisplay != "--:--") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Anda sudah check out hari ini")),
          );
          return;
        }

        await postCheckOut(
          token: token!,
          attendanceDate: attendanceDate,
          checkOutTime: checkTime,
          lat: myPos!.latitude,
          lng: myPos!.longitude,
          address: currentAddress,
        );
        await prefs.setString('saved_checkout_$userKey', checkTime);
        await prefs.setString('saved_checkout_date_$userKey', attendanceDate);
        await prefs.setString(
          'saved_checkout_location_$userKey',
          currentAddress,
        );
        setState(() {
          checkOutTimeDisplay = checkTime;
          checkOutLocationDisplay = currentAddress;
        });
      } else if (widget.currentStatus == "checkout") {
        // Sudah selesai absen hari ini
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Absensi hari ini sudah selesai")),
        );
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Absensi Berhasil!")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text(
          "Live Attendance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Bagian Atas: Info Jam
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _timeInfoColumn(
                      "Check In",
                      checkInTimeDisplay,
                      checkInLocationDisplay,
                      Icons.login_rounded,
                      Colors.green,
                    ),
                  ),
                  Container(width: 1, height: 80, color: Colors.grey.shade200),
                  Expanded(
                    child: _timeInfoColumn(
                      "Check Out",
                      checkOutTimeDisplay,
                      checkOutLocationDisplay,
                      Icons.logout_rounded,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bagian Tengah: GOOGLE MAPS
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-6.2000, 106.8166), // Default Jakarta
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: myPos == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId("current_pos"),
                            position: LatLng(myPos!.latitude, myPos!.longitude),
                          ),
                        },
                ),
              ),
            ),
          ),

          // Bagian Bawah: Info Alamat & Tombol
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColor.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        currentAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.currentStatus == "checkout"
                          ? Colors.grey
                          : AppColor.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: (isLoading || widget.currentStatus == "checkout")
                        ? null
                        : processAbsen,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.currentStatus == "none"
                                ? "Check In Now"
                                : "Check Out Now",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeInfoColumn(
    String label,
    String time,
    String location,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          location,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}
