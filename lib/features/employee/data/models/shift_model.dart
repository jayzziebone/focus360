import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employerId;
  final String locationId;
  final String locationName;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // scheduled, in_progress, completed, missed
  final DateTime createdAt;

  ShiftModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employerId,
    required this.locationId,
    required this.locationName,
    required this.startTime,
    required this.endTime,
    this.status = 'scheduled',
    required this.createdAt,
  });

  factory ShiftModel.fromMap(Map<String, dynamic> map, String id) {
    return ShiftModel(
      id: id,
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      employerId: map['employerId'] ?? '',
      locationId: map['locationId'] ?? '',
      locationName: map['locationName'] ?? '',
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'scheduled',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employerId': employerId,
      'locationId': locationId,
      'locationName': locationName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ShiftModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employerId,
    String? locationId,
    String? locationName,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    DateTime? createdAt,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employerId: employerId ?? this.employerId,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
