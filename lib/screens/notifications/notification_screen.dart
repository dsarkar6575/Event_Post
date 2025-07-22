import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/notification_model.dart';
import 'package:myapp/providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    await Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading && notificationProvider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (notificationProvider.error != null) {
            return Center(child: Text('Error: ${notificationProvider.error}'));
          }
          if (notificationProvider.notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            child: ListView.builder(
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationProvider.notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    await notificationProvider.deleteNotification(notification.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notification deleted: ${notification.message}')),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    color: notification.isRead ? null : Colors.blue.shade50,
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: notification.sender?.profileImageUrl != null
                            ? NetworkImage(notification.sender!.profileImageUrl!)
                            : null,
                        child: notification.sender?.profileImageUrl == null
                            ? Text(notification.sender?.username[0].toUpperCase() ?? '')
                            : null,
                      ),
                      title: Text(notification.message),
                      subtitle: Text(timeago.format(notification.createdAt)),
                      onTap: () async {
                        if (!notification.isRead) {
                          await notificationProvider.markNotificationAsRead(notification.id);
                        }
                        // TODO: Navigate to relevant screen based on notification type/entityId
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Notification tapped! Type: ${notification.type.name}')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}