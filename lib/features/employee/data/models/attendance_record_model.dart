import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecordModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employerId;
  final String shiftId;
  final DateTime punchInTime;
  final DateTime? punchOutTime;
  final double punchInLatitude;
  final double punchInLongitude;
  final double? punchOutLatitude;
  final double? punchOutLongitude;
  final bool punchInVerified;
  final bool? punchOutVerified;
  final String approvedStatus; // pending, approved, rejected
  final String? approvedByEmployerId;
  final DateTime? approvedTime;
  final String? rejectionReason;

  AttendanceRecordModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employerId,
    required this.shiftId,
    required this.punchInTime,
    this.punchOutTime,
    required this.punchInLatitude,
    required this.punchInLongitude,
    this.punchOutLatitude,
    this.punchOutLongitude,
    required this.punchInVerified,
    this.punchOutVerified,
    this.approvedStatus = 'pending',
    this.approvedByEmployerId,
    this.approvedTime,
    this.rejectionReason,
  });

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecordModel(
      id: id,
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      employerId: map['employerId'] ?? '',
      shiftId: map['shiftId'] ?? '',
      punchInTime: (map['punchInTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      punchOutTime: (map['punchOutTime'] as Timestamp?)?.toDate(),
      punchInLatitude: (map['punchInLatitude'] as num?)?.toDouble() ?? 0.0,
      punchInLongitude: (map['punchInLongitude'] as num?)?.toDouble() ?? 0.0,
      punchOutLatitude: (map['punchOutLatitude'] as num?)?.toDouble(),
      punchOutLongitude: (map['punchOutLongitude'] as num?)?.toDouble(),
      punchInVerified: map['punchInVerified'] ?? false,
      punchOutVerified: map['punchOutVerified'] as bool?,
      approvedStatus: map['approvedStatus'] ?? 'pending',
      approvedByEmployerId: map['approvedByEmployerId'] as String?,
      approvedTime: (map['approvedTime'] as Timestamp?)?.toDate(),
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employerId': employerId,
      'shiftId': shiftId,
      'punchInTime': Timestamp.fromDate(punchInTime),
      'punchOutTime': punchOutTime != null ? Timestamp.fromDate(punchOutTime!) : null,
      'punchInLatitude': punchInLatitude,
      'punchInLongitude': punchInLongitude,
      'punchOutLatitude': punchOutLatitude,
      'punchOutLongitude': punchOutLongitude,
      'punchInVerified': punchInVerified,
      'punchOutVerified': punchOutVerified,
      'approvedStatus': approvedStatus,
      'approvedByEmployerId': approvedByEmployerId,
      'approvedTime': approvedTime != null ? Timestamp.fromDate(approvedTime!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  AttendanceRecordModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employerId,
    String? shiftId,
    DateTime? punchInTime,
    DateTime? punchOutTime,
    double? punchInLatitude,
    double? punchInLongitude,
    double? punchOutLatitude,
    double? punchOutLongitude,
    bool? punchInVerified,
    bool? punchOutVerified,
    String? approvedStatus,
    String? approvedByEmployerId,
    DateTime? approvedTime,
    String? rejectionReason,
  }) {
    return AttendanceRecordModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employerId: employerId ?? this.employerId,
      shiftId: shiftId ?? this.shiftId,
      punchInTime: punchInTime ?? this.punchInTime,
      punchOutTime: punchOutTime ?? this.punchOutTime,
      punchInLatitude: punchInLatitude ?? this.punchInLatitude,
      punchInLongitude: punchInLongitude ?? this.punchInLongitude,
      punchOutLatitude: punchOutLatitude ?? this.punchOutLatitude,
      punchOutLongitude: punchOutLongitude ?? this.punchOutLongitude,
      punchInVerified: punchInVerified ?? this.punchInVerified,
      punchOutVerified: punchOutVerified ?? this.punchOutVerified,
      approvedStatus: approvedStatus ?? this.approvedStatus,
      approvedByEmployerId: approvedByEmployerId ?? this.approvedByEmployerId,
      approvedTime: approvedTime ?? this.approvedTime,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
