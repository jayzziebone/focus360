import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shiftsync/core/constants/app_colors.dart';
import 'package:shiftsync/features/auth/data/models/user_model.dart';
import 'package:shiftsync/features/admin/presentation/providers/admin_provider.dart';
import 'package:shiftsync/features/admin/data/models/location_model.dart';
import 'package:shiftsync/features/employee/data/models/attendance_record_model.dart';
import 'package:shiftsync/features/employee/data/models/shift_model.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final UserModel employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  ConsumerState<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  late UserModel _currentEmployee;

  @override
  void initState() {
    super.initState();
    _currentEmployee = widget.employee;
  }

  @override
  Widget build(BuildContext context) {
    final employersAsync = ref.watch(adminEmployersProvider);
    final attendanceAsync = ref.watch(adminAttendanceProvider);
    final shiftsAsync = ref.watch(adminShiftsProvider);
    final locationsAsync = ref.watch(adminLocationsProvider);

    // Dynamic reactive sync with active user updates in background
    final employeesList = ref.watch(adminEmployeesProvider).value ?? [];
    final matchedEmployee = employeesList.where((e) => e.uid == _currentEmployee.uid).toList();
    if (matchedEmployee.isNotEmpty) {
      _currentEmployee = matchedEmployee.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Staff Portfolio',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.secondary),
        actions: [
          employersAsync.when(
            data: (employers) => IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => _showEditEmployeeDialog(context, _currentEmployee, employers),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek Gradient Profile Header Card
              _buildProfileHeaderCard(),
              const SizedBox(height: 24),

              // 2. Real-time Computed Hours & Billing Metrics
              Text(
                'Work Hours & Analytics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
              const SizedBox(height: 12),
              _buildMetricsSummary(attendanceAsync),
              const SizedBox(height: 28),

              // 3. Assigned Primary Employer
              Text(
                'Corporate Assignment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
              const SizedBox(height: 12),
              _buildEmployerAssignment(employersAsync, shiftsAsync),
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
                      final count = recs.where((r) => r.employeeId == _currentEmployee.employeeId).length;
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
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAttendanceLogsList(attendanceAsync, shiftsAsync, locationsAsync),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: Profile Header Card ---
  Widget _buildProfileHeaderCard() {
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
              backgroundColor: _currentEmployee.isActive
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              child: Text(
                _currentEmployee.fullName.isNotEmpty ? _currentEmployee.fullName[0].toUpperCase() : 'E',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _currentEmployee.isActive ? AppColors.primary : Colors.grey,
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
                          _currentEmployee.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentEmployee.isActive
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentEmployee.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _currentEmployee.isActive ? AppColors.primary : Colors.red,
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
                          _currentEmployee.email,
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
                          'ID: ${_currentEmployee.employeeId ?? "None Assigned"}',
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
  Widget _buildMetricsSummary(AsyncValue<List<AttendanceRecordModel>> attendanceAsync) {
    return attendanceAsync.when(
      data: (records) {
        final employeeRecords = records.where((r) => r.employeeId == _currentEmployee.employeeId).toList();
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
        final approvedTotal = employeeRecords.where((r) => r.approvedStatus == 'approved').length;
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
                        '${pendingTotal} pending approvals',
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
  Widget _buildEmployerAssignment(
    AsyncValue<List<UserModel>> employersAsync,
    AsyncValue<List<ShiftModel>> shiftsAsync,
  ) {
    return employersAsync.when(
      data: (employers) {
        return shiftsAsync.when(
          data: (shifts) {
            final now = DateTime.now();
            final todayShifts = shifts.where((s) =>
                s.employeeId == _currentEmployee.employeeId &&
                s.startTime.year == now.year &&
                s.startTime.month == now.month &&
                s.startTime.day == now.day
            ).toList();

            if (todayShifts.length > 1) {
              todayShifts.sort((a, b) {
                int score(ShiftModel s) {
                  if (s.status == 'in_progress') return 3;
                  if (s.status == 'scheduled') return 2;
                  if (s.status == 'completed') return 1;
                  return 0;
                }
                return score(b).compareTo(score(a));
              });
            }

            final String? employerId;
            final bool isTodayAssignment;
            if (todayShifts.isNotEmpty) {
              employerId = todayShifts.first.employerId;
              isTodayAssignment = true;
            } else {
              employerId = _currentEmployee.employerId;
              isTodayAssignment = false;
            }

            final matchedList = employers.where((emp) => emp.employerId == employerId).toList();

            if (matchedList.isEmpty || employerId == null) {
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.tertiary.withOpacity(0.15)),
                ),
                child: const ListTile(
                  leading: Icon(Icons.business, color: Colors.grey),
                  title: Text('No Organization Assigned', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  subtitle: Text('Employee is currently unassigned to any firm.'),
                ),
              );
            }

            final employer = matchedList.first;
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
                title: Row(
                  children: [
                    Expanded(
                      child: Text(employer.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTodayAssignment ? AppColors.success.withOpacity(0.15) : AppColors.outline.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isTodayAssignment ? 'TODAY\'S SHIFT' : 'PRIMARY ASSIGNMENT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isTodayAssignment ? AppColors.success : AppColors.outline,
                        ),
                      ),
                    ),
                  ],
                ),
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
          error: (e, _) => Center(child: Text('Error loading shifts: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tertiary)),
      error: (e, _) => Center(child: Text('Error loading assignment: $e')),
    );
  }

  // --- WIDGET: Attendance Logs History List ---
  Widget _buildAttendanceLogsList(
    AsyncValue<List<AttendanceRecordModel>> attendanceAsync,
    AsyncValue<List<ShiftModel>> shiftsAsync,
    AsyncValue<List<LocationModel>> locationsAsync,
  ) {
    return attendanceAsync.when(
      data: (attendanceList) {
        final records = attendanceList.where((r) => r.employeeId == _currentEmployee.employeeId).toList();

        if (records.isEmpty) {
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
        final sortedRecords = List<AttendanceRecordModel>.from(records)
          ..sort((a, b) => b.punchInTime.compareTo(a.punchInTime));

        final locations = locationsAsync.value ?? [];

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

            final matchedLoc = locations.where((l) => l.id == rec.shiftId).toList();
            // Fallback lookup or generic location details
            final locationText = rec.punchInVerified ? 'Geofenced radius target' : 'Out of bounds GPS location';

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

  // --- ACTION DIALOG: Edit Employee Info ---
  void _showEditEmployeeDialog(BuildContext context, UserModel employee, List<UserModel> employers) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: employee.fullName);
    final emailController = TextEditingController(text: employee.email);
    String? selectedEmployerId = employee.employerId;
    bool isActive = employee.isActive;
    bool isSaving = false;

    // Check if employee's current employerId is in the list of employers
    final hasEmployer = employers.any((e) => e.employerId == selectedEmployerId);
    if (!hasEmployer && employers.isNotEmpty && selectedEmployerId != null) {
      selectedEmployerId = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.background,
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
                            const Icon(Icons.manage_accounts, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Edit Staff Profile',
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
                              TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Employee Full Name',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!RegExp(r'^[\w-\.\+]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: selectedEmployerId,
                                decoration: const InputDecoration(
                                  labelText: 'Assigned Employer Org',
                                  prefixIcon: Icon(Icons.business),
                                ),
                                hint: const Text('Unassigned'),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Unassigned / Independent'),
                                  ),
                                  ...employers.map((emp) {
                                    return DropdownMenuItem<String>(
                                      value: emp.employerId,
                                      child: Text(emp.fullName),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setModalState(() {
                                    selectedEmployerId = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                value: isActive,
                                title: const Text('Account Status Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                subtitle: const Text('Toggle employee authorization access'),
                                activeColor: AppColors.primary,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) {
                                  setModalState(() {
                                    isActive = val;
                                  });
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
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          if (formKey.currentState!.validate()) {
                                            setModalState(() => isSaving = true);
                                            try {
                                              final updated = employee.copyWith(
                                                fullName: nameController.text.trim(),
                                                email: emailController.text.trim(),
                                                employerId: selectedEmployerId,
                                                isActive: isActive,
                                                updatedAt: DateTime.now(),
                                              );

                                              final adminRepo = ref.read(adminRepositoryProvider);
                                              await adminRepo.updateUserProfile(updated);

                                              if (mounted) {
                                                setState(() {
                                                  _currentEmployee = updated;
                                                });
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Staff details updated successfully!'),
                                                    backgroundColor: AppColors.success,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                              );
                                            } finally {
                                              setModalState(() => isSaving = false);
                                            }
                                          }
                                        },
                                  child: isSaving
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text('SAVE PROFILE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
