import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shiftsync/core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import '../../../employee/data/models/shift_model.dart';
import '../../../employee/data/models/attendance_record_model.dart';

class EmployerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all shifts assigned to this employer
  Stream<List<ShiftModel>> getEmployerShifts(String employerId) {
    return _firestore
        .collection(AppConstants.shiftsCollection)
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream of pending attendance records waiting for review
  Stream<List<AttendanceRecordModel>> getPendingApprovals(String employerId) {
    return _firestore
        .collection(AppConstants.attendanceCollection)
        .where('employerId', isEqualTo: employerId)
        .where('approvedStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream of historically completed/reviewed attendance logs
  Stream<List<AttendanceRecordModel>> getAttendanceHistory(String employerId) {
    return _firestore
        .collection(AppConstants.attendanceCollection)
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecordModel.fromMap(doc.data(), doc.id))
            .where((record) => record.approvedStatus != 'pending' || record.punchOutTime != null)
            .toList());
  }

  // Approve attendance punch
  Future<void> approveAttendance(String recordId, String employerId) async {
    try {
      final doc = await _firestore.collection(AppConstants.attendanceCollection).doc(recordId).get();
      if (doc.exists) {
        final rec = AttendanceRecordModel.fromMap(doc.data()!, doc.id);

        await _firestore
            .collection(AppConstants.attendanceCollection)
            .doc(recordId)
            .update({
          'approvedStatus': 'approved',
          'approvedByEmployerId': employerId,
          'approvedTime': Timestamp.fromDate(DateTime.now()),
        });

        // Send notification to employee
        final empUid = await _getUidByEmployeeId(rec.employeeId);
        if (empUid != null) {
          final dateStr = DateFormat('EEE, MMM d').format(rec.punchInTime);
          await _sendNotification(
            userId: empUid,
            title: 'Attendance Approved ✅',
            body: 'Your attendance punch-in record for $dateStr has been approved by your employer.',
            type: 'approved',
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Reject attendance punch
  Future<void> rejectAttendance(String recordId, String employerId, String reason) async {
    try {
      final doc = await _firestore.collection(AppConstants.attendanceCollection).doc(recordId).get();
      if (doc.exists) {
        final rec = AttendanceRecordModel.fromMap(doc.data()!, doc.id);

        await _firestore
            .collection(AppConstants.attendanceCollection)
            .doc(recordId)
            .update({
          'approvedStatus': 'rejected',
          'approvedByEmployerId': employerId,
          'approvedTime': Timestamp.fromDate(DateTime.now()),
          'rejectionReason': reason,
        });

        // Send notification to employee
        final empUid = await _getUidByEmployeeId(rec.employeeId);
        if (empUid != null) {
          final dateStr = DateFormat('EEE, MMM d').format(rec.punchInTime);
          await _sendNotification(
            userId: empUid,
            title: 'Attendance Clock Rejected ❌',
            body: 'Your clock record for $dateStr was rejected. Reason: $reason',
            type: 'rejected',
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Stream of all attendance records for this employer
  Stream<List<AttendanceRecordModel>> getEmployerAttendance(String employerId) {
    return _firestore
        .collection(AppConstants.attendanceCollection)
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecordModel.fromMap(doc.data(), doc.id))
            .toList());
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
      print('Error sending employer notification: $e');
    }
  }

  // Look up user UID from employeeId
  Future<String?> _getUidByEmployeeId(String employeeId) async {
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('employeeId', isEqualTo: employeeId)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    return null;
  }
}
