import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shiftsync/core/constants/app_colors.dart';
import 'package:shiftsync/features/auth/presentation/providers/auth_provider.dart';
import 'package:shiftsync/features/notifications/presentation/widgets/notifications_bell_widget.dart';
import 'package:shiftsync/features/auth/data/models/user_model.dart';
import 'package:shiftsync/features/admin/presentation/providers/admin_provider.dart';
import 'package:shiftsync/features/admin/data/models/location_model.dart';
import 'package:shiftsync/features/employee/data/models/shift_model.dart';
import 'package:shiftsync/features/employee/data/models/attendance_record_model.dart';
import 'package:shiftsync/features/admin/presentation/screens/employee_detail_screen.dart';
import 'package:shiftsync/features/admin/presentation/screens/onboard_employer_screen.dart';
import 'package:shiftsync/features/admin/presentation/screens/edit_employer_screen.dart';
import 'package:shiftsync/features/admin/presentation/screens/onboard_employee_screen.dart';
import 'package:shiftsync/features/admin/presentation/screens/admin_schedules_archive_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.userModel;

    final List<Widget> pages = [
      _buildOverviewTab(user?.fullName ?? 'Administrator'),
      _buildEmployersTab(),
      _buildEmployeesTab(),
      _buildSchedulesTab(),
      _buildSettingsTab(),
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
            icon: Icon(Icons.admin_panel_settings_outlined, color: AppColors.secondary),
            selectedIcon: Icon(Icons.admin_panel_settings, color: AppColors.primary),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined, color: AppColors.secondary),
            selectedIcon: Icon(Icons.business, color: AppColors.primary),
            label: 'Employers',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: AppColors.secondary),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Employees',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined, color: AppColors.secondary),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
            label: 'Schedules',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: AppColors.secondary),
            selectedIcon: Icon(Icons.settings, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // --- TAB: OVERVIEW ---
  Widget _buildOverviewTab(String name) {
    final employersStream = ref.watch(adminEmployersProvider);
    final employeesStream = ref.watch(adminEmployeesProvider);
    final locationsStream = ref.watch(adminLocationsProvider);
    final shiftsStream = ref.watch(adminShiftsProvider);
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
                      'Global System Console',
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
                        Icons.security,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Live Metrics Row
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
                          const Text(
                            'Employers',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.outline, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          employersStream.when(
                            data: (list) => Text(
                              '${list.length}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            loading: () => const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            error: (_, __) => const Text('Error', style: TextStyle(color: AppColors.error)),
                          ),
                          const SizedBox(height: 4),
                          const Text('Managed organizations', style: TextStyle(fontSize: 11, color: AppColors.outline)),
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
                      side: BorderSide(color: AppColors.tertiary.withOpacity(0.1), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Employees',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.outline, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          employeesStream.when(
                            data: (list) => Text(
                              '${list.length}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppColors.tertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            loading: () => const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.tertiary),
                            ),
                            error: (_, __) => const Text('Error', style: TextStyle(color: AppColors.error)),
                          ),
                          const SizedBox(height: 4),
                          const Text('Active system users', style: TextStyle(fontSize: 11, color: AppColors.outline)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Additional stats info
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.amber.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.pin_drop, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                locationsStream.when(
                                  data: (list) => Text(
                                    '${list.length} Locations',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  loading: () => const Text('...', style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  error: (_, __) => const Text('Error', maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                const Text(
                                  'GPS Geofenced Locations',
                                  style: TextStyle(fontSize: 11, color: AppColors.outline),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                shiftsStream.when(
                                  data: (list) => Text(
                                    '${list.length} Shifts',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  loading: () => const Text('...', style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  error: (_, __) => const Text('Error', maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                const Text(
                                  'Scheduled Shifts',
                                  style: TextStyle(fontSize: 11, color: AppColors.outline),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Text(
              'System Domains',
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
                  child: const Icon(Icons.business, color: AppColors.primary),
                ),
                title: const Text('Manage Organizations & Employers', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                subtitle: const Text('Create, edit, or configure employers'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.secondary),
                onTap: () => setState(() => _currentIndex = 1),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.tertiary.withOpacity(0.1), width: 1),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people, color: AppColors.tertiary),
                ),
                title: const Text('Manage Employees & Staff', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                subtitle: const Text('Assign employees and roles'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.secondary),
                onTap: () => setState(() => _currentIndex = 2),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.amber.withOpacity(0.1), width: 1),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.amber),
                ),
                title: const Text('Global Shifts & Roster Maker', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                subtitle: const Text('Create and publish employee schedules'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.secondary),
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB: EMPLOYERS ---
  Widget _buildEmployersTab() {
    final employersStream = ref.watch(adminEmployersProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Employers',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 36),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OnboardEmployerScreen())),
              )
            ],
          ),
          const SizedBox(height: 4),
          const Text('Manage corporate employer profiles', style: TextStyle(color: AppColors.outline)),
          const SizedBox(height: 24),
          Expanded(
            child: employersStream.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business, size: 64, color: AppColors.outline.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('No employers registered yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OnboardEmployerScreen())),
                          child: const Text('Add Employer Now'),
                        )
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final employer = list[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditEmployerScreen(employer: employer))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(employer.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(employer.email, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('ID: ${employer.employerId ?? "N/A"}', style: TextStyle(fontSize: 10, color: AppColors.outline, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Employer', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error loading employers: $err', style: const TextStyle(color: AppColors.error))),
            ),
          )
        ],
      ),
    );
  }

  // --- TAB: EMPLOYEES ---
  Widget _buildEmployeesTab() {
    final employeesStream = ref.watch(adminEmployeesProvider);
    final employersStream = ref.watch(adminEmployersProvider);
    final shiftsStream = ref.watch(adminShiftsProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Employees',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
              ),
              employersStream.when(
                data: (employersList) => IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.tertiary, size: 36),
                  onPressed: () {
                    if (employersList.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please register at least one Employer before onboarding Employees.')),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OnboardEmployeeScreen(employers: employersList),
                        ),
                      );
                    }
                  },
                ),
                loading: () => const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('View and onboard system employees', style: TextStyle(color: AppColors.outline)),
          const SizedBox(height: 24),
          Expanded(
            child: employeesStream.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 64, color: AppColors.outline.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('No employees onboarded yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        employersStream.when(
                          data: (employersList) => employersList.isNotEmpty
                              ? TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OnboardEmployeeScreen(employers: employersList),
                                    ),
                                  ),
                                  child: const Text('Onboard Employee Now'),
                                )
                              : const Text('Add an employer first.', style: TextStyle(color: AppColors.outline)),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final employee = list[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.tertiary.withOpacity(0.1)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmployeeDetailScreen(employee: employee),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.tertiary.withOpacity(0.1),
                          child: Text(
                            employee.fullName.isNotEmpty ? employee.fullName[0].toUpperCase() : 'E',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tertiary),
                          ),
                        ),
                        title: Text(employee.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(employee.email, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                final employersList = employersStream.value ?? [];
                                final shiftsList = shiftsStream.value ?? [];
                                final now = DateTime.now();
                                final todayShifts = shiftsList.where((s) =>
                                    s.employeeId == employee.employeeId &&
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
                                  employerId = employee.employerId;
                                  isTodayAssignment = false;
                                }

                                final matchingEmployer = employersList.firstWhere(
                                  (emp) => emp.employerId == employerId,
                                  orElse: () => UserModel(
                                    uid: '',
                                    email: '',
                                    fullName: employerId ?? 'None Assigned',
                                    role: UserRole.employer,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                    isActive: true,
                                  ),
                                );
                                return Text(
                                  isTodayAssignment
                                      ? 'Employer Org: ${matchingEmployer.fullName} (Today\'s Shift)'
                                      : 'Employer Org: ${matchingEmployer.fullName}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isTodayAssignment ? AppColors.success : AppColors.outline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Staff', style: TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tertiary)),
              error: (err, _) => Center(child: Text('Error loading employees: $err', style: const TextStyle(color: AppColors.error))),
            ),
          )
        ],
      ),
    );
  }

  // --- TAB: SCHEDULES / SHIFTS & LOCATIONS ---
  Widget _buildSchedulesTab() {
    final shiftsStream = ref.watch(adminShiftsProvider);
    final locationsStream = ref.watch(adminLocationsProvider);
    final employersStream = ref.watch(adminEmployersProvider);
    final employeesStream = ref.watch(adminEmployeesProvider);
    final attendanceStream = ref.watch(adminAttendanceProvider);

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Schedules & Sites',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                ),
                // Pop-up menu or combo button for options
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.archive_outlined, color: AppColors.primary, size: 28),
                      tooltip: 'View Schedules Archive',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminSchedulesArchiveScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.add_circle, color: Colors.amber, size: 36),
                      onSelected: (value) {
                        if (value == 'shift') {
                          employeesStream.whenData((employees) {
                            locationsStream.whenData((locations) {
                              if (employees.isEmpty || locations.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please onboard both Employees and Locations before scheduling shifts.')),
                                );
                              } else {
                                _showCreateShiftSheet(context, employees, locations);
                              }
                            });
                          });
                        } else if (value == 'location') {
                          employersStream.whenData((employers) {
                            if (employers.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please onboard an Employer before adding geofenced locations.')),
                              );
                            } else {
                              _showAddLocationSheet(context, employers);
                            }
                          });
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'shift',
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Create Shift Schedule'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'location',
                          child: Row(
                            children: [
                              Icon(Icons.pin_drop, color: Colors.amber),
                              SizedBox(width: 8),
                              Text('Add Work Location'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.outline,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Shifts Roster'),
                Tab(text: 'Workplace Locations'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab Content: Shifts List
                  shiftsStream.when(
                    data: (list) {
                      final attendanceList = attendanceStream.value ?? [];

                      // Filter out completed and missed shifts for active Roster view
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
                            return false; // completed shifts are archived
                          }
                          return true; // in progress shift is active
                        } else {
                          if (shift.endTime.isBefore(DateTime.now())) {
                            return false; // missed shifts are archived
                          }
                          return true; // scheduled active shift
                        }
                      }).toList();

                      if (activeList.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month, size: 64, color: AppColors.outline.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              const Text('No active shifts rostered.', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('Tap the "+" icon above to create schedules.', style: TextStyle(fontSize: 12, color: AppColors.outline)),
                            ],
                          ),
                        );
                      }
                      // Sort shifts chronologically by start time descending
                      final sortedList = List<ShiftModel>.from(activeList)..sort((a, b) => b.startTime.compareTo(a.startTime));

                      return ListView.builder(
                        itemCount: sortedList.length,
                        itemBuilder: (context, index) {
                          final shift = sortedList[index];
                          final dateFormat = DateFormat('EEE, MMM d, y');
                          final timeFormat = DateFormat('hh:mm a');
                          final dateTimeFormat = DateFormat('MMM d • hh:mm a');
                          final matchingAttendance = attendanceList.where((r) => r.shiftId == shift.id).toList();
                          final AttendanceRecordModel? attendance = matchingAttendance.isNotEmpty ? matchingAttendance.first : null;

                          // Compute dynamic status and color based on live attendance clocks (SCHEDULED, IN PROGRESS, MISSED, COMPLETED)
                          String displayStatus = 'SCHEDULED';
                          Color displayColor = AppColors.tertiary;

                          if (attendance != null) {
                            if (attendance.punchInTime != null && attendance.punchOutTime != null) {
                              displayStatus = 'COMPLETED';
                              displayColor = AppColors.success;
                            } else if (attendance.punchInTime != null && attendance.punchOutTime == null) {
                              displayStatus = 'IN PROGRESS';
                              displayColor = AppColors.primary;
                            }
                          } else {
                            if (shift.endTime.isBefore(DateTime.now())) {
                              displayStatus = 'MISSED';
                              displayColor = AppColors.error;
                            }
                          }

                          final String formattedIn = attendance != null ? dateTimeFormat.format(attendance.punchInTime) : '--:--';
                          final String formattedOut = (attendance != null && attendance.punchOutTime != null) ? dateTimeFormat.format(attendance.punchOutTime!) : '--:--';

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.amber.withOpacity(0.15)),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          shift.employeeName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: displayColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              displayStatus,
                                              style: TextStyle(color: displayColor, fontWeight: FontWeight.bold, fontSize: 11),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                                            onPressed: () {
                                              employeesStream.whenData((employees) {
                                                locationsStream.whenData((locations) {
                                                  _showEditShiftDialog(context, shift, employees, locations);
                                                });
                                              });
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.pin_drop, size: 16, color: AppColors.outline),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          shift.locationName,
                                          style: const TextStyle(color: AppColors.outline, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.date_range, size: 16, color: AppColors.outline),
                                      const SizedBox(width: 4),
                                      Text(
                                        dateFormat.format(shift.startTime),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.schedule, size: 16, color: AppColors.outline),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${timeFormat.format(shift.startTime)} - ${timeFormat.format(shift.endTime)}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 8,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            'CLOCKED IN at: $formattedIn',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: attendance != null ? AppColors.success : AppColors.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.logout_outlined, size: 16, color: AppColors.secondary),
                                          const SizedBox(width: 6),
                                          Text(
                                            'CLOCKED OUT at: $formattedOut',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: (attendance != null && attendance.punchOutTime != null) ? AppColors.secondary : AppColors.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
                    error: (err, _) => Center(child: Text('Error loading shifts: $err', style: const TextStyle(color: AppColors.error))),
                  ),

                  // Tab Content: Locations List
                  locationsStream.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pin_drop, size: 64, color: Colors.amber.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              const Text('No locations added yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('Tap the "+" icon above to add locations.', style: TextStyle(fontSize: 12, color: AppColors.outline)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final loc = list[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.amber.withOpacity(0.2)),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () {
                                final employersList = employersStream.value ?? [];
                                _showEditLocationDialog(context, loc, employersList);
                              },
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(loc.address, style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'GPS: (${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}) • Radius: ${loc.radiusMeters}m',
                                    style: TextStyle(fontSize: 10, color: AppColors.outline, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.amber),
                                    tooltip: 'Modify Location',
                                    onPressed: () {
                                      final employersList = employersStream.value ?? [];
                                      _showEditLocationDialog(context, loc, employersList);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                    tooltip: 'Delete Location',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Workplace Location?'),
                                          content: const Text('Are you sure you want to permanently delete this workplace location? This cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('CANCEL'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        try {
                                          final adminRepo = ref.read(adminRepositoryProvider);
                                          await adminRepo.deleteLocation(loc.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Workplace location deleted successfully.'),
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
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
                    error: (err, _) => Center(child: Text('Error loading locations: $err', style: const TextStyle(color: AppColors.error))),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- TAB: SETTINGS ---
  Widget _buildSettingsTab() {
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
                  'Settings',
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
                side: BorderSide(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.cloud_sync, color: AppColors.primary),
                    title: Text('Firebase Integration Status', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Active and Online'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.security, color: AppColors.tertiary),
                    title: Text('Role Security Policies', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Enforced in Firestore Rules'),
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

  // ============================================
  // === ONBOARDING DIALOGS (CRUD) ===
  // ============================================

  // Sheet 3: Add Workplace Location
  void _showAddLocationSheet(BuildContext context, List<UserModel> employers) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final radiusController = TextEditingController(text: '100');
    String? selectedEmployerId = employers.first.employerId;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Geofenced Location',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Location/Workplace Name',
                          prefixIcon: Icon(Icons.place),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Location name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Street Address',
                          prefixIcon: Icon(Icons.map),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: latController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                hintText: 'e.g. 40.7128',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (double.tryParse(v) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: lngController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                hintText: 'e.g. -74.0060',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (double.tryParse(v) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: radiusController,
                        decoration: const InputDecoration(
                          labelText: 'Geofence Radius (meters)',
                          prefixIcon: Icon(Icons.radar),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Radius is required';
                          final val = int.tryParse(v);
                          if (val == null || val <= 0) return 'Must be positive integer';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedEmployerId,
                        decoration: const InputDecoration(
                          labelText: 'Assign to Employer Org',
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: employers.map((emp) {
                          return DropdownMenuItem<String>(
                            value: emp.employerId,
                            child: Text(emp.fullName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedEmployerId = value;
                          });
                        },
                        validator: (v) => v == null ? 'Please assign an employer' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    setModalState(() => isLoading = true);
                                    try {
                                      final loc = LocationModel(
                                        id: '',
                                        name: nameController.text.trim(),
                                        address: addressController.text.trim(),
                                        latitude: double.parse(latController.text),
                                        longitude: double.parse(lngController.text),
                                        radiusMeters: int.parse(radiusController.text),
                                        employerId: selectedEmployerId!,
                                      );

                                      final adminRepo = ref.read(adminRepositoryProvider);
                                      await adminRepo.addLocation(loc);

                                      if (mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Added location "${nameController.text}" successfully!'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                      );
                                    } finally {
                                      setModalState(() => isLoading = false);
                                    }
                                  }
                                },
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('ADD LOCATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

   // Dialog 3b: Edit Workplace Location
  void _showEditLocationDialog(BuildContext context, LocationModel location, List<UserModel> employers) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: location.name);
    final addressController = TextEditingController(text: location.address);
    final latController = TextEditingController(text: location.latitude.toString());
    final lngController = TextEditingController(text: location.longitude.toString());
    final radiusController = TextEditingController(text: location.radiusMeters.toString());
    final MapController mapController = MapController();
    String? selectedEmployerId = employers.any((e) => e.employerId == location.employerId)
        ? location.employerId
        : (employers.isNotEmpty ? employers.first.employerId : null);
    bool isLoading = false;

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
                final double currentLat = double.tryParse(latController.text) ?? location.latitude;
                final double currentLng = double.tryParse(lngController.text) ?? location.longitude;
                final double currentRadius = double.tryParse(radiusController.text) ?? location.radiusMeters.toDouble();

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
                            colors: [Colors.amber, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_location_alt, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Edit Geofenced Location',
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
                                  labelText: 'Location/Workplace Name',
                                  prefixIcon: Icon(Icons.place),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Location name is required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: addressController,
                                decoration: const InputDecoration(
                                  labelText: 'Street Address',
                                  prefixIcon: Icon(Icons.map),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: latController,
                                      decoration: const InputDecoration(
                                        labelText: 'Latitude',
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (val) {
                                        final lat = double.tryParse(latController.text);
                                        final lng = double.tryParse(lngController.text);
                                        if (lat != null && lng != null) {
                                          mapController.move(LatLng(lat, lng), mapController.camera.zoom);
                                        }
                                        setModalState(() {});
                                      },
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Required';
                                        if (double.tryParse(v) == null) return 'Invalid';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: lngController,
                                      decoration: const InputDecoration(
                                        labelText: 'Longitude',
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (val) {
                                        final lat = double.tryParse(latController.text);
                                        final lng = double.tryParse(lngController.text);
                                        if (lat != null && lng != null) {
                                          mapController.move(LatLng(lat, lng), mapController.camera.zoom);
                                        }
                                        setModalState(() {});
                                      },
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Required';
                                        if (double.tryParse(v) == null) return 'Invalid';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: radiusController,
                                decoration: const InputDecoration(
                                  labelText: 'Geofence Radius (meters)',
                                  prefixIcon: Icon(Icons.radar),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setModalState(() {});
                                },
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Radius is required';
                                  final val = int.tryParse(v);
                                  if (val == null || val <= 0) return 'Must be positive';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              if (employers.isNotEmpty) DropdownButtonFormField<String>(
                                value: selectedEmployerId,
                                decoration: const InputDecoration(
                                  labelText: 'Assign to Employer Org',
                                  prefixIcon: Icon(Icons.business),
                                ),
                                items: employers.map((emp) {
                                  return DropdownMenuItem<String>(
                                    value: emp.employerId,
                                    child: Text(emp.fullName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setModalState(() {
                                    selectedEmployerId = value;
                                  });
                                },
                                validator: (v) => v == null ? 'Please assign an employer' : null,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tap map to update coordinates geofence pinpoint:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.outline),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.withOpacity(0.25)),
                                  ),
                                  child: FlutterMap(
                                    mapController: mapController,
                                    options: MapOptions(
                                      initialCenter: LatLng(currentLat, currentLng),
                                      initialZoom: 14.0,
                                      maxZoom: 18.0,
                                      minZoom: 2.0,
                                      onTap: (tapPosition, point) {
                                        setModalState(() {
                                          latController.text = point.latitude.toStringAsFixed(6);
                                          lngController.text = point.longitude.toStringAsFixed(6);
                                        });
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.focus360.app',
                                      ),
                                      CircleLayer(
                                        circles: [
                                          CircleMarker(
                                            point: LatLng(currentLat, currentLng),
                                            color: Colors.amber.withOpacity(0.15),
                                            borderStrokeWidth: 2,
                                            borderColor: Colors.amber,
                                            useRadiusInMeter: true,
                                            radius: currentRadius,
                                          ),
                                        ],
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(currentLat, currentLng),
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
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Delete Workplace Location?'),
                                                  content: const Text('Are you sure you want to permanently delete this workplace location? This cannot be undone.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('CANCEL'),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                                      onPressed: () => Navigator.pop(context, true),
                                                      child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                setModalState(() => isLoading = true);
                                                try {
                                                  final adminRepo = ref.read(adminRepositoryProvider);
                                                  await adminRepo.deleteLocation(location.id);
                                                  if (mounted) {
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Workplace location deleted successfully.'),
                                                        backgroundColor: AppColors.error,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                                  );
                                                } finally {
                                                  setModalState(() => isLoading = false);
                                                }
                                              }
                                            },
                                      child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              if (formKey.currentState!.validate()) {
                                                setModalState(() => isLoading = true);
                                                try {
                                                  final updatedLoc = LocationModel(
                                                    id: location.id,
                                                    name: nameController.text.trim(),
                                                    address: addressController.text.trim(),
                                                    latitude: double.parse(latController.text),
                                                    longitude: double.parse(lngController.text),
                                                    radiusMeters: int.parse(radiusController.text),
                                                    employerId: selectedEmployerId ?? location.employerId,
                                                  );

                                                  final adminRepo = ref.read(adminRepositoryProvider);
                                                  await adminRepo.updateLocation(updatedLoc);

                                                  if (mounted) {
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Updated location "${nameController.text}" successfully!'),
                                                        backgroundColor: AppColors.success,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error updating location: $e'), backgroundColor: AppColors.error),
                                                  );
                                                } finally {
                                                  setModalState(() => isLoading = false);
                                                }
                                              }
                                            },
                                      child: isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                                ],
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

  // Sheet 4: Create Shift
  void _showCreateShiftSheet(BuildContext context, List<UserModel> employees, List<LocationModel> locations) {
    final formKey = GlobalKey<FormState>();
    UserModel selectedEmployee = employees.first;
    LocationModel selectedLocation = locations.first;
    DateTime startDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dateFormat = DateFormat('EEE, MMM d, yyyy');
            final formattedDate = dateFormat.format(startDate);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Schedule Work Shift',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Select Employee
                      DropdownButtonFormField<UserModel>(
                        value: selectedEmployee,
                        decoration: const InputDecoration(
                          labelText: 'Select Employee Staff',
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: employees.map((emp) {
                          return DropdownMenuItem<UserModel>(
                            value: emp,
                            child: Text(emp.fullName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedEmployee = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Select Location
                      DropdownButtonFormField<LocationModel>(
                        value: selectedLocation,
                        decoration: const InputDecoration(
                          labelText: 'Select Location/Site',
                          prefixIcon: Icon(Icons.place),
                        ),
                        items: locations.map((loc) {
                          return DropdownMenuItem<LocationModel>(
                            value: loc,
                            child: Text(loc.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedLocation = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Pick Shift Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setModalState(() {
                              startDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Shift Date',
                            prefixIcon: Icon(Icons.calendar_month),
                          ),
                          child: Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Select Start & End Times
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: startTime,
                                );
                                if (time != null) {
                                  setModalState(() {
                                    startTime = time;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Time',
                                ),
                                child: Text(
                                  startTime.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: endTime,
                                );
                                if (time != null) {
                                  setModalState(() {
                                    endTime = time;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Time',
                                ),
                                child: Text(
                                  endTime.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setModalState(() => isLoading = true);
                                  try {
                                    final startDT = DateTime(
                                      startDate.year,
                                      startDate.month,
                                      startDate.day,
                                      startTime.hour,
                                      startTime.minute,
                                    );
                                    final endDT = DateTime(
                                      startDate.year,
                                      startDate.month,
                                      startDate.day,
                                      endTime.hour,
                                      endTime.minute,
                                    );

                                    // Form validation check
                                    if (endDT.isBefore(startDT)) {
                                      throw Exception('Shift end time cannot be before start time.');
                                    }

                                    final shift = ShiftModel(
                                      id: '',
                                      employeeId: selectedEmployee.employeeId ?? '',
                                      employeeName: selectedEmployee.fullName,
                                      employerId: selectedLocation.employerId,
                                      locationId: selectedLocation.id,
                                      locationName: selectedLocation.name,
                                      startTime: startDT,
                                      endTime: endDT,
                                      status: 'scheduled',
                                      createdAt: DateTime.now(),
                                    );

                                    final adminRepo = ref.read(adminRepositoryProvider);
                                    await adminRepo.createShift(shift);

                                    if (selectedEmployee.employerId != selectedLocation.employerId) {
                                      final updatedEmployee = selectedEmployee.copyWith(
                                        employerId: selectedLocation.employerId,
                                        updatedAt: DateTime.now(),
                                      );
                                      await adminRepo.updateUserProfile(updatedEmployee);
                                    }

                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Shift created and published successfully!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                    );
                                  } finally {
                                    setModalState(() => isLoading = false);
                                  }
                                },
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('PUBLISH SHIFT', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Dialog 4b: Edit / Modify Shift Schedule
  void _showEditShiftDialog(
    BuildContext context,
    ShiftModel shift,
    List<UserModel> employees,
    List<LocationModel> locations,
  ) {
    final formKey = GlobalKey<FormState>();
    UserModel selectedEmployee = employees.firstWhere(
      (emp) => emp.employeeId == shift.employeeId,
      orElse: () => employees.first,
    );
    LocationModel selectedLocation = locations.firstWhere(
      (loc) => loc.id == shift.locationId,
      orElse: () => locations.first,
    );
    DateTime startDate = shift.startTime;
    TimeOfDay startTime = TimeOfDay(hour: shift.startTime.hour, minute: shift.startTime.minute);
    TimeOfDay endTime = TimeOfDay(hour: shift.endTime.hour, minute: shift.endTime.minute);
    bool isLoading = false;

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
                final dateFormat = DateFormat('EEE, MMM d, yyyy');
                final formattedDate = dateFormat.format(startDate);

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                            const Icon(Icons.edit_calendar, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Modify Shift Schedule',
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
                              DropdownButtonFormField<UserModel>(
                                value: selectedEmployee,
                                decoration: const InputDecoration(
                                  labelText: 'Select Employee Staff',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                items: employees.map((emp) {
                                  return DropdownMenuItem<UserModel>(
                                    value: emp,
                                    child: Text(emp.fullName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setModalState(() {
                                      selectedEmployee = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<LocationModel>(
                                value: selectedLocation,
                                decoration: const InputDecoration(
                                  labelText: 'Select Location/Site',
                                  prefixIcon: Icon(Icons.place),
                                ),
                                items: locations.map((loc) {
                                  return DropdownMenuItem<LocationModel>(
                                    value: loc,
                                    child: Text(loc.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setModalState(() {
                                      selectedLocation = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime.now().subtract(const Duration(days: 90)),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setModalState(() {
                                      startDate = date;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Shift Date',
                                    prefixIcon: Icon(Icons.calendar_month),
                                  ),
                                  child: Text(
                                    formattedDate,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: startTime,
                                        );
                                        if (time != null) {
                                          setModalState(() {
                                            startTime = time;
                                          });
                                        }
                                      },
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Start Time',
                                        ),
                                        child: Text(
                                          startTime.format(context),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: endTime,
                                        );
                                        if (time != null) {
                                          setModalState(() {
                                            endTime = time;
                                          });
                                        }
                                      },
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'End Time',
                                        ),
                                        child: Text(
                                          endTime.format(context),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Delete Shift Schedule?'),
                                                  content: const Text('Are you sure you want to permanently delete this scheduled shift? This cannot be undone.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('CANCEL'),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                                      onPressed: () => Navigator.pop(context, true),
                                                      child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                setModalState(() => isLoading = true);
                                                try {
                                                  final adminRepo = ref.read(adminRepositoryProvider);
                                                  await adminRepo.deleteShift(shift.id);
                                                  if (mounted) {
                                                    Navigator.pop(context); // Close edit dialog
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Shift schedule deleted successfully.'),
                                                        backgroundColor: AppColors.error,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                                  );
                                                } finally {
                                                  setModalState(() => isLoading = false);
                                                }
                                              }
                                            },
                                      child: const Text('DELETE SHIFT', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              setModalState(() => isLoading = true);
                                              try {
                                                final startDT = DateTime(
                                                  startDate.year,
                                                  startDate.month,
                                                  startDate.day,
                                                  startTime.hour,
                                                  startTime.minute,
                                                );
                                                final endDT = DateTime(
                                                  startDate.year,
                                                  startDate.month,
                                                  startDate.day,
                                                  endTime.hour,
                                                  endTime.minute,
                                                );

                                                if (endDT.isBefore(startDT)) {
                                                  throw Exception('End time cannot be before start time.');
                                                }

                                                final updatedShift = shift.copyWith(
                                                  employeeId: selectedEmployee.employeeId ?? '',
                                                  employeeName: selectedEmployee.fullName,
                                                  employerId: selectedLocation.employerId,
                                                  locationId: selectedLocation.id,
                                                  locationName: selectedLocation.name,
                                                  startTime: startDT,
                                                  endTime: endDT,
                                                );

                                                final adminRepo = ref.read(adminRepositoryProvider);
                                                await adminRepo.updateShift(updatedShift);
                                                if (selectedEmployee.employerId != selectedLocation.employerId) {
                                                  final updatedEmployee = selectedEmployee.copyWith(
                                                    employerId: selectedLocation.employerId,
                                                    updatedAt: DateTime.now(),
                                                  );
                                                  await adminRepo.updateUserProfile(updatedEmployee);
                                                }

                                                if (mounted) {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Shift updated successfully!'),
                                                      backgroundColor: AppColors.success,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                                );
                                              } finally {
                                                setModalState(() => isLoading = false);
                                              }
                                            },
                                      child: isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                                ],
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
