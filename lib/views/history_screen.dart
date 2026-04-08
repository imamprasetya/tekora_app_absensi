import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekora_app_absensi/models/attendence_model.dart';
import 'package:tekora_app_absensi/services/api/attendence.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  List<AttendanceModel> _historyData = [];
  DateTime _selectedDate =
      DateTime.now(); // Variabel untuk menyimpan bulan yang dipilih

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw "Sesi berakhir, silakan login kembali.";
      }

      final data = await _attendanceService.fetchHistory(token);
      
      // Mengurutkan data (terbaru di atas)
      data.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

      setState(() {
        _historyData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // FUNGSI BARU: Memunculkan Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      helpText: "Pilih Bulan Riwayat",
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Di sini Anda bisa memanggil API lagi jika backend mendukung filter per bulan
        // _loadHistoryWithFilter(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalHadir = _historyData
        .where((e) => e.status.toLowerCase() == 'masuk')
        .length;
    int totalIzin = _historyData
        .where((e) => e.status.toLowerCase() == 'izin')
        .length;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(12.0),
          child: CircleAvatar(
            backgroundColor: Color(0x1A2196F3),
            child: Icon(Icons.fingerprint, color: Colors.blue, size: 20),
          ),
        ),
        title: const Text(
          "Attendance",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        // Dropdown yang bisa diklik
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(20),
                          child: _buildFilterDropdown(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: "HADIR",
                            value: "$totalHadir/${_historyData.length}",
                            isProgress: true,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildSummaryCard(
                            title: "IZIN",
                            value: totalIzin.toString().padLeft(2, '0'),
                            subtitle: "Total absensi izin/sakit",
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    if (_historyData.isEmpty)
                      const Center(child: Text("Belum ada riwayat absensi"))
                    else
                      ..._historyData
                          .map((item) => _buildHistoryItem(item))
                          .toList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }

  // --- Widget Card & Item sama seperti sebelumnya (tetap rapi) ---
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          if (isProgress)
            LinearProgressIndicator(
              value: 0.8,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 6,
            )
          else if (subtitle != null)
            Text(subtitle, style: TextStyle(fontSize: 9, color: color)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(AttendanceModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(item.attendanceDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(item.attendanceDate).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE').format(item.attendanceDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${item.checkInTime ?? '--:--'} - ${item.checkOutTime ?? '--:--'}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(item.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(item.status),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('izin') || status.contains('sakit')) return Colors.orange;
    if (status.contains('telat') || status.contains('terlambat')) return Colors.red;
    return Colors.green;
  }
}
