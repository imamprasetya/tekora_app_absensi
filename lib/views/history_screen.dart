import 'package:flutter/material.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: CircleAvatar(
            backgroundColor: AppColor.primary.withOpacity(0.1),
            child: const Icon(
              Icons.fingerprint,
              color: AppColor.primary,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          "Attendance",
          style: TextStyle(
            color: AppColor.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColor.textGrey,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Judul & Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Riwayat\nAbsensi",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Oktober 2023",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // SUMMARY CARDS
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: "HADIR",
                    value: "22/24",
                    isProgress: true,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildSummaryCard(
                    title: "TERLAMBAT",
                    value: "02",
                    subtitle: "8% dari total kehadiran",
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // LIST RIWAYAT
            _historyItem(
              date: "24",
              month: "OKT",
              day: "Selasa",
              status: "TEPAT WAKTU",
              clockIn: "08:52",
              clockOut: "17:05",
              isLate: false,
            ),
            _historyItem(
              date: "23",
              month: "OKT",
              day: "Senin",
              status: "TERLAMBAT",
              clockIn: "09:15",
              clockOut: "17:00",
              isLate: true,
            ),
            _historyItem(
              date: "20",
              month: "OKT",
              day: "Jumat",
              status: "TEPAT WAKTU",
              clockIn: "08:45",
              clockOut: "17:15",
              isLate: false,
            ),
            _historyItem(
              date: "19",
              month: "OKT",
              day: "Kamis",
              status: "TEPAT WAKTU",
              clockIn: "08:30",
              clockOut: "17:02",
              isLate: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    String? subtitle,
    bool isProgress = false,
    required Color color,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColor.textGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isProgress ? Colors.blue.shade800 : Colors.red.shade800,
            ),
          ),
          const Spacer(),
          if (isProgress)
            LinearProgressIndicator(
              value: 0.9,
              backgroundColor: Colors.blue.shade50,
              color: Colors.blue,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            )
          else if (subtitle != null)
            Row(
              children: [
                const Icon(Icons.trending_up, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(fontSize: 9, color: Colors.red),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _historyItem({
    required String date,
    required String month,
    required String day,
    required String status,
    required String clockIn,
    required String clockOut,
    required bool isLate,
  }) {
    Color statusColor = isLate ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Date Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: statusColor,
                  ),
                ),
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.login,
                      size: 14,
                      color: isLate ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      clockIn,
                      style: TextStyle(
                        fontSize: 12,
                        color: isLate ? Colors.red : Colors.grey,
                        fontWeight: isLate
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.logout, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      clockOut,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColor.textGrey,
          ),
        ],
      ),
    );
  }
}
