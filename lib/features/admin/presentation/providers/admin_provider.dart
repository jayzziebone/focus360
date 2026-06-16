import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/location_model.dart';
import '../../../employee/data/models/shift_model.dart';
import '../../../employee/data/models/attendance_record_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

// Stream of onboarded employers
final adminEmployersProvider = StreamProvider<List<UserModel>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getEmployers();
});

// Stream of onboarded employees
final adminEmployeesProvider = StreamProvider<List<UserModel>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getEmployees();
});

// Stream of system locations
final adminLocationsProvider = StreamProvider<List<LocationModel>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getLocations();
});

// Stream of all schedules
final adminShiftsProvider = StreamProvider<List<ShiftModel>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getShifts();
});

// Stream of all attendance records
final adminAttendanceProvider = StreamProvider<List<AttendanceRecordModel>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getAllAttendance();
});
