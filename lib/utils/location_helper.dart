import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// 1. FUNGSI UNTUK AMBIL KOORDINAT (LATITUDE & LONGITUDE)
Future<Position> getCurrentLocation() async {
  // Cek apakah GPS di HP aktif
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception(
      "GPS tidak aktif, silakan aktifkan lokasi di pengaturan HP.",
    );
  }

  // Cek izin (Permission)
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied) {
    throw Exception("Izin lokasi ditolak oleh pengguna.");
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      "Izin lokasi ditolak permanen. Buka pengaturan untuk mengaktifkan.",
    );
  }

  // Ambil posisi GPS dengan akurasi tinggi
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

/// 2. FUNGSI UNTUK MENGUBAH KOORDINAT MENJADI ALAMAT (REVERSE GEOCODING)
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
      return "Nama jalan tidak ditemukan";
    }
  } catch (e) {
    return "Gagal mendapatkan alamat: $e";
  }
}
