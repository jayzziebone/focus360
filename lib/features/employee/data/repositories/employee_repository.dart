import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shiftsync/core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import '../models/shift_model.dart';
import '../models/attendance_record_model.dart';
import 'package:shiftsync/features/admin/data/models/location_model.dart';
import 'package:shiftsync/features/auth/data/models/user_model.dart';


class EmployeeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of shifts for a specific employee
  Stream<List<ShiftModel>> getEmployeeShifts(String employeeId) {
    return _firestore
        .collection(AppConstants.shiftsCollection)
        .where('employeeId', isEqualTo: employeeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream of attendance records for a specific employee
  Stream<List<AttendanceRecordModel>> getEmployeeAttendanceHistory(String employeeId) {
    return _firestore
        .collection(AppConstants.attendanceCollection)
        .where('employeeId', isEqualTo: employeeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get active/ongoing attendance record if any
  Future<AttendanceRecordModel?> getActiveAttendance(String employeeId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.attendanceCollection)
          .where('employeeId', isEqualTo: employeeId)
          .where('approvedStatus', isEqualTo: 'pending')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['punchOutTime'] == null) {
          return AttendanceRecordModel.fromMap(data, doc.id);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Punch clock in
  Future<void> punchIn(AttendanceRecordModel record) async {
    try {
      // 1. Save attendance record
      await _firestore
          .collection(AppConstants.attendanceCollection)
          .doc(record.id.isEmpty ? null : record.id)
          .set(record.toMap());

      // 2. Update shift status to 'in_progress'
      await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(record.shiftId)
          .update({'status': 'in_progress'});

      // Send notifications
      final timeStr = DateFormat('hh:mm a').format(record.punchInTime);
      final oobStr = record.punchInVerified ? '' : ' ⚠️ [OUT OF BOUNDS ALERT]';
      final title = 'Employee Clocked In 🕒';
      final body = '${record.employeeName} clocked in at $timeStr for shift${oobStr}.';

      // 1. Notify Employer
      if (record.employerId != null) {
        final employerUid = await _getUidByEmployerId(record.employerId!);
        if (employerUid != null) {
          await _sendNotification(
            userId: employerUid,
            title: title,
            body: body,
            type: 'punch_in',
          );
        }
      }

      // 2. Notify Admins
      final adminUids = await _getAdminUids();
      for (var adminUid in adminUids) {
        await _sendNotification(
          userId: adminUid,
          title: title,
          body: body,
          type: 'punch_in',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Punch clock out
  Future<void> punchOut({
    required String recordId,
    required String shiftId,
    required double latitude,
    required double longitude,
    required bool verified,
  }) async {
    try {
      // 1. Update attendance record
      await _firestore
          .collection(AppConstants.attendanceCollection)
          .doc(recordId)
          .update({
        'punchOutTime': Timestamp.fromDate(DateTime.now()),
        'punchOutLatitude': latitude,
        'punchOutLongitude': longitude,
        'punchOutVerified': verified,
      });

      // 2. Update shift status to 'completed'
      await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .update({'status': 'completed'});

      // Send notifications
      final recordDoc = await _firestore.collection(AppConstants.attendanceCollection).doc(recordId).get();
      if (recordDoc.exists) {
        final recordMap = recordDoc.data()!;
        final employeeName = recordMap['employeeName'] ?? 'An employee';
        final employerId = recordMap['employerId'];

        final timeStr = DateFormat('hh:mm a').format(DateTime.now());
        final oobStr = verified ? '' : ' ⚠️ [OUT OF BOUNDS ALERT]';
        final title = 'Employee Clocked Out 🕒';
        final body = '$employeeName clocked out at $timeStr${oobStr}.';

        // 1. Notify Employer
        if (employerId != null) {
          final employerUid = await _getUidByEmployerId(employerId);
          if (employerUid != null) {
            await _sendNotification(
              userId: employerUid,
              title: title,
              body: body,
              type: 'punch_out',
            );
          }
        }

        // 2. Notify Admins
        final adminUids = await _getAdminUids();
        for (var adminUid in adminUids) {
          await _sendNotification(
            userId: adminUid,
            title: title,
            body: body,
            type: 'punch_out',
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Stream of locations for a specific employer
  Stream<List<LocationModel>> getEmployerLocations(String employerId) {
    return _firestore
        .collection(AppConstants.locationsCollection)
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get location details by ID
  Future<LocationModel?> getLocationById(String locationId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.locationsCollection)
          .doc(locationId)
          .get();
      if (doc.exists && doc.data() != null) {
        return LocationModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Helper to send a notification to a specific user UID
  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending employee notification: $e');
    }
  }

  // Look up user UID from employerId
  Future<String?> _getUidByEmployerId(String employerId) async {
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('employerId', isEqualTo: employerId)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    return null;
  }

  // Get all Admin UIDs
  Future<List<String>> _getAdminUids() async {
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'admin')
        .get();
    return query.docs.map((doc) => doc.id).toList();
  }

  // Stream of employer user details
  Stream<UserModel?> getEmployerDetails(String employerId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'employer')
        .where('employerId', isEqualTo: employerId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return UserModel.fromMap(snapshot.docs.first.data());
          }
          return null;
        });
  }
}
