import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Tambahkan ini
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekora_app_absensi/services/absen/checkin_service.dart';
import 'package:tekora_app_absensi/services/absen/checkout_service.dart';
import 'package:tekora_app_absensi/utils/location_helper.dart';

class CheckInScreen extends StatefulWidget {
  final String currentStatus;
  const CheckInScreen({super.key, required this.currentStatus});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool isLoading = false;
  Position? myPos;
  String currentAddress = "Mencari lokasi...";
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // AMBIL LOKASI & ALAMAT SEKALIGUS
  Future<void> _initLocation() async {
    try {
      // 1. Ambil Koordinat
      Position position = await getCurrentLocation();

      // 2. Ubah Koordinat jadi Nama Alamat (Reverse Geocoding)
      String address = await getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        myPos = position;
        currentAddress = address;
      });

      // 3. Gerakkan kamera map ke lokasi user
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      debugPrint("Gagal ambil lokasi: $e");
      setState(() {
        currentAddress = "Gagal mendapatkan alamat";
      });
    }
  }

  // EKSEKUSI ABSEN (CHECK IN / CHECK OUT)
  Future<void> processAbsen() async {
    if (myPos == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Menunggu sinyal GPS...")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      String attendanceDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String checkTime = DateFormat('HH:mm:ss').format(DateTime.now());

      if (widget.currentStatus == "none") {
        await checkIn(
          token: token!,
          attendanceDate: attendanceDate,
          checkInTime: checkTime,
          lat: myPos!.latitude,
          lng: myPos!.longitude,
          address: currentAddress, // MENGIRIM ALAMAT ASLI
        );
      } else {
        await checkOut(
          token: token!,
          attendanceDate: attendanceDate,
          checkOutTime: checkTime,
          lat: myPos!.latitude,
          lng: myPos!.longitude,
          address: currentAddress, // MENGIRIM ALAMAT ASLI
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. MAPS ASLI (Google Maps)
          myPos == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(myPos!.latitude, myPos!.longitude),
                    zoom: 17,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true, // Menampilkan titik biru lokasi user
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                ),

          // 2. Tombol Back
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // 3. Bottom Card (Menampilkan Alamat Real)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "CURRENT LOCATION",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // MENAMPILKAN ALAMAT ASLI
                  Text(
                    currentAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 5),

                  // Menampilkan Koordinat di bawah alamat
                  if (myPos != null)
                    Text(
                      "${myPos!.latitude.toStringAsFixed(6)}, ${myPos!.longitude.toStringAsFixed(6)}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Tombol Utama
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D1B5E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: isLoading ? null : processAbsen,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.currentStatus == "none"
                                      ? Icons.login
                                      : Icons.logout,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.currentStatus == "none"
                                      ? "Check In"
                                      : "Check Out",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
