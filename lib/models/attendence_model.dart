class AttendanceModel {
  final int id;
  final DateTime attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String status;
  final String? alasanIzin;

  AttendanceModel({
    required this.id,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.alasanIzin,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    String dateStr = json['attendance_date']?.toString() ?? json['tanggal']?.toString() ?? json['date']?.toString() ?? '';
    return AttendanceModel(
      id: json['id'] ?? 0,
      attendanceDate: DateTime.tryParse(dateStr) ?? DateTime.now(),
      checkInTime: json['check_in']?.toString() ?? json['check_in_time']?.toString() ?? json['jam_masuk']?.toString(),
      checkOutTime: json['check_out']?.toString() ?? json['check_out_time']?.toString() ?? json['jam_keluar']?.toString(),
      status: json['status'] ?? 'masuk',
      alasanIzin: json['alasan_izin'],
    );
  }
}
