import 'package:flutter/material.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';

class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND MAP (sementara pakai image)
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset("assets/image/map.png", fit: BoxFit.cover),
          ),

          // OVERLAY GELAP
          Container(color: Colors.black.withOpacity(0.3)),

          // APPBAR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Attendance",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.notifications_none, color: Colors.white),
                  const SizedBox(width: 10),
                  const CircleAvatar(radius: 14),
                ],
              ),
            ),
          ),

          // GPS SIGNAL
          Positioned(
            top: 80,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("GPS Signal: Strong"),
            ),
          ),

          // PIN LOKASI
          const Center(
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.location_on, size: 30, color: Colors.blue),
            ),
          ),

          // BOTTOM CARD
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CURRENT LOCATION",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "North Creek Business Park",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "128 Technology Drive, Building 4, Suite 200",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _infoBox(
                          icon: Icons.access_time,
                          title: "SCHEDULED",
                          value: "09:00 AM",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoBox(
                          icon: Icons.my_location,
                          title: "ACCURACY",
                          value: "< 5 Meters",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Check In"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Center(
                    child: Text(
                      "Your location is recorded only at the moment of check-in and check-out to verify workplace attendance.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Today's Timeline",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  const Text("ENTRY - Awaiting Check-in"),
                  const SizedBox(height: 5),
                  const Text(
                    "SHIFT END - 06:00 PM",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColor.primary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
