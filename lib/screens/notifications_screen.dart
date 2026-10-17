import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import 'auction_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  Widget _buildTypeIcon(AppNotification notif) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (notif.type) {
      case 'outbid':
        iconData = Icons.warning_amber_rounded;
        iconColor = Colors.orange.shade800;
        bgColor = Colors.orange.shade50;
        break;
      case 'won':
        iconData = Icons.emoji_events_rounded;
        iconColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'lost':
        iconData = Icons.gavel_rounded;
        iconColor = Colors.blueGrey;
        bgColor = Colors.blueGrey.shade50;
        break;
      case 'live':
        iconData = Icons.bolt_rounded;
        iconColor = AppTheme.primary;
        bgColor = AppTheme.primary.withValues(alpha: 0.1);
        break;
      default:
        iconData = Icons.notifications_active_rounded;
        iconColor = AppTheme.primary;
        bgColor = AppTheme.primary.withValues(alpha: 0.1);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  void _onNotificationTap(AppNotification notif) {
    final provider = context.read<NotificationProvider>();
    if (!notif.isRead) {
      provider.markAsRead(notif.id);
    }

    if (notif.auctionId != null && notif.auctionId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuctionDetailScreen(auctionId: notif.auctionId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton.icon(
              onPressed: () => provider.markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchNotifications(),
        child: provider.isLoading && notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Notifications Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'When someone outbids you or an auction you bid on ends, you will receive instant push alerts here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 72,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return Material(
                        color: notif.isRead
                            ? Colors.white
                            : AppTheme.primary.withValues(alpha: 0.04),
                        child: InkWell(
                          onTap: () => _onNotificationTap(notif),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTypeIcon(notif),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: notif.isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.bold,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            notif.timeAgo,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: notif.isRead
                                                  ? AppTheme.textMuted
                                                  : AppTheme.primary,
                                              fontWeight: notif.isRead
                                                  ? FontWeight.normal
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.body,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: notif.isRead
                                              ? AppTheme.textDark.withValues(alpha: 0.8)
                                              : AppTheme.textDark,
                                          height: 1.3,
                                        ),
                                      ),
                                      if (notif.auctionId != null) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              'Tap to view auction',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            const Icon(
                                              Icons.chevron_right,
                                              size: 14,
                                              color: AppTheme.primary,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (!notif.isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
