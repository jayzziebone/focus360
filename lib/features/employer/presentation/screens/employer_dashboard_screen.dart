import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shiftsync/core/constants/app_colors.dart';
import 'package:shiftsync/features/auth/presentation/providers/auth_provider.dart';
import 'package:shiftsync/features/notifications/presentation/widgets/notifications_bell_widget.dart';
import 'package:shiftsync/features/employer/presentation/providers/employer_provider.dart';
import 'package:shiftsync/features/employee/data/models/attendance_record_model.dart';
import 'package:shiftsync/features/auth/data/models/user_model.dart';

class EmployerDashboardScreen extends ConsumerStatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  ConsumerState<EmployerDashboardScreen> createState() => _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends ConsumerState<EmployerDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.userModel;

    final List<Widget> pages = [
      _buildOverviewTab(user?.fullName ?? 'Employer Manager'),
      _buildTodayTab(),
      _buildApprovalsTab(),
      _buildHistoryTab(),
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
            icon: Icon(Icons.dashboard_outlined, color: AppColors.secondary),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: AppColors.secondary),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined, color: AppColors.secondary),
            selectedIcon: Icon(Icons.fact_check, color: AppColors.primary),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.history, color: AppColors.secondary),
            selectedIcon: Icon(Icons.history, color: AppColors.primary),
            label: 'History',
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

  // --- TAB: OVERVIEW ---
  Widget _buildOverviewTab(String name) {
    final shiftsStream = ref.watch(employerShiftsProvider);
    final pendingStream = ref.watch(pendingApprovalsProvider);
    final historyStream = ref.watch(attendanceHistoryProvider);
    final user = ref.watch(authProvider).userModel;

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
                      'Employer Console',
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
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.business,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.1), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('On Duty Now', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.outline, fontSize: 13)),
                          const SizedBox(height: 8),
                          shiftsStream.when(
                            data: (list) {
                              final todayShifts = list.where((s) => DateUtils.isSameDay(s.startTime.toLocal(), DateTime.now().toLocal())).toList();
                              
                              final onDutyCount = historyStream.when(
                                data: (historyList) {
                                  return historyList.where((r) {
                                    final isToday = DateUtils.isSameDay(r.punchInTime.toLocal(), DateTime.now().toLocal());
                                    final isApproved = r.approvedStatus == 'approved';
                                    final isStillActive = r.punchOutTime == null;
                                    return isToday && isApproved && isStillActive;
                                  }).length;
                                },
                                loading: () => 0,
                                error: (_, __) => 0,
                              );

                              return Text(
                                '$onDutyCount / ${todayShifts.length}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              );
                            },
                            loading: () => const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (_, __) => const Text('Error', style: TextStyle(color: AppColors.error)),
                          ),
                          const SizedBox(height: 4),
                          const Text('Employees active today', style: TextStyle(fontSize: 11, color: AppColors.outline)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.pending.withOpacity(0.1), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Approvals Queue', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.outline, fontSize: 13)),
                          const SizedBox(height: 8),
                          pendingStream.when(
                            data: (list) => Text(
                              '${list.length}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppColors.pending,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            loading: () => const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (_, __) => const Text('Error', style: TextStyle(color: AppColors.error)),
                          ),
                          const SizedBox(height: 4),
                          const Text('Pending punch reviews', style: TextStyle(fontSize: 11, color: AppColors.outline)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            Text(
              'Actions Console',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.primary.withOpacity(0.1), width: 1),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.done_all, color: AppColors.primary),
                ),
                title: const Text('Review Attendance Approvals', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                subtitle: const Text('Approve or reject employee punch-ins'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.secondary),
                onTap: () => setState(() => _currentIndex = 2),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.secondary.withOpacity(0.1), width: 1),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people, color: AppColors.secondary),
                ),
                title: const Text('Roster and Operations', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                subtitle: const Text('Check active shifts and scheduled staff'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.secondary),
                onTap: () => setState(() => _currentIndex = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB: TODAY'S SHIFTS ---
  Widget _buildTodayTab() {
    final shiftsStream = ref.watch(employerShiftsProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Staff Today',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
          ),
          const SizedBox(height: 4),
          const Text('Track shifts scheduled for today', style: TextStyle(color: AppColors.outline)),
          const SizedBox(height: 24),
          Expanded(
            child: shiftsStream.when(
              data: (list) {
                final todayShifts = list.where((s) => DateUtils.isSameDay(s.startTime.toLocal(), DateTime.now().toLocal())).toList();

                if (todayShifts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: AppColors.outline.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text('No shifts scheduled for today.', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Contact the administrator to schedule staff.', style: TextStyle(fontSize: 12, color: AppColors.outline)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: todayShifts.length,
                  itemBuilder: (context, index) {
                    final shift = todayShifts[index];
                    final timeStr = '${DateFormat('hh:mm a').format(shift.startTime)} - ${DateFormat('hh:mm a').format(shift.endTime)}';

                    Color statusColor = AppColors.secondary;
                    if (shift.status == 'in_progress') {
                      statusColor = AppColors.primary;
                    } else if (shift.status == 'completed') {
                      statusColor = Colors.grey;
                    }

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: statusColor.withOpacity(0.15)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Text(
                            shift.employeeName.isNotEmpty ? shift.employeeName[0].toUpperCase() : 'S',
                            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                        title: Text(shift.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Site: ${shift.locationName}', style: const TextStyle(fontSize: 11, color: AppColors.outline)),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            shift.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error loading today\'s roster: $err')),
            ),
          )
        ],
      ),
    );
  }

  // --- TAB: APPROVALS QUEUE ---
  Widget _buildApprovalsTab() {
    final pendingStream = ref.watch(pendingApprovalsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.userModel;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approvals Queue',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
          ),
          const SizedBox(height: 4),
          const Text('Review pending attendance punches', style: TextStyle(color: AppColors.outline)),
          const SizedBox(height: 24),
          Expanded(
            child: pendingStream.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fact_check, size: 64, color: AppColors.primary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('Queue is all clear!', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('No pending attendance records need review.', style: TextStyle(fontSize: 12, color: AppColors.outline)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final record = list[index];
                    final inTimeStr = DateFormat('hh:mm a').format(record.punchInTime);
                    final formattedDate = DateFormat('EEEE, MMMM d').format(record.punchInTime);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: Text(
                                    record.employeeName.isNotEmpty ? record.employeeName[0].toUpperCase() : 'E',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(record.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary)),
                                      Text(formattedDate, style: const TextStyle(color: AppColors.outline, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Clocked In at: $inTimeStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  record.punchInVerified ? Icons.gps_fixed : Icons.gps_off,
                                  size: 14,
                                  color: record.punchInVerified ? AppColors.success : AppColors.error,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'GPS Status: ${record.punchInVerified ? "Coordinates Verified" : "Out of bounds (OOB)"}',
                                  style: TextStyle(
                                    color: record.punchInVerified ? AppColors.success : AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _showRejectDialog(context, record, user?.employerId ?? ''),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                  child: const Text('REJECT LOG', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      final repo = ref.read(employerRepositoryProvider);
                                      await repo.approveAttendance(record.id, user?.employerId ?? 'employer_generic');
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Punch record approved successfully!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Error approving: $e'), backgroundColor: AppColors.error),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('APPROVE LOG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error loading approvals queue: $err')),
            ),
          )
        ],
      ),
    );
  }

  // --- TAB: HISTORY LOGS ---
  Widget _buildHistoryTab() {
    final historyStream = ref.watch(attendanceHistoryProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance History',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
          ),
          const SizedBox(height: 4),
          const Text('Completed work shift logs & history reviews', style: TextStyle(color: AppColors.outline)),
          const SizedBox(height: 24),
          Expanded(
            child: historyStream.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: AppColors.outline.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text('No historical logs yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                // Sort history descending by punch in time
                final sortedList = List<AttendanceRecordModel>.from(list)..sort((a, b) => b.punchInTime.compareTo(a.punchInTime));

                return ListView.builder(
                  itemCount: sortedList.length,
                  itemBuilder: (context, index) {
                    final record = sortedList[index];
                    final dateStr = DateFormat('MMM d, yyyy').format(record.punchInTime);
                    final inTime = DateFormat('hh:mm a').format(record.punchInTime);
                    final outTime = record.punchOutTime != null ? DateFormat('hh:mm a').format(record.punchOutTime!) : '--';

                    Color statusColor = AppColors.pending;
                    if (record.approvedStatus == 'approved') {
                      statusColor = AppColors.success;
                    } else if (record.approvedStatus == 'rejected') {
                      statusColor = AppColors.error;
                    }

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.secondary.withOpacity(0.08)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(record.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$dateStr • worked: $inTime - $outTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'GPS Verification: In ${record.punchInVerified ? "OK" : "OOB"} • Out ${record.punchOutVerified == true ? "OK" : "OOB"}',
                              style: TextStyle(fontSize: 10, color: AppColors.outline, fontWeight: FontWeight.bold),
                            ),
                            if (record.rejectionReason != null) ...[
                              const SizedBox(height: 4),
                              Text('Rejection Reason: ${record.rejectionReason}', style: const TextStyle(color: AppColors.error, fontSize: 11)),
                            ],
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            record.approvedStatus.toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error loading history: $err')),
            ),
          )
        ],
      ),
    );
  }

  // --- TAB: PROFILE ---
  Widget _buildProfileTab() {
    final authState = ref.watch(authProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.business, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.userModel?.fullName ?? 'Employer Account',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.secondary),
                          ),
                          const SizedBox(height: 4),
                          Text(authState.userModel?.email ?? '', style: const TextStyle(color: AppColors.outline)),
                          const SizedBox(height: 4),
                          Text(
                            'Employer ID: ${authState.userModel?.employerId ?? "N/A"}',
                            style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.secondary.withOpacity(0.1)),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Organization Settings'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('Notification Preferences'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================
  // === ACTION WIDGETS & DIALOGS ===
  // ============================================

  // Dialog: Prompt Employer for Rejection Reason (Mandatory)
  void _showRejectDialog(BuildContext context, AttendanceRecordModel record, String employerId) {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    bool isLoading = false;
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Reject Attendance Punch',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provide a mandatory reason for rejecting ${record.employeeName}\'s punch record.',
                      style: const TextStyle(fontSize: 13, color: AppColors.outline),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Rejection Reason',
                        hintText: 'e.g. Out of bounds, late punch, etc.',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Rejection reason is required' : null,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isLoading = true);
                            try {
                              final repo = ref.read(employerRepositoryProvider);
                              await repo.rejectAttendance(
                                record.id,
                                employerId,
                                reasonController.text.trim(),
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Attendance punch for ${record.employeeName} rejected.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                              );
                              setDialogState(() => isLoading = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('REJECT LOG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
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
