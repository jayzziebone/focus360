import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftsync/core/constants/app_colors.dart';
import 'package:shiftsync/features/auth/presentation/providers/auth_provider.dart';
import 'package:shiftsync/features/auth/data/models/user_model.dart';
import 'package:shiftsync/features/employee/presentation/providers/employee_provider.dart';
import 'package:shiftsync/features/notifications/presentation/screens/notifications_screen.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationsBellWidget extends ConsumerWidget {
  final String userId;

  const NotificationsBellWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to notification changes to trigger foreground SnackBar and auto-refresh shift targeting
    ref.listen<AsyncValue<List<NotificationModel>>>(
      userNotificationsProvider(userId),
      (previous, next) {
        if (next.hasValue && previous != null && previous.hasValue) {
          final prevList = previous.value!;
          final nextList = next.value!;

          // Find newly added notifications
          final newItems = nextList.where((item) =>
              !item.isRead && !prevList.any((prevItem) => prevItem.id == item.id));

          if (newItems.isNotEmpty) {
            for (final item in newItems) {
              // 1. Show Foreground Banner (SnackBar)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.body,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.secondary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  action: SnackBarAction(
                    label: 'VIEW',
                    textColor: Colors.amber,
                    onPressed: () {
                      _navigateToNotifications(context);
                    },
                  ),
                ),
              );

              // 2. Auto-refresh punch tab data if a new schedule arrives for the employee
              final auth = ref.read(authProvider);
              final isEmployee = auth.userModel?.role == UserRole.employee;
              if (isEmployee && (item.type == 'shift_created' || item.type == 'shift_modified' || item.type == 'shift_deleted')) {
                print('=== [DEBUG] New shift notification received. Invalidating providers... ===');
                ref.invalidate(employeeShiftsProvider);
                ref.invalidate(employeeLocationsProvider);
                // Trigger a GPS refresh to re-evaluate geofencing for the new shift details
                Future.delayed(const Duration(milliseconds: 500), () {
                  ref.read(punchProvider.notifier).checkGpsLocation();
                });
              }
            }
          }
        }
      },
    );

    final notificationsAsync = ref.watch(userNotificationsProvider(userId));

    return notificationsAsync.when(
      data: (list) {
        final unreadCount = list.where((n) => !n.isRead).length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                unreadCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                color: unreadCount > 0 ? Colors.amber : AppColors.secondary,
                size: 28,
              ),
              onPressed: () => _navigateToNotifications(context),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NotificationsScreen(userId: userId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            alignment: Alignment.topRight,
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }
}
