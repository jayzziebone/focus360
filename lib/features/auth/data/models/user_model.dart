import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  employee,
  employer,
  admin,
}

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final String? employerId;
  final String? employeeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final double? latitude;
  final double? longitude;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.employerId,
    this.employeeId,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.latitude,
    this.longitude,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    UserRole parsedRole;
    switch (map['role']) {
      case 'employer':
        parsedRole = UserRole.employer;
        break;
      case 'admin':
        parsedRole = UserRole.admin;
        break;
      case 'employee':
      default:
        parsedRole = UserRole.employee;
        break;
    }

    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: parsedRole,
      employerId: map['employerId'],
      employeeId: map['employeeId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role.name,
      'employerId': employerId,
      'employeeId': employeeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    UserRole? role,
    String? employerId,
    String? employeeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    double? latitude,
    double? longitude,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      employerId: employerId ?? this.employerId,
      employeeId: employeeId ?? this.employeeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
