import 'package:myapp/core/api_constants.dart';
import 'package:myapp/models/notification_model.dart';
import 'package:myapp/services/api_base_service.dart';

class NotificationService {
  final ApiBaseService _apiService = ApiBaseService();

  Future<List<AppNotification>> getNotifications() async {
    final response = await _apiService.get(ApiConstants.getNotificationsEndpoint);
    return (response as List).map((notification) => AppNotification.fromJson(notification)).toList();
  }

  Future<AppNotification> markNotificationAsRead(String notificationId) async {
    final response = await _apiService.put(
      ApiConstants.markNotificationAsReadEndpoint(notificationId),
      {}, // Empty body as per API description
    );
    return AppNotification.fromJson(response['notification']);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _apiService.delete(ApiConstants.deleteNotificationEndpoint(notificationId));
  }
}