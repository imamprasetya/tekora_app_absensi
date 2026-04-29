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
  List<AttendanceModel> _allHistoryData = []; // Data asli dari API
  List<AttendanceModel> _historyData = [];    // Data yang sudah difilter
  DateTime _selectedDate = DateTime.now();
  bool _isFiltered = false;

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

      if (token == null) {
        throw "Session expired, please login again.";
      }

      final data = await _attendanceService.fetchHistory(token);
      
      // Mengurutkan data (terbaru di atas)
      data.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

      _allHistoryData = data;
      if (_isFiltered) {
        _applyFilter();
      } else {
        setState(() {
          _historyData = List.from(_allHistoryData);
        });
      }
      
      setState(() {
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

  // Fungsi untuk memfilter data berdasarkan bulan dan tahun yang dipilih
  void _applyFilter() {
    setState(() {
      _historyData = _allHistoryData.where((item) {
        return item.attendanceDate.year == _selectedDate.year &&
               item.attendanceDate.month == _selectedDate.month;
      }).toList();
      _isFiltered = true;
    });
  }

  // Fungsi untuk me-reset filter (menampilkan semua data)
  void _clearFilter() {
    setState(() {
      _isFiltered = false;
      _historyData = List.from(_allHistoryData);
    });
  }

  // FUNGSI BARU: Memunculkan Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      helpText: "Select History Month",
      cancelText: "Cancel",
      confirmText: "OK",
    );
    if (picked != null && (picked.year != _selectedDate.year || picked.month != _selectedDate.month)) {
      _selectedDate = picked;
      _applyFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalHadir = 0;
    int totalIzin = 0;
    int totalTelat = 0;

    for (var item in _historyData) {
      final computed = _getComputedStatus(item.status, item.checkInTime, item.checkOutTime).toLowerCase();
      if (computed.contains('izin') || computed.contains('sakit')) {
        totalIzin++;
      } else {
        totalHadir++;
        if (computed.contains('telat')) {
          totalTelat++;
        }
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
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
                        Text(
                          "Attendance\nHistory",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
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
                            title: "PRESENT",
                            value: "$totalHadir/${_historyData.length}",
                            isProgress: true,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            title: "LATE",
                            value: totalTelat.toString().padLeft(2, '0'),
                            subtitle: "Late count",
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            title: "LEAVE",
                            value: totalIzin.toString().padLeft(2, '0'),
                            subtitle: "Leave/Sick",
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    if (_historyData.isEmpty)
                      const Center(child: Text("No attendance history yet"))
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
    return GestureDetector(
      onLongPress: _clearFilter, // Tahan untuk mereset filter
      child: Container(
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
              _isFiltered ? DateFormat('MMM yyyy').format(_selectedDate) : "All",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
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
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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
        color: Theme.of(context).cardColor,
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
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
              color: _getStatusColor(_getComputedStatus(item.status, item.checkInTime, item.checkOutTime)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _getComputedStatus(item.status, item.checkInTime, item.checkOutTime).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(_getComputedStatus(item.status, item.checkInTime, item.checkOutTime)),
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
    if (status.contains('izin') || status.contains('sakit') || status.contains('cepat') || status.contains('leave') || status.contains('sick') || status.contains('early')) return Colors.orange;
    if (status.contains('telat') || status.contains('terlambat') || status.contains('late')) return Colors.red;
    return Colors.green;
  }

  String _getComputedStatus(String originalStatus, String? checkIn, String? checkOut) {
    String status = originalStatus.toLowerCase();
    if (status.contains('izin') || status.contains('sakit') || status.contains('telat')) {
      return originalStatus;
    }
    
    bool isLate = false;
    bool isEarlyLeave = false;

    // Cek jika absen lewat jam 08:00
    if (checkIn != null && checkIn != "--:--" && checkIn.isNotEmpty) {
      try {
        final parts = checkIn.split(':');
        if (parts.length >= 2) {
          final hours = int.tryParse(parts[0]) ?? 0;
          final mins = int.tryParse(parts[1]) ?? 0;
          if (hours > 8 || (hours == 8 && mins > 0)) {
            isLate = true;
          }
        }
      } catch (_) {}
    }

    // Cek jika pulang sebelum jam 17:00
    if (checkOut != null && checkOut != "--:--" && checkOut.isNotEmpty) {
      try {
        final parts = checkOut.split(':');
        if (parts.length >= 2) {
          final hours = int.tryParse(parts[0]) ?? 0;
          if (hours < 17) {
            isEarlyLeave = true;
          }
        }
      } catch (_) {}
    }

    if (isLate) return "Late";
    if (isEarlyLeave) return "Early Leave";
    return "On Time";
  }
}
