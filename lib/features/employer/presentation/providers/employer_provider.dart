import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftsync/features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/employer_repository.dart';
import '../../../employee/data/models/shift_model.dart';
import '../../../employee/data/models/attendance_record_model.dart';

final employerRepositoryProvider = Provider<EmployerRepository>((ref) {
  return EmployerRepository();
});

// Stream of all shifts scheduled under this organization
final employerShiftsProvider = StreamProvider<List<ShiftModel>>((ref) {
  final authState = ref.watch(authProvider);
  final employerId = authState.userModel?.employerId;
  print('=== [DEBUG] employerShiftsProvider: employerId=$employerId ===');
  if (employerId == null) return Stream.value([]);

  final repository = ref.watch(employerRepositoryProvider);
  return repository.getEmployerShifts(employerId).map((list) {
    print('=== [DEBUG] employerShiftsProvider received ${list.length} shifts ===');
    for (var s in list) {
      print('  - Shift: id=${s.id}, employeeName=${s.employeeName}, startTime=${s.startTime}, employerId=${s.employerId}, status=${s.status}');
    }
    return list;
  });
});

// Stream of pending attendance records waiting for review
final pendingApprovalsProvider = StreamProvider<List<AttendanceRecordModel>>((ref) {
  final authState = ref.watch(authProvider);
  final employerId = authState.userModel?.employerId;
  print('=== [DEBUG] pendingApprovalsProvider: employerId=$employerId ===');
  if (employerId == null) return Stream.value([]);

  final repository = ref.watch(employerRepositoryProvider);
  return repository.getPendingApprovals(employerId).map((list) {
    print('=== [DEBUG] pendingApprovalsProvider received ${list.length} pending logs ===');
    for (var r in list) {
      print('  - Pending record: id=${r.id}, employeeName=${r.employeeName}, punchInTime=${r.punchInTime}, employerId=${r.employerId}');
    }
    return list;
  });
});

// Stream of attendance history (approved/rejected)
final attendanceHistoryProvider = StreamProvider<List<AttendanceRecordModel>>((ref) {
  final authState = ref.watch(authProvider);
  final employerId = authState.userModel?.employerId;
  print('=== [DEBUG] attendanceHistoryProvider: employerId=$employerId ===');
  if (employerId == null) return Stream.value([]);

  final repository = ref.watch(employerRepositoryProvider);
  return repository.getAttendanceHistory(employerId).map((list) {
    print('=== [DEBUG] attendanceHistoryProvider received ${list.length} history logs ===');
    for (var r in list) {
      print('  - History record: id=${r.id}, employeeName=${r.employeeName}, status=${r.approvedStatus}, employerId=${r.employerId}');
    }
    return list;
  });
});
