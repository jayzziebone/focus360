import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shiftsync/core/constants/app_colors.dart';
import 'package:shiftsync/features/auth/presentation/providers/auth_provider.dart';
import 'package:shiftsync/features/notifications/presentation/widgets/notifications_bell_widget.dart';
import 'package:shiftsync/features/employee/presentation/providers/employee_provider.dart';
import 'package:shiftsync/features/employee/data/models/shift_model.dart';
import 'package:shiftsync/features/employee/data/models/attendance_record_model.dart';
import 'package:shiftsync/features/admin/data/models/location_model.dart';
import 'package:shiftsync/features/auth/data/models/user_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shiftsync/features/employee/presentation/screens/schedules_archive_screen.dart';

class EmployeeDashboardScreen extends ConsumerStatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  ConsumerState<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends ConsumerState<EmployeeDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Request fine/coarse GPS permission and perform location check on startup load
    Future.microtask(() {
      ref.read(punchProvider.notifier).checkGpsLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.userModel;

    final List<Widget> pages = [
      _buildHomeTab(user?.fullName ?? 'Employee'),
      _buildScheduleTab(),
      _buildPunchTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.secondary),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined, color: AppColors.secondary),
            selectedIcon: Icon(Icons.calendar_today, color: AppColors.primary),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined, color: AppColors.secondary),
            selectedIcon: Icon(Icons.timer, color: AppColors.primary),
            label: 'Punch',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppColors.secondary),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // --- TAB: HOME ---
  Widget _buildHomeTab(String name) {
    final punchState = ref.watch(punchProvider);
    final user = ref.watch(authProvider).userModel;
    final attendanceHistoryAsync = ref.watch(employeeAttendanceHistoryProvider);
    final attendanceHistory = attendanceHistoryAsync.value ?? [];

    final todayShift = punchState.todayShift;
    AttendanceRecordModel? todayRecord;
    if (todayShift != null) {
      final matches = attendanceHistory
          .where((r) => r.shiftId == todayShift.id && r.approvedStatus != 'rejected')
          .toList();
      if (matches.isNotEmpty) {
        todayRecord = matches.first;
      }
    }

    String statusText = 'NOT CLOCKED IN';
    Color statusColor = AppColors.pending;
    Color statusBgColor = AppColors.pending.withOpacity(0.1);

    if (todayRecord != null) {
      if (todayRecord.punchInTime != null && todayRecord.punchOutTime != null) {
        statusText = 'COMPLETED';
        statusColor = AppColors.success;
        statusBgColor = AppColors.success.withOpacity(0.1);
      } else if (todayRecord.punchInTime != null) {
        if (todayRecord.approvedStatus == 'approved') {
          statusText = 'CLOCKED IN at ${DateFormat('hh:mm a').format(todayRecord.punchInTime)}';
          statusColor = AppColors.success;
          statusBgColor = AppColors.success.withOpacity(0.1);
        } else {
          statusText = 'PENDING APPROVAL (Punched in at ${DateFormat('hh:mm a').format(todayRecord.punchInTime)})';
          statusColor = AppColors.pending;
          statusBgColor = AppColors.pending.withOpacity(0.1);
        }
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: AppColors.secondary.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user?.uid != null) NotificationsBellWidget(userId: user!.uid),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _currentIndex = 3),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.1),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Today's Shift Card (Live Firebase Data)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.primary.withOpacity(0.15), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'TODAY\'S ASSIGNED SHIFT',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                          ),
                        ),
                        const Icon(
                          Icons.work_outline,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (punchState.todayShift != null) ...[
                      Text(
                        '${DateFormat('hh:mm a').format(punchState.todayShift!.startTime)} - ${DateFormat('hh:mm a').format(punchState.todayShift!.endTime)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.pin_drop, size: 18, color: AppColors.outline),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              punchState.todayShift!.locationName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.secondary.withOpacity(0.8),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      )
                    ] else ...[
                      const Text(
                        'No Shift Scheduled Today',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enjoy your day off! Contact your administrator if you believe this is an error.',
                        style: TextStyle(fontSize: 12, color: AppColors.outline),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = 2),
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.1)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.timer, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(height: 12),
                            const Text('Punch Clock', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = 1),
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColors.tertiary.withOpacity(0.1)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.tertiary.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.calendar_month, color: AppColors.tertiary, size: 28),
                            ),
                            const SizedBox(height: 12),
                            const Text('My Schedule', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- TAB: SCHEDULES LIST ---
  Widget _buildScheduleTab() {
    final shiftsStream = ref.watch(employeeShiftsProvider);
    final attendanceHistoryAsync = ref.watch(employeeAttendanceHistoryProvider);
    final locationsAsync = ref.watch(employeeLocationsProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Schedule',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text('View your scheduled work shifts', style: TextStyle(color: AppColors.outline)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.archive_outlined, color: AppColors.primary, size: 28),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SchedulesArchiveScreen(),
                    ),
                  );
                },
                tooltip: 'Archive',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: shiftsStream.when(
              data: (list) {
                final attendanceList = attendanceHistoryAsync.value ?? [];

                // Filter for completed or missed shifts to exclude them
                final activeList = list.where((shift) {
                  final matchingRecord = attendanceList.firstWhere(
                    (r) => r.shiftId == shift.id,
                    orElse: () => AttendanceRecordModel(
                      id: '',
                      employeeId: '',
                      employeeName: '',
                      employerId: '',
                      shiftId: '',
                      punchInTime: DateTime.fromMillisecondsSinceEpoch(0),
                      punchInLatitude: 0,
                      punchInLongitude: 0,
                      punchInVerified: false,
                      approvedStatus: 'pending',
                    ),
                  );

                  if (matchingRecord.id.isNotEmpty) {
                    if (matchingRecord.punchInTime != null && matchingRecord.punchOutTime != null) {
                      return false; // completed shift, archive it
                    }
                    return true; // in progress, keep it
                  } else {
                    if (shift.endTime.isBefore(DateTime.now())) {
                      return false; // missed shift, archive it
                    }
                    return true; // scheduled, keep it
                  }
                }).toList();

                if (activeList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: AppColors.outline.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('No shifts scheduled.', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('You will be notified once a shift is assigned to you.', style: TextStyle(fontSize: 12, color: AppColors.outline)),
                      ],
                    ),
                  );
                }

                // Sort shifts from recent to past (descending chronological order)
                final sortedList = List<ShiftModel>.from(activeList)..sort((a, b) => b.startTime.compareTo(a.startTime));

                return ListView.builder(
                  itemCount: sortedList.length,
                  itemBuilder: (context, index) {
                    final shift = sortedList[index];
                    final isToday = DateUtils.isSameDay(shift.startTime.toLocal(), DateTime.now().toLocal());
                    final formattedDate = DateFormat('EEEE, MMM d, y').format(shift.startTime);
                    final formattedTime = '${DateFormat('hh:mm a').format(shift.startTime)} - ${DateFormat('hh:mm a').format(shift.endTime)}';

                    final matchingRecord = attendanceList.firstWhere(
                      (r) => r.shiftId == shift.id,
                      orElse: () => AttendanceRecordModel(
                        id: '',
                        employeeId: '',
                        employeeName: '',
                        employerId: '',
                        shiftId: '',
                        punchInTime: DateTime.fromMillisecondsSinceEpoch(0),
                        punchInLatitude: 0,
                        punchInLongitude: 0,
                        punchInVerified: false,
                        approvedStatus: 'pending',
                      ),
                    );

                    // 2. Compute dynamic operational status matching user request
                    String displayStatus = 'SCHEDULED';
                    Color statusColor = AppColors.tertiary;
                    Color statusBgColor = AppColors.tertiary.withOpacity(0.15);

                    if (matchingRecord.id.isNotEmpty) {
                      if (matchingRecord.punchInTime != null && matchingRecord.punchOutTime != null) {
                        displayStatus = 'COMPLETED';
                        statusColor = AppColors.success;
                        statusBgColor = AppColors.success.withOpacity(0.15);
                      } else if (matchingRecord.punchInTime != null && matchingRecord.punchOutTime == null) {
                        displayStatus = 'IN PROGRESS';
                        statusColor = AppColors.primary;
                        statusBgColor = AppColors.primary.withOpacity(0.15);
                      }
                    } else {
                      // No attendance record found. Check if shift has been missed (endTime is past)
                      if (shift.endTime.isBefore(DateTime.now())) {
                        displayStatus = 'MISSED';
                        statusColor = AppColors.error;
                        statusBgColor = AppColors.error.withOpacity(0.15);
                      }
                    }

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isToday ? AppColors.primary.withOpacity(0.3) : AppColors.secondary.withOpacity(0.1),
                          width: isToday ? 1.5 : 1,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () async {
                          // Search for full LocationModel metrics from loaded locations list
                          LocationModel? location;
                          final localLocations = locationsAsync.value ?? [];
                          final matched = localLocations.where((l) => l.id == shift.locationId).toList();
                          
                          if (matched.isNotEmpty) {
                            location = matched.first;
                          } else {
                            // If location is not in the cached stream list, fetch it directly from repository
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            try {
                              final repo = ref.read(employeeRepositoryProvider);
                              location = await repo.getLocationById(shift.locationId);
                            } catch (e) {
                              print('=== [DEBUG] Error fetching location details directly: $e ===');
                            }
                            if (mounted) {
                              Navigator.pop(context); // Dismiss loading indicator
                            }
                          }

                          // Fallback to dummy model if still not found
                          location ??= LocationModel(
                            id: shift.locationId,
                            name: shift.locationName,
                            address: 'Address not loaded',
                            latitude: 0.0,
                            longitude: 0.0,
                            radiusMeters: 100,
                            employerId: '',
                          );

                          if (mounted) {
                            _showLocationDialog(context, shift, location);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            isToday ? 'Today ($formattedDate)' : formattedDate,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.pin_drop, size: 14, color: AppColors.outline),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(shift.locationName, style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              displayStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error loading schedules: $err', style: const TextStyle(color: AppColors.error))),
            ),
          )
        ],
      ),
    );
  }

  // --- Gorgeous Custom Location Pinpoint Dialog with Geofence Pulse Mockup ---
  void _showLocationDialog(BuildContext context, ShiftModel shift, LocationModel location) {
    showDialog(
      context: context,
      builder: (context) {
        final formattedDate = DateFormat('EEEE, MMM d, y').format(shift.startTime);
        final formattedTime = '${DateFormat('hh:mm a').format(shift.startTime)} - ${DateFormat('hh:mm a').format(shift.endTime)}';

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.background,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Header Gradient Panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pin_drop_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      location.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SHIFT LOCATION METRICS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shift schedule details
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Full Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Workplace Address',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                location.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.outline,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // GPS Metrics
                    Row(
                      children: [
                        const Icon(Icons.radar_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GPS Geofencing Metrics',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: AppColors.outline,
                                ),
                              ),
                              Text(
                                'Allowed punch radius: ${location.radiusMeters} meters',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Real Interactive Map Widget (OpenStreetMap + Leaflet via flutter_map)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(location.latitude, location.longitude),
                            initialZoom: 15.0,
                            maxZoom: 18.0,
                            minZoom: 10.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.focus360.app',
                            ),
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: LatLng(location.latitude, location.longitude),
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderStrokeWidth: 2,
                                  borderColor: AppColors.primary,
                                  useRadiusInMeter: true,
                                  radius: location.radiusMeters.toDouble(),
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(location.latitude, location.longitude),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions Button Row (Copy GPS coordinates, launch maps via url_launcher)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(
                                text: '${location.latitude}, ${location.longitude}',
                              ));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Coordinates copied to clipboard!'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('COPY GPS'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final Uri googleMapsUri = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
                              );
                              final Uri appleMapsUri = Uri.parse(
                                'https://maps.apple.com/?q=${location.latitude},${location.longitude}',
                              );
                              try {
                                if (await canLaunchUrl(googleMapsUri)) {
                                  await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
                                } else if (await canLaunchUrl(appleMapsUri)) {
                                  await launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
                                } else {
                                  throw Exception('Could not launch maps application.');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to open maps: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.map_rounded, size: 18),
                            label: const Text('OPEN MAPS'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB: GPS PUNCH IN/OUT ---
  Widget _buildPunchTab() {
    final punchState = ref.watch(punchProvider);
    final punchNotifier = ref.read(punchProvider.notifier);
    final activeAttendance = ref.watch(activeAttendanceProvider);
    final hasPendingApproval = ref.watch(hasPendingApprovalProvider);
    final hasPunchedTodayShift = ref.watch(isShiftCompletedOrPendingProvider);

    final bool isPunchedIn = activeAttendance != null;
    final bool isPunchInBlocked = !isPunchedIn && hasPunchedTodayShift;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(
            'GPS Punch Clock',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
          ),
          const SizedBox(height: 4),
          if (punchState.todayLocation != null) ...[
            Text(
              '${punchState.todayLocation!.name} (Fence: ${punchState.todayLocation!.radiusMeters}m)',
              style: const TextStyle(color: AppColors.outline, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              punchState.todayLocation!.address,
              style: const TextStyle(color: AppColors.outline, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const Text(
              'No geofence location targeted today',
              style: TextStyle(color: AppColors.outline),
            ),
          ],

          if (isPunchInBlocked) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.primary.withOpacity(0.08),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.primary.withOpacity(0.4), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shift Attendance Submitted',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You have already successfully clocked in and submitted attendance for today\'s shift. Consecutive punch-ins are disabled to prevent duplicate hour entries.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.outline,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (hasPendingApproval) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.amber.withOpacity(0.08),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.amber.withOpacity(0.4), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Punch-In Blocked',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You have a pending attendance record awaiting employer approval. To prevent duplicate submissions, you cannot punch in again until your previous record is approved.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.outline,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // LARGE CIRCULAR ACTION BUTTON
          GestureDetector(
            onTap: (punchState.isCheckingGps || punchState.isPunching)
                ? null
                : () async {
                    if (isPunchInBlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Action locked: You have already submitted attendance for today\'s shift.'),
                          backgroundColor: Colors.amber,
                        ),
                      );
                      return;
                    }

                    if (hasPendingApproval) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Action locked: Awaiting employer approval for your previous shift.'),
                          backgroundColor: Colors.amber,
                        ),
                      );
                      return;
                    }

                    if (isPunchedIn) {
                      // Trigger clock out
                      final success = await punchNotifier.triggerPunchOut();
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Successfully clocked out! Record saved.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } else {
                      // Target shift check
                      if (punchState.todayShift == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot clock in: No active shift scheduled today.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      // Check GPS and trigger punch in
                      final success = await punchNotifier.triggerPunchIn();
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Successfully clocked in! Session pending approval.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  },
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isPunchInBlocked || hasPendingApproval)
                    ? Colors.grey.shade400
                    : (isPunchedIn ? AppColors.secondary : AppColors.primary),
                boxShadow: [
                  BoxShadow(
                    color: ((isPunchInBlocked || hasPendingApproval)
                            ? Colors.grey.shade400
                            : (isPunchedIn ? AppColors.secondary : AppColors.primary))
                        .withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 8,
                  )
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 4,
                ),
              ),
              alignment: Alignment.center,
              child: punchState.isPunching
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPunchInBlocked
                              ? Icons.task_alt
                              : (hasPendingApproval ? Icons.lock_outline : (isPunchedIn ? Icons.exit_to_app : Icons.touch_app)),
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isPunchInBlocked
                              ? 'COMPLETED'
                              : (hasPendingApproval ? 'LOCKED' : (isPunchedIn ? 'PUNCH OUT' : 'PUNCH IN')),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1.1,
                          ),
                        ),
                        if (activeAttendance != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Since ${DateFormat('hh:mm a').format(activeAttendance.punchInTime)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ],
                    ),
            ),
          ),
          const Spacer(),


          // GPS VERIFICATION STATUS CARD
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: punchState.isWithinRadius ? AppColors.primary.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        punchState.isCheckingGps
                            ? Icons.hourglass_top
                            : (punchState.isWithinRadius ? Icons.gps_fixed : Icons.gps_off),
                        color: punchState.isCheckingGps
                            ? Colors.amber
                            : (punchState.isWithinRadius ? AppColors.primary : AppColors.error),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              punchState.isCheckingGps
                                  ? 'Validating Geolocation...'
                                  : (punchState.isWithinRadius ? 'GPS Position Verified' : 'Out of Geofenced Radius'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: punchState.isCheckingGps
                                    ? Colors.amber
                                    : (punchState.isWithinRadius ? AppColors.primary : AppColors.error),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (punchState.distanceToTargetMeters != null)
                              Text(
                                'Distance to Workspace: ${punchState.distanceToTargetMeters!.toStringAsFixed(1)}m',
                                style: const TextStyle(fontSize: 12, color: AppColors.outline, fontWeight: FontWeight.w600),
                              )
                            else
                              const Text(
                                'Unable to calculate coordinates distance.',
                                style: TextStyle(fontSize: 12, color: AppColors.outline),
                              ),
                          ],
                        ),
                      ),
                      if (!punchState.isCheckingGps)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.secondary),
                          onPressed: () => punchNotifier.checkGpsLocation(),
                        )
                    ],
                  ),
                  if (punchState.errorMessage != null) ...[
                    const Divider(height: 16),
                    Text(
                      punchState.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- TAB: PROFILE & HISTORY LOGS ---
  Widget _buildProfileTab() {
    final authState = ref.watch(authProvider);
    final user = authState.userModel;
    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final attendanceAsync = ref.watch(employeeAttendanceHistoryProvider);
    final shiftsAsync = ref.watch(employeeShiftsProvider);
    final locationsAsync = ref.watch(employeeLocationsProvider);
    final employerAsync = ref.watch(employeeEmployerProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row with Title & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.lock_outline, color: AppColors.primary),
                      onPressed: () => _showChangePasswordDialog(context),
                      tooltip: 'Change Password',
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                      },
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Sleek Gradient Profile Header Card
            _buildProfileHeaderCard(user),
            const SizedBox(height: 24),

            // 2. Real-time Computed Hours & Billing Metrics
            Text(
              'Work Hours & Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const SizedBox(height: 12),
            _buildMetricsSummary(user, attendanceAsync),
            const SizedBox(height: 28),

            // 3. Assigned Primary Employer
            Text(
              'Corporate Assignment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const SizedBox(height: 12),
            _buildEmployerAssignment(employerAsync),
            const SizedBox(height: 28),

            // 4. Chronological Pay & Shift Logs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Work & Attendance Log',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
                attendanceAsync.when(
                  data: (recs) {
                    final count = recs.length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count Total Punches',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAttendanceLogsList(user, attendanceAsync, shiftsAsync, locationsAsync),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: Profile Header Card ---
  Widget _buildProfileHeaderCard(UserModel user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.secondary.withOpacity(0.1), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AppColors.primary.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: user.isActive
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'E',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: user.isActive ? AppColors.primary : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isActive
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: user.isActive ? AppColors.primary : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: AppColors.outline),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.email,
                          style: const TextStyle(color: AppColors.outline, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 14, color: AppColors.outline),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ID: ${user.employeeId ?? "None Assigned"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.outline, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: Realtime Metrics Summary ---
  Widget _buildMetricsSummary(UserModel user, AsyncValue<List<AttendanceRecordModel>> attendanceAsync) {
    return attendanceAsync.when(
      data: (records) {
        final employeeRecords = records.where((r) => r.employeeId == user.employeeId).toList();
        final now = DateTime.now();

        // 7 Days
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        final weekRecords = employeeRecords
            .where((r) => r.approvedStatus == 'approved' && r.punchOutTime != null && r.punchInTime.isAfter(sevenDaysAgo))
            .toList();
        double hoursWeek = 0.0;
        for (var r in weekRecords) {
          hoursWeek += r.punchOutTime!.difference(r.punchInTime).inMinutes / 60.0;
        }

        // 30 Days
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        final monthRecords = employeeRecords
            .where((r) => r.approvedStatus == 'approved' && r.punchOutTime != null && r.punchInTime.isAfter(thirtyDaysAgo))
            .toList();
        double hoursMonth = 0.0;
        for (var r in monthRecords) {
          hoursMonth += r.punchOutTime!.difference(r.punchInTime).inMinutes / 60.0;
        }

        // Shift count
        final pendingTotal = employeeRecords.where((r) => r.approvedStatus == 'pending').length;

        return Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HOURS (7 DAYS)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.outline, letterSpacing: 1.1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${hoursWeek.toStringAsFixed(1)} hrs',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${weekRecords.length} shifts approved',
                        style: const TextStyle(fontSize: 10, color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.amber.withOpacity(0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HOURS (30 DAYS)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.outline, letterSpacing: 1.1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${hoursMonth.toStringAsFixed(1)} hrs',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.amber, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pendingTotal pending approvals',
                        style: const TextStyle(fontSize: 10, color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error loading hours: $e', style: const TextStyle(color: AppColors.error))),
    );
  }

  // --- WIDGET: Assigned Employer Card ---
  Widget _buildEmployerAssignment(AsyncValue<UserModel?> employerAsync) {
    return employerAsync.when(
      data: (employer) {
        if (employer == null) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.tertiary.withOpacity(0.15)),
            ),
            child: const ListTile(
              leading: Icon(Icons.business, color: Colors.grey),
              title: Text('No Organization Assigned', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
              subtitle: Text('You are currently unassigned to any firm.'),
            ),
          );
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.tertiary.withOpacity(0.15)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.tertiary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.business, color: AppColors.tertiary),
            ),
            title: Text(employer.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employer.email, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text('Employer Name: ${employer.fullName}', style: const TextStyle(fontSize: 10, color: AppColors.outline, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tertiary)),
      error: (e, _) => Center(child: Text('Error loading assignment: $e')),
    );
  }

  // --- WIDGET: Attendance Logs History List ---
  Widget _buildAttendanceLogsList(
    UserModel user,
    AsyncValue<List<AttendanceRecordModel>> attendanceAsync,
    AsyncValue<List<ShiftModel>> shiftsAsync,
    AsyncValue<List<LocationModel>> locationsAsync,
  ) {
    return attendanceAsync.when(
      data: (records) {
        final employeeRecords = records.where((r) => r.employeeId == user.employeeId).toList();

        if (employeeRecords.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.secondary.withOpacity(0.08)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(28.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, color: AppColors.outline, size: 40),
                    SizedBox(height: 12),
                    Text('No attendance clock logs registered.', style: TextStyle(color: AppColors.outline, fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }

        // Sort descending chronologically
        final sortedRecords = List<AttendanceRecordModel>.from(employeeRecords)
          ..sort((a, b) => b.punchInTime.compareTo(a.punchInTime));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedRecords.length,
          itemBuilder: (context, index) {
            final rec = sortedRecords[index];
            final dateFormat = DateFormat('EEE, MMM d, yyyy');
            final timeFormat = DateFormat('hh:mm a');

            final formattedDate = dateFormat.format(rec.punchInTime);
            final formattedIn = timeFormat.format(rec.punchInTime);
            final formattedOut = rec.punchOutTime != null ? timeFormat.format(rec.punchOutTime!) : 'Active';

            double recordHours = 0.0;
            if (rec.punchOutTime != null) {
              recordHours = rec.punchOutTime!.difference(rec.punchInTime).inMinutes / 60.0;
            }

            Color statusColor = AppColors.pending;
            if (rec.approvedStatus == 'approved') {
              statusColor = AppColors.success;
            } else if (rec.approvedStatus == 'rejected') {
              statusColor = AppColors.error;
            }

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.secondary.withOpacity(0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rec.approvedStatus.toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PUNCH IN', style: TextStyle(fontSize: 9, color: AppColors.outline, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(formattedIn, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.outline, size: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PUNCH OUT', style: TextStyle(fontSize: 9, color: AppColors.outline, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(formattedOut, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: rec.punchOutTime == null ? AppColors.primary : AppColors.secondary)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('DURATION', style: TextStyle(fontSize: 9, color: AppColors.outline, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              rec.punchOutTime != null ? '${recordHours.toStringAsFixed(1)} hrs' : '--',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          rec.punchInVerified ? Icons.gps_fixed : Icons.gps_off,
                          size: 14,
                          color: rec.punchInVerified ? AppColors.primary : AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'GPS Verification: Clock-In ${rec.punchInVerified ? "OK" : "OOB"} • Clock-Out ${rec.punchOutVerified == true ? "OK" : "OOB (Out of Bounds)"}',
                            style: const TextStyle(fontSize: 10, color: AppColors.outline),
                          ),
                        ),
                      ],
                    ),
                    if (rec.rejectionReason != null && rec.rejectionReason!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: AppColors.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Rejection Reason: ${rec.rejectionReason}',
                              style: const TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error loading work log: $e')),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.background,
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Premium Header Gradient Panel
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryContainer],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_reset, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Change Password',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Set a secure new password for your account.',
                                style: TextStyle(fontSize: 13, color: AppColors.outline),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: newPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'New Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: confirmPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm New Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please confirm your password';
                                  if (v != newPasswordController.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          if (formKey.currentState!.validate()) {
                                            setModalState(() => isLoading = true);
                                            try {
                                              final success = await ref.read(authProvider.notifier).changePassword(newPasswordController.text);
                                              if (success && context.mounted) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Password updated successfully!'),
                                                    backgroundColor: AppColors.success,
                                                  ),
                                                );
                                              } else if (context.mounted) {
                                                final err = ref.read(authProvider).errorMessage;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(err ?? 'Failed to update password.'),
                                                    backgroundColor: AppColors.error,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                                );
                                              }
                                            } finally {
                                              if (context.mounted) {
                                                setModalState(() => isLoading = false);
                                              }
                                            }
                                          }
                                        },
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('UPDATE PASSWORD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
