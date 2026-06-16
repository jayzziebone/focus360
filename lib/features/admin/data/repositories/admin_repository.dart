import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shiftsync/core/constants/app_constants.dart';
import 'package:shiftsync/features/auth/data/models/user_model.dart';
import 'package:intl/intl.dart';
import '../models/location_model.dart';
import '../../../employee/data/models/shift_model.dart';
import '../../../employee/data/models/attendance_record_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of employers
  Stream<List<UserModel>> getEmployers() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'employer')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // Stream of employees
  Stream<List<UserModel>> getEmployees() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'employee')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // Stream of locations
  Stream<List<LocationModel>> getLocations() {
    return _firestore
        .collection(AppConstants.locationsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add location
  Future<void> addLocation(LocationModel location) async {
    try {
      await _firestore
          .collection(AppConstants.locationsCollection)
          .add(location.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Stream of shifts
  Stream<List<ShiftModel>> getShifts() {
    return _firestore
        .collection(AppConstants.shiftsCollection)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Create shift
  Future<void> createShift(ShiftModel shift) async {
    try {
      await _firestore
          .collection(AppConstants.shiftsCollection)
          .add(shift.toMap());

      // Send notifications
      final dateStr = DateFormat('EEE, MMM d').format(shift.startTime);
      final startStr = DateFormat('hh:mm a').format(shift.startTime);
      final endStr = DateFormat('hh:mm a').format(shift.endTime);

      final empUid = await _getUidByEmployeeId(shift.employeeId);
      if (empUid != null) {
        await _sendNotification(
          userId: empUid,
          title: 'New Shift Assigned 📅',
          body: 'You have been scheduled for a shift at ${shift.locationName} on $dateStr from $startStr to $endStr.',
          type: 'shift_created',
        );
      }

      final employerUid = await _getUidByEmployerId(shift.employerId);
      if (employerUid != null) {
        await _sendNotification(
          userId: employerUid,
          title: 'New Shift Scheduled 📅',
          body: 'A new shift has been scheduled for ${shift.employeeName} at ${shift.locationName} on $dateStr.',
          type: 'shift_created',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update shift
  Future<void> updateShift(ShiftModel shift) async {
    try {
      await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shift.id)
          .update(shift.toMap());

      // Send notifications
      final dateStr = DateFormat('EEE, MMM d').format(shift.startTime);

      final empUid = await _getUidByEmployeeId(shift.employeeId);
      if (empUid != null) {
        await _sendNotification(
          userId: empUid,
          title: 'Shift Details Updated 🔄',
          body: 'Your scheduled shift at ${shift.locationName} on $dateStr has been modified.',
          type: 'shift_modified',
        );
      }

      final employerUid = await _getUidByEmployerId(shift.employerId);
      if (employerUid != null) {
        await _sendNotification(
          userId: employerUid,
          title: 'Shift Details Updated 🔄',
          body: 'The scheduled shift for ${shift.employeeName} at ${shift.locationName} on $dateStr has been modified.',
          type: 'shift_modified',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete shift
  Future<void> deleteShift(String shiftId) async {
    try {
      // Fetch shift details first to notify targets
      final doc = await _firestore.collection(AppConstants.shiftsCollection).doc(shiftId).get();
      if (doc.exists) {
        final shift = ShiftModel.fromMap(doc.data()!, doc.id);
        final dateStr = DateFormat('EEE, MMM d').format(shift.startTime);

        final empUid = await _getUidByEmployeeId(shift.employeeId);
        if (empUid != null) {
          await _sendNotification(
            userId: empUid,
            title: 'Shift Cancelled ❌',
            body: 'Your scheduled shift at ${shift.locationName} on $dateStr has been cancelled.',
            type: 'shift_deleted',
          );
        }

        final employerUid = await _getUidByEmployerId(shift.employerId);
        if (employerUid != null) {
          await _sendNotification(
            userId: employerUid,
            title: 'Shift Cancelled ❌',
            body: 'The scheduled shift for ${shift.employeeName} at ${shift.locationName} on $dateStr has been cancelled.',
            type: 'shift_deleted',
          );
        }
      }

      await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Advanced Client-Side User Onboarding without interrupting current admin session
  Future<String> onboardUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? employerId,
    String? employeeId,
    double? latitude,
    double? longitude,
  }) async {
    FirebaseApp? tempApp;
    try {
      // Create temporary app instance
      final String tempAppName = 'OnboardApp_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );

      final FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // Create credential on temporary instance
      final UserCredential credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String newUid = credential.user!.uid;

      // Create model profile
      final UserModel newUser = UserModel(
        uid: newUid,
        email: email,
        fullName: fullName,
        role: role,
        employerId: employerId ?? (role == UserRole.employer ? 'employer_${DateTime.now().millisecondsSinceEpoch}' : null),
        employeeId: employeeId ?? (role == UserRole.employee ? 'employee_${DateTime.now().millisecondsSinceEpoch}' : null),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        latitude: latitude,
        longitude: longitude,
      );

      // Write profile database record from primary Firebase Firestore connection
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(newUid)
          .set(newUser.toMap());

      // Write email notification record to be picked up by the Trigger Email extension
      await _firestore.collection('mail').add({
        'to': email,
        'message': {
          'subject': 'Welcome to ${AppConstants.appName} - Your Account is Ready',
          'text': 'Hello $fullName,\n\nYour account has been created on ${AppConstants.appName} by the administrator.\n\nTemporary Password: $password\n\nPlease log in and change your password in your profile tab immediately.\n\nBest regards,\n${AppConstants.appName} Team',
          'html': '<p>Hello <strong>$fullName</strong>,</p>'
                  '<p>Your account has been created on <strong>${AppConstants.appName}</strong> by the administrator.</p>'
                  '<p><strong>Temporary Password:</strong> <code>$password</code></p>'
                  '<p>Please log in and change your password in your profile tab immediately.</p>'
                  '<p>Best regards,<br/><strong>${AppConstants.appName} Team</strong></p>',
        },
      });

      print('[EMAIL SIMULATOR] Sent welcome email to $email with temporary password: $password');

      return newUid;
    } catch (e) {
      rethrow;
    } finally {
      // Cleanup the temporary secondary app
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  // Update location
  Future<void> updateLocation(LocationModel location) async {
    try {
      await _firestore
          .collection(AppConstants.locationsCollection)
          .doc(location.id)
          .update(location.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete location
  Future<void> deleteLocation(String locationId) async {
    try {
      await _firestore
          .collection(AppConstants.locationsCollection)
          .doc(locationId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile details
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Stream of all attendance records across the system
  Stream<List<AttendanceRecordModel>> getAllAttendance() {
    return _firestore
        .collection(AppConstants.attendanceCollection)
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
      print('Error sending admin notification: $e');
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
}
