import 'package:flutter/material.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';
import 'package:tekora_app_absensi/views/checkin_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        elevation: 0,
        title: const Text("Attendance"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Good Morning,", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 4),

            const Text(
              "Alexander",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            _timeCard(context),

            const SizedBox(height: 20),

            _weeklyPresence(),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.access_time,
                    title: "AVG. TIME",
                    value: "09:12 AM",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoCard(
                    icon: Icons.timer_outlined,
                    title: "OVERTIME",
                    value: "4.5 Hrs",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Recent Activity",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text("View All", style: TextStyle(color: AppColor.primary)),
              ],
            ),

            const SizedBox(height: 10),

            _activityItem("Check In", "Headquarters • On-site", "08:42 AM"),

            _activityItem(
              "Check Out",
              "Remote • Work from home",
              "May 21, 05:30 PM",
            ),

            _activityItem(
              "Late Arrival",
              "Traffic delay noted",
              "May 20, 09:45 AM",
            ),
          ],
        ),
      ),
    );
  }

  // ================= TIME CARD =================

  Widget _timeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "CURRENT TIME",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),

          const SizedBox(height: 10),

          const Text(
            "08:42",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 5),

          const Text("Monday, 24 May", style: TextStyle(color: Colors.white70)),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckInScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Check In",
                    style: TextStyle(color: AppColor.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                  ),
                  onPressed: () {},
                  child: const Text("Check Out"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= WEEKLY =================

  Widget _weeklyPresence() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Weekly Presence",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text("4 out of 5 days recorded"),
            ],
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.orange,
            child: Text("80%"),
          ),
        ],
      ),
    );
  }

  // ================= INFO CARD =================

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColor.primary),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ================= ACTIVITY =================

  Widget _activityItem(String title, String subtitle, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
