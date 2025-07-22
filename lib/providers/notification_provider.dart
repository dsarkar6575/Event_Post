import 'package:flutter/material.dart';
import 'package:myapp/models/notification_model.dart';
import 'package:myapp/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _notificationService.getNotifications();
    } catch (e) {
      _error = e.toString();
      print('Fetch Notifications Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    _error = null;
    try {
      final updatedNotification = await _notificationService.markNotificationAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = updatedNotification;
      }
    } catch (e) {
      _error = e.toString();
      print('Mark Notification As Read Error: $_error');
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    _error = null;
    try {
      await _notificationService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
    } catch (e) {
      _error = e.toString();
      print('Delete Notification Error: $_error');
    } finally {
      notifyListeners();
    }
  }

  // Method to add new notification received via Socket.IO
  void addNotification(AppNotification notification) {
    if (_notifications.any((n) => n.id == notification.id)) return; // Avoid duplicates
    _notifications.insert(0, notification);
    notifyListeners();
  }
}