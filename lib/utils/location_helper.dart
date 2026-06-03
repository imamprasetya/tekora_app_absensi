import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

//FUNGSI UNTUK AMBIL KOORDINAT (LATITUDE & LONGITUDE)
Future<Position> getCurrentLocation() async {
  // Cek apakah GPS di HP aktif
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception(
      "GPS is not active. Please enable location in device settings.",
    );
  }

  // Cek izin (Permission)
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied) {
    throw Exception("Location permission denied by user.");
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      "Location permission permanently denied. Open settings to enable.",
    );
  }

  // Ambil posisi GPS dengan akurasi tinggi
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

//FUNGSI UNTUK MENGUBAH KOORDINAT MENJADI ALAMAT (REVERSE GEOCODING)
Future<String> getAddressFromLatLng(double lat, double lng) async {
  try {
    // Fungsi dari package 'geocoding' untuk menerjemahkan koordinat
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];

      // Kita susun string alamatnya dari properti yang ada di dalam Placemark
      // Kamu bisa atur sendiri mau nampilin apa aja (street, locality, dll)
      String alamatLengkap =
          "${place.street}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}";

      return alamatLengkap;
    } else {
      return "Street name not found";
    }
  } catch (e) {
    return "Failed to get address: $e";
  }
}
