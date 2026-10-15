import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService;
  final SocketService _socketService;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  AppNotification? _latestBannerNotification;

  NotificationProvider(this._apiService, this._socketService) {
    _socketService.addPushNotificationListener(_onSocketNotification);
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  AppNotification? get latestBannerNotification => _latestBannerNotification;

  void _onSocketNotification(Map<String, dynamic> data) {
    try {
      final notif = AppNotification.fromJson(data);
      // Avoid duplicate notifications
      _notifications.removeWhere((n) => n.id == notif.id);
      _notifications.insert(0, notif);
      _unreadCount++;
      _latestBannerNotification = notif;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationProvider] Parse error: $e');
      }
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _apiService.getNotifications();
      _notifications = list;
      _unreadCount = list.where((n) => !n.isRead).length;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationProvider] Fetch error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
      await _apiService.markNotificationRead(id);
    }
  }

  Future<void> markAllAsRead() async {
    bool hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    await _apiService.markAllNotificationsRead();
  }

  void dismissBanner() {
    _latestBannerNotification = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.removePushNotificationListener(_onSocketNotification);
    super.dispose();
  }
}
