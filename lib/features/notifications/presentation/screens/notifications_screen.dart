import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shiftsync/core/constants/app_colors.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          notificationsAsync.when(
            data: (list) {
              if (list.isEmpty) return const SizedBox.shrink();
              final unreadCount = list.where((n) => !n.isRead).length;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (unreadCount > 0)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(notificationRepositoryProvider).markAllAsRead(userId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications marked as read.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                      label: const Text(
                        'Mark all read',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => _showClearConfirmationDialog(context, ref),
                    icon: const Icon(Icons.clear_all_rounded, size: 18, color: AppColors.error),
                    label: const Text(
                      'Clear',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: notificationsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_off_outlined,
                          size: 72,
                          color: AppColors.outline.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'All caught up!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You don\'t have any notifications right now.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: list.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = list[index];
                final timeAgo = _formatTimeAgo(notif.createdAt);

                return Dismissible(
                  key: Key(notif.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                  onDismissed: (direction) {
                    ref.read(notificationRepositoryProvider).deleteNotification(notif.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification deleted'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: notif.isRead
                            ? AppColors.secondary.withOpacity(0.08)
                            : AppColors.primary.withOpacity(0.18),
                        width: notif.isRead ? 1 : 1.5,
                      ),
                    ),
                    color: notif.isRead
                        ? Colors.white
                        : AppColors.primary.withOpacity(0.04),
                    child: InkWell(
                      onTap: () {
                        if (!notif.isRead) {
                          ref.read(notificationRepositoryProvider).markAsRead(notif.id);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTypeIcon(notif.type, notif.isRead),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif.title,
                                          style: TextStyle(
                                            fontWeight: notif.isRead
                                                ? FontWeight.bold
                                                : FontWeight.w800,
                                            fontSize: 15,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                      if (!notif.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notif.body,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    timeAgo,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.outline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error loading notifications: $err',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type, bool isRead) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'shift_created':
        iconData = Icons.calendar_today_rounded;
        color = Colors.amber.shade700;
        break;
      case 'shift_modified':
        iconData = Icons.calendar_month_rounded;
        color = AppColors.primary;
        break;
      case 'shift_deleted':
        iconData = Icons.event_busy_rounded;
        color = AppColors.error;
        break;
      case 'punch_in':
        iconData = Icons.login_rounded;
        color = Colors.green.shade600;
        break;
      case 'punch_out':
        iconData = Icons.logout_rounded;
        color = Colors.orange.shade700;
        break;
      case 'approved':
        iconData = Icons.check_circle_outline_rounded;
        color = AppColors.success;
        break;
      case 'rejected':
        iconData = Icons.error_outline_rounded;
        color = AppColors.error;
        break;
      default:
        iconData = Icons.notifications_rounded;
        color = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRead ? color.withOpacity(0.08) : color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dt);
    }
  }

  void _showClearConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear all notifications?'),
          content: const Text(
            'This will permanently delete all your notifications. This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppColors.outline),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(notificationRepositoryProvider).clearAllNotifications(userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications cleared.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('CLEAR ALL'),
            ),
          ],
        );
      },
    );
  }
}
