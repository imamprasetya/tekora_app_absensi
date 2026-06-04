import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  // Inisialisasi Service Baru
  final AttendanceService _attendanceService = AttendanceService();

  String checkInTimeDisplay = "--:--";
  String checkOutTimeDisplay = "--:--";
  String checkInLocationDisplay = "-";
  String checkOutLocationDisplay = "-";
  String currentAddress = "Finding location...";
  Position? myPos;
  bool isLoading = false;
  DateTime lastCheckDate = DateTime.now();
  Timer? timer;

  GoogleMapController? mapController;

  // Variabel Keamanan & Mode Kerja
  String workMode = "WFO"; // WFO, WFH, Field Work
  bool isMockLocation = false;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
    _determinePosition();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();

      if (now.day != lastCheckDate.day ||
          now.month != lastCheckDate.month ||
          now.year != lastCheckDate.year) {
        lastCheckDate = now;
        setState(() {
          checkInTimeDisplay = "--:--";
          checkOutTimeDisplay = "--:--";
          checkInLocationDisplay = "-";
          checkOutLocationDisplay = "-";
        });
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

    // MOCK DEMO MODE
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      setState(() {
        checkInTimeDisplay = "08:00";
        checkInLocationDisplay = "Office (Mock)";
      });
    } catch (_) {}
  }

  Future<void> _showGPSDisabledDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("GPS Disabled"),
        content: const Text(
          "Location services (GPS) on your device are disabled.\n\n"
          "Please enable GPS to proceed with attendance verification.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
              Future.delayed(const Duration(seconds: 1), () {
                _determinePosition();
              });
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionDeniedDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Location Permission Denied"),
        content: const Text(
          "This attendance app requires location permission to verify your position.\n\n"
          "Please enable location permission in app settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
              Future.delayed(const Duration(seconds: 1), () {
                _determinePosition();
              });
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => currentAddress = "GPS Disabled");
      _showGPSDisabledDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => currentAddress = "Location permission denied");
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => currentAddress = "Location permission permanently denied");
      _showPermissionDeniedDialog();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      bool mocked = false;
      try {
        mocked = position.isMocked;
      } catch (_) {}

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          myPos = position;
          isMockLocation = mocked;
          Placemark place = placemarks[0];
          String street = place.street ?? "";
          String subLoc = place.subLocality ?? "";
          String loc = place.locality ?? "";
          currentAddress = "${street.isNotEmpty ? '$street, ' : ''}${subLoc.isNotEmpty ? '$subLoc, ' : ''}$loc";
          if (currentAddress.trim().isEmpty) {
            currentAddress = "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
          }

          mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => currentAddress = "Failed to load coordinates: $e");
      }
    }
  }

  Future<void> processAbsen() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      _showGPSDisabledDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _showPermissionDeniedDialog();
      return;
    }

    if (myPos == null) {
      setState(() => isLoading = true);
      await _determinePosition();
      if (!mounted) return;
      setState(() => isLoading = false);
      if (myPos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to detect GPS location. Please try again.")),
        );
        return;
      }
    }

    // Cek Mock Location (Fake GPS)
    if (isMockLocation) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Fake GPS Detected"),
          content: const Text(
            "Mock location / Fake GPS usage detected.\n\n"
            "Please disable your fake GPS application to proceed with attendance.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    String confirmTitle = "Confirm Check In";
    String confirmContent = "Are you sure you want to check in now?";
    Color confirmColor = AppColor.primary;

    final now = DateTime.now();
    if (widget.currentStatus == "none") {
      if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Attendance Denied"),
            content: const Text("Attendance denied. Today is a weekend (non-working day)."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      if (now.hour >= 17) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Attendance Denied"),
            content: const Text("Check in denied because office hours have ended (after 17:00)."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      // Deteksi terlambat (setelah pukul 08:00)
      if (now.hour > 8 || (now.hour == 8 && now.minute > 0)) {
        confirmTitle = "Confirm Check In (Late)";
        confirmContent = "You are checking in after 08:00 (Late).\n\nAre you sure you want to proceed?";
        confirmColor = Colors.red;
      }
    } else if (widget.currentStatus == "checkin") {
      // Deteksi pulang cepat (sebelum pukul 17:00)
      if (now.hour < 17) {
        confirmTitle = "Early Departure Warning";
        confirmContent = "You are checking out early (before 17:00).\n\nAre you sure you want to check out now?";
        confirmColor = Colors.orange;
      } else {
        confirmTitle = "Confirm Check Out";
        confirmContent = "Are you sure you want to check out now?";
      }
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(confirmTitle, style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold)),
        content: Text(confirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(widget.currentStatus == "none" ? "Yes, Check In" : "Yes, Check Out"),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      String userKey = prefs.getString('active_user_email') ?? "default";

      String attendanceDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String checkTime = DateFormat('HH:mm').format(DateTime.now());
      String finalAddress = "[$workMode] $currentAddress";

      if (widget.currentStatus == "none") {
        await _attendanceService.postCheckIn(
          token: token!,
          attendanceDate: attendanceDate,
          checkInTime: checkTime,
          lat: myPos!.latitude,
          lng: myPos!.longitude,
          address: finalAddress,
        );

        await prefs.setString('saved_checkin_$userKey', checkTime);
        await prefs.setString('saved_checkin_date_$userKey', attendanceDate);
        await prefs.setString(
          'saved_checkin_location_$userKey',
          finalAddress,
        );

        if (!mounted) return;
        setState(() {
          checkInTimeDisplay = checkTime;
          checkInLocationDisplay = finalAddress;
        });
      } else if (widget.currentStatus == "checkin") {
        await _attendanceService.postCheckOut(
          token: token!,
          attendanceDate: attendanceDate,
          checkOutTime: checkTime,
          lat: myPos!.latitude,
          lng: myPos!.longitude,
          address: finalAddress,
        );

        await prefs.setString('saved_checkout_$userKey', checkTime);
        await prefs.setString('saved_checkout_date_$userKey', attendanceDate);
        await prefs.setString(
          'saved_checkout_location_$userKey',
          finalAddress,
        );

        if (!mounted) return;
        setState(() {
          checkOutTimeDisplay = checkTime;
          checkOutLocationDisplay = finalAddress;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance Successful!")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool get isButtonEnabled {
    if (isLoading) return false;
    if (widget.currentStatus == "checkout") return false;
    return true;
  }

  Widget _buildModeChip(String mode, IconData icon) {
    bool isSelected = workMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          workMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.blueGrey.shade800
                  : AppColor.primary.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.blueGrey.shade600
                    : AppColor.primary)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColor.primary)
                  : Colors.grey,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mode,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColor.primary)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Live Attendance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
          
          // Mode Pilihan Chip Kerja
          if (widget.currentStatus != "checkout")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Work Mode:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildModeChip("WFO", Icons.business)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildModeChip("WFH", Icons.home)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildModeChip("Field Work", Icons.commute)),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: myPos != null
                                  ? LatLng(myPos!.latitude, myPos!.longitude)
                                  : const LatLng(-6.2000, 106.8166),
                              zoom: 16,
                            ),
                            onMapCreated: (controller) {
                              mapController = controller;
                              if (myPos != null) {
                                mapController?.animateCamera(
                                  CameraUpdate.newLatLng(LatLng(myPos!.latitude, myPos!.longitude)),
                                );
                              }
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            markers: myPos == null
                                ? {}
                                : {
                                    Marker(
                                      markerId: const MarkerId("current_pos"),
                                      position: LatLng(myPos!.latitude, myPos!.longitude),
                                      infoWindow: const InfoWindow(title: "Your Location"),
                                    ),
                                  },
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: FloatingActionButton.small(
                              heroTag: "my_location_btn",
                              backgroundColor: Colors.white,
                              foregroundColor: AppColor.primary,
                              child: const Icon(Icons.my_location, size: 20),
                              onPressed: () {
                                if (myPos != null) {
                                  mapController?.animateCamera(
                                    CameraUpdate.newLatLng(LatLng(myPos!.latitude, myPos!.longitude)),
                                  );
                                } else {
                                  _determinePosition();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColor.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                currentAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
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
                              backgroundColor: isButtonEnabled
                                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey.shade800 : AppColor.primary)
                                  : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: isButtonEnabled ? processAbsen : null,
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    widget.currentStatus == "none"
                                        ? "Check In Now"
                                        : widget.currentStatus == "checkin"
                                            ? "Check Out Now"
                                            : "View Attendance",
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
    String cleanLocation = location;
    String modeTag = "";
    if (location.startsWith("[WFO]")) {
      cleanLocation = location.substring(5);
      modeTag = "WFO";
    } else if (location.startsWith("[WFH]")) {
      cleanLocation = location.substring(5);
      modeTag = "WFH";
    } else if (location.startsWith("[Field Work]")) {
      cleanLocation = location.substring(12);
      modeTag = "Field Work";
    } else if (location.startsWith("[Dinas Luar]")) {
      cleanLocation = location.substring(12);
      modeTag = "Field Work";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        if (modeTag.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              modeTag,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          cleanLocation,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}
