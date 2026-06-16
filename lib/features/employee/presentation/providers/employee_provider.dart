import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shiftsync/features/auth/presentation/providers/auth_provider.dart';
import 'package:shiftsync/features/auth/data/models/user_model.dart';
import 'package:shiftsync/features/admin/data/models/location_model.dart';
import 'package:shiftsync/features/admin/presentation/providers/admin_provider.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/models/shift_model.dart';
import '../../data/models/attendance_record_model.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository();
});

// Stream of this employee's schedules
final employeeShiftsProvider = StreamProvider<List<ShiftModel>>((ref) {
  final authState = ref.watch(authProvider);
  final employeeId = authState.userModel?.employeeId;
  if (employeeId == null) return Stream.value([]);

  final repository = ref.watch(employeeRepositoryProvider);
  return repository.getEmployeeShifts(employeeId);
});

// Stream of this employee's attendance logs
final employeeAttendanceHistoryProvider = StreamProvider<List<AttendanceRecordModel>>((ref) {
  final authState = ref.watch(authProvider);
  final employeeId = authState.userModel?.employeeId;
  print('=== [DEBUG] employeeAttendanceHistoryProvider: employeeId=$employeeId ===');
  if (employeeId == null) return Stream.value([]);

  final repository = ref.watch(employeeRepositoryProvider);
  return repository.getEmployeeAttendanceHistory(employeeId).map((list) {
    print('=== [DEBUG] employeeAttendanceHistoryProvider received data: ${list.length} records ===');
    for (var r in list) {
      print('  - Attendance ID: ${r.id}, status: ${r.approvedStatus}, punchOutTime: ${r.punchOutTime}');
    }
    return list;
  }).handleError((err) {
    print('=== [DEBUG] employeeAttendanceHistoryProvider error: $err ===');
  });
});

// Reactive provider for the currently active/ongoing attendance record (punched in but not punched out)
final activeAttendanceProvider = Provider<AttendanceRecordModel?>((ref) {
  final historyAsync = ref.watch(employeeAttendanceHistoryProvider);
  print('=== [DEBUG] activeAttendanceProvider: historyAsync.state = ${historyAsync.runtimeType} (isLoading=${historyAsync.isLoading}, hasValue=${historyAsync.hasValue}) ===');
  return historyAsync.when(
    data: (records) {
      final active = records.where((r) => r.punchOutTime == null && r.approvedStatus != 'rejected').toList();
      final result = active.isNotEmpty ? active.first : null;
      print('=== [DEBUG] activeAttendanceProvider evaluated to: $result (punchInTime=${result?.punchInTime}) ===');
      return result;
    },
    loading: () {
      print('=== [DEBUG] activeAttendanceProvider: Loading... returning null ===');
      return null;
    },
    error: (err, stack) {
      print('=== [DEBUG] activeAttendanceProvider Error: $err ===');
      return null;
    },
  );
});

// Reactive provider to check if the employee has any attendance record with approvedStatus == 'pending' while they are not clocked in.
// This is to avoid duplicates when they punch in again before approval.
final hasPendingApprovalProvider = Provider<bool>((ref) {
  final historyAsync = ref.watch(employeeAttendanceHistoryProvider);
  final active = ref.watch(activeAttendanceProvider);
  
  // If they are currently clocked in, they are in the PUNCH OUT state, so we don't block their checkout.
  if (active != null) return false;
  
  return historyAsync.when(
    data: (records) {
      final hasPending = records.any((r) => r.approvedStatus == 'pending');
      print('=== [DEBUG] hasPendingApprovalProvider: hasPending=$hasPending ===');
      return hasPending;
    },
    loading: () => false,
    error: (err, stack) => false,
  );
});

// Reactive provider to check if the employee has already successfully punched in for today's shift (either pending or approved).
final isShiftCompletedOrPendingProvider = Provider<bool>((ref) {
  final historyAsync = ref.watch(employeeAttendanceHistoryProvider);
  final punchState = ref.watch(punchProvider);
  final todayShift = punchState.todayShift;

  if (todayShift == null) return false;

  return historyAsync.when(
    data: (records) {
      return records.any((r) => r.shiftId == todayShift.id && r.approvedStatus != 'rejected');
    },
    loading: () => false,
    error: (err, stack) => false,
  );
});

// Stream of this employee's employer's locations
final employeeLocationsProvider = StreamProvider<List<LocationModel>>((ref) {
  final authState = ref.watch(authProvider);
  final employerId = authState.userModel?.employerId;
  print('=== [DEBUG] employeeLocationsProvider: employerId=$employerId ===');
  if (employerId == null) return Stream.value([]);

  final repository = ref.watch(employeeRepositoryProvider);
  return repository.getEmployerLocations(employerId).map((list) {
    print('=== [DEBUG] employeeLocationsProvider received data: ${list.length} locations ===');
    return list;
  });
});

// Stream of this employee's assigned employer user details
final employeeEmployerProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  final employerId = authState.userModel?.employerId;
  if (employerId == null) return Stream.value(null);

  final repository = ref.watch(employeeRepositoryProvider);
  return repository.getEmployerDetails(employerId);
});

// Punch Clock State representation
class PunchState {
  final bool isCheckingGps;
  final bool isPunching;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? distanceToTargetMeters;
  final bool isWithinRadius;
  final String? errorMessage;
  final ShiftModel? todayShift;
  final LocationModel? todayLocation;

  PunchState({
    this.isCheckingGps = false,
    this.isPunching = false,
    this.currentLatitude,
    this.currentLongitude,
    this.distanceToTargetMeters,
    this.isWithinRadius = false,
    this.errorMessage,
    this.todayShift,
    this.todayLocation,
  });

  PunchState copyWith({
    bool? isCheckingGps,
    bool? isPunching,
    double? currentLatitude,
    double? currentLongitude,
    double? distanceToTargetMeters,
    bool? isWithinRadius,
    String? errorMessage,
    ShiftModel? todayShift,
    bool clearTodayShift = false,
    LocationModel? todayLocation,
    bool clearTodayLocation = false,
  }) {
    return PunchState(
      isCheckingGps: isCheckingGps ?? this.isCheckingGps,
      isPunching: isPunching ?? this.isPunching,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      distanceToTargetMeters: distanceToTargetMeters ?? this.distanceToTargetMeters,
      isWithinRadius: isWithinRadius ?? this.isWithinRadius,
      errorMessage: errorMessage,
      todayShift: clearTodayShift ? null : (todayShift ?? this.todayShift),
      todayLocation: clearTodayLocation ? null : (todayLocation ?? this.todayLocation),
    );
  }
}

// Riverpod Notifier to handle real-time GPS operations and punch clock actions
class PunchNotifier extends Notifier<PunchState> {
  EmployeeRepository get _repository => ref.read(employeeRepositoryProvider);

  @override
  PunchState build() {
    // Watch active user to load initial active attendance
    final authState = ref.watch(authProvider);
    final employeeId = authState.userModel?.employeeId;
    print('=== [DEBUG] PunchNotifier.build: employeeId=$employeeId ===');

    // Listen to shifts and locations synchronously to update todayShift/todayLocation
    ref.listen(employeeShiftsProvider, (previous, next) {
      print('=== [DEBUG] PunchNotifier: employeeShiftsProvider updated ===');
      next.whenData((shifts) {
        _updateTodayShiftAndLocation(shifts, ref.read(employeeLocationsProvider).value ?? []);
      });
    });

    ref.listen(employeeLocationsProvider, (previous, next) {
      print('=== [DEBUG] PunchNotifier: employeeLocationsProvider updated ===');
      next.whenData((locations) {
        _updateTodayShiftAndLocation(ref.read(employeeShiftsProvider).value ?? [], locations);
      });
    });

    // Run initial fetch on microtask
    if (employeeId != null) {
      Future.microtask(() {
        final shifts = ref.read(employeeShiftsProvider).value ?? [];
        final locations = ref.read(employeeLocationsProvider).value ?? [];
        _updateTodayShiftAndLocation(shifts, locations);
      });
    }

    return PunchState();
  }

  void _updateTodayShiftAndLocation(List<ShiftModel> shifts, List<LocationModel> locations) {
    final now = DateTime.now();
    print('=== [DEBUG] PunchNotifier._updateTodayShiftAndLocation ===');
    print('  - Current local time: $now (isUtc: ${now.isUtc})');
    print('  - Loaded shifts count: ${shifts.length}');
    print('  - Loaded locations count: ${locations.length}');

    final todayShifts = shifts.where((s) {
      final localStart = s.startTime.toLocal();
      final localNow = now.toLocal();
      final isToday = localStart.year == localNow.year &&
          localStart.month == localNow.month &&
          localStart.day == localNow.day;
      
      print('    * Shift ID: ${s.id}');
      print('      - DB StartTime: ${s.startTime} (isUtc: ${s.startTime.isUtc})');
      print('      - Local StartTime: $localStart');
      print('      - Status: ${s.status}');
      print('      - IsToday match: $isToday');
      
      return isToday && (s.status == 'scheduled' || s.status == 'in_progress' || s.status == 'completed');
    }).toList();

    ShiftModel? todayShift;
    LocationModel? todayLocation;

    if (todayShifts.isNotEmpty) {
      todayShift = todayShifts.first;
      print('  - Matched today shift ID: ${todayShift.id}, locationId: ${todayShift.locationId}');
      final matched = locations.where((l) => l.id == todayShift!.locationId).toList();
      if (matched.isNotEmpty) {
        todayLocation = matched.first;
        print('  - Matched today location: ${todayLocation.name} (id: ${todayLocation.id})');
      } else {
        print('  - WARNING: Location ID ${todayShift.locationId} not found in loaded locations! Fetching asynchronously...');
        _fetchLocationAndSetState(todayShift.locationId);
      }
    } else {
      print('  - No matching shift found for today.');
    }

    state = state.copyWith(
      todayShift: todayShift,
      clearTodayShift: todayShift == null,
      todayLocation: todayLocation,
      clearTodayLocation: todayLocation == null,
    );

    // If today's shift target changes or is loaded for the first time, check location radius
    if (todayShift != null && todayLocation != null) {
      checkGpsLocation();
    }
  }

  Future<void> _fetchLocationAndSetState(String locationId) async {
    try {
      final location = await _repository.getLocationById(locationId);
      if (location != null) {
        print('=== [DEBUG] PunchNotifier: Successfully fetched location "${location.name}" (id: ${location.id}) asynchronously ===');
        // Ensure that the todayShift is still the same before setting todayLocation
        if (state.todayShift != null && state.todayShift!.locationId == locationId) {
          state = state.copyWith(
            todayLocation: location,
          );
          checkGpsLocation();
        }
      } else {
        print('=== [DEBUG] PunchNotifier: Asynchronous fetch returned null for location ID $locationId ===');
      }
    } catch (e) {
      print('=== [DEBUG] PunchNotifier: Error fetching location asynchronously: $e ===');
    }
  }

  // Trigger real geolocation check
  Future<void> checkGpsLocation() async {
    state = state.copyWith(isCheckingGps: true, errorMessage: null);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          errorMessage: 'Location services are disabled. Please enable GPS.',
          isCheckingGps: false,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            errorMessage: 'Location permissions are denied.',
            isCheckingGps: false,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          errorMessage: 'Location permissions are permanently denied.',
          isCheckingGps: false,
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final targetLocation = state.todayLocation;
      if (targetLocation == null) {
        state = state.copyWith(
          currentLatitude: position.latitude,
          currentLongitude: position.longitude,
          isCheckingGps: false,
        );
        return;
      }

      // Calculate distance using Geolocator helper
      final double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLocation.latitude,
        targetLocation.longitude,
      );

      final bool isWithin = distance <= targetLocation.radiusMeters;

      state = state.copyWith(
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        distanceToTargetMeters: distance,
        isWithinRadius: isWithin,
        isCheckingGps: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'GPS error: $e', isCheckingGps: false);
    }
  }

  // Punch In Action
  Future<bool> triggerPunchIn() async {
    final authState = ref.read(authProvider);
    final user = authState.userModel;
    final todayShift = state.todayShift;
    final todayLocation = state.todayLocation;

    if (user == null || todayShift == null || todayLocation == null) {
      state = state.copyWith(errorMessage: 'No active shift scheduled to clock in.');
      return false;
    }

    final history = ref.read(employeeAttendanceHistoryProvider).value ?? [];
    final alreadyPunched = history.any((r) => r.shiftId == todayShift.id && r.approvedStatus != 'rejected');
    if (alreadyPunched) {
      state = state.copyWith(errorMessage: 'You have already punched in for this shift.');
      return false;
    }

    state = state.copyWith(isPunching: true);

    try {
      // Re-verify GPS directly during clock in action
      await checkGpsLocation();

      final record = AttendanceRecordModel(
        id: '', // Firestore auto ID
        employeeId: user.employeeId ?? '',
        employeeName: user.fullName,
        employerId: todayShift.employerId,
        shiftId: todayShift.id,
        punchInTime: DateTime.now(),
        punchInLatitude: state.currentLatitude ?? 0.0,
        punchInLongitude: state.currentLongitude ?? 0.0,
        punchInVerified: state.isWithinRadius,
        approvedStatus: 'pending',
      );

      await _repository.punchIn(record);

      state = state.copyWith(isPunching: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isPunching: false);
      return false;
    }
  }

  // Punch Out Action
  Future<bool> triggerPunchOut() async {
    final authState = ref.read(authProvider);
    final user = authState.userModel;
    final active = ref.read(activeAttendanceProvider);

    if (user == null || active == null) {
      state = state.copyWith(errorMessage: 'No active punch session found.');
      return false;
    }

    state = state.copyWith(isPunching: true);

    try {
      // Re-verify GPS coordinates
      await checkGpsLocation();

      await _repository.punchOut(
        recordId: active.id,
        shiftId: active.shiftId,
        latitude: state.currentLatitude ?? 0.0,
        longitude: state.currentLongitude ?? 0.0,
        verified: state.isWithinRadius,
      );

      state = state.copyWith(isPunching: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isPunching: false);
      return false;
    }
  }
}

// Punch Clock Global State Provider
final punchProvider = NotifierProvider<PunchNotifier, PunchState>(() {
  return PunchNotifier();
});
