// lib/features/notifications/notifications_system.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'dart:async';

// ============================================================================
// NOTIFICATION MODEL
// ============================================================================

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      type: NotificationType.fromString(json['type']),
      title: json['title'],
      body: json['body'],
      data: json['data'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.newOffer:
        return Icons.local_offer;
      case NotificationType.offerAccepted:
        return Icons.check_circle;
      case NotificationType.offerRejected:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.priceDrop:
        return Icons.trending_down;
      case NotificationType.itemSold:
        return Icons.shopping_bag;
      case NotificationType.favoriteAvailable:
        return Icons.favorite;
      case NotificationType.achievementUnlocked:
        return Icons.emoji_events;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.newOffer:
        return const Color(0xFFBB86FC);
      case NotificationType.offerAccepted:
        return const Color(0xFF00E676);
      case NotificationType.offerRejected:
        return Colors.red;
      case NotificationType.newMessage:
        return const Color(0xFF2962FF);
      case NotificationType.priceDrop:
        return Colors.orange;
      case NotificationType.itemSold:
        return const Color(0xFF00E676);
      case NotificationType.favoriteAvailable:
        return Colors.pink;
      case NotificationType.achievementUnlocked:
        return Colors.amber;
    }
  }
}

enum NotificationType {
  newOffer,
  offerAccepted,
  offerRejected,
  newMessage,
  priceDrop,
  itemSold,
  favoriteAvailable,
  achievementUnlocked;

  static NotificationType fromString(String value) {
    switch (value) {
      case 'new_offer':
        return NotificationType.newOffer;
      case 'offer_accepted':
        return NotificationType.offerAccepted;
      case 'offer_rejected':
        return NotificationType.offerRejected;
      case 'new_message':
        return NotificationType.newMessage;
      case 'price_drop':
        return NotificationType.priceDrop;
      case 'item_sold':
        return NotificationType.itemSold;
      case 'favorite_available':
        return NotificationType.favoriteAvailable;
      case 'achievement_unlocked':
        return NotificationType.achievementUnlocked;
      default:
        return NotificationType.newMessage;
    }
  }

  String get value {
    return toString().split('.').last.replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        );
  }
}

// ============================================================================
// NOTIFICATION SERVICE
// ============================================================================

class NotificationService {
  final _supabase = Supabase.instance.client;
  StreamSubscription? _subscription;

  // Get all notifications
  Future<List<AppNotification>> getNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((json) => AppNotification.fromJson(json))
        .toList();
  }

  // Stream of notifications (real-time)
  Stream<List<AppNotification>> getNotificationsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data
            .map((json) => AppNotification.fromJson(json))
            .toList());
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }

  // Clear all notifications
  Future<void> clearAll() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('notifications')
        .delete()
        .eq('user_id', userId);
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationServiceProvider).getNotificationsStream();
});

final unreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  return ref
      .watch(notificationServiceProvider)
      .getNotificationsStream()
      .map((notifications) =>
          notifications.where((n) => !n.isRead).length);
});

// ============================================================================
// IN-APP NOTIFICATION BANNER
// ============================================================================

class InAppNotificationBanner extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InAppNotificationBanner({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: () {
          widget.onTap?.call();
          _dismiss();
        },
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.notification.color.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.notification.color.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.notification.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.notification.icon,
                  color: widget.notification.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.notification.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.notification.body,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: _dismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NOTIFICATIONS SCREEN
// ============================================================================

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearConfirmation(context, ref),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2962FF)),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading notifications',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(
                context,
                ref,
                notifications[index],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see updates here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref
            .read(notificationServiceProvider)
            .deleteNotification(notification.id);
        ref.invalidate(notificationsProvider);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.grey[900] : Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey[800]!
                : notification.color.withOpacity(0.3),
          ),
        ),
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              await ref
                  .read(notificationServiceProvider)
                  .markAsRead(notification.id);
              ref.invalidate(notificationsProvider);
            }
            // Handle navigation based on notification type
            _handleNotificationTap(context, notification);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: notification.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: notification.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
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
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) {
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.newOffer:
      case NotificationType.offerAccepted:
        // Navigate to offers screen
        break;
      case NotificationType.newMessage:
        // Navigate to chat
        break;
      default:
        break;
    }
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Clear All Notifications?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete all notifications.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(notificationServiceProvider).clearAll();
              ref.invalidate(notificationsProvider);
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NOTIFICATION BADGE WIDGET
// ============================================================================

class NotificationBadge extends ConsumerWidget {
  final Widget child;

  const NotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    return Stack(
      children: [
        child,
        unreadCount.when(
          data: (count) {
            if (count == 0) return const SizedBox.shrink();
            return Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
