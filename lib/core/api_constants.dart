class ApiConstants {
  static const String baseUrl = 'https://event-backend-4rd9.onrender.com/api';

 
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String getAuthUserEndpoint = '/auth';

  // Chat Endpoints
  static const String startChatEndpoint = '/chat/start';
  static const String createGroupChatEndpoint = '/chat/group';
  static const String getUserChatsEndpoint = '/chat';
  static String getChatMessagesEndpoint(String chatId) => '/chat/$chatId/messages';
  static String sendMessageEndpoint(String chatId) => '/chat/$chatId/messages';
  static String markMessageAsReadEndpoint(String messageId) => '/chat/messages/$messageId/read';

  // Notification Endpoints
  static const String getNotificationsEndpoint = '/notifications';
  static String markNotificationAsReadEndpoint(String notificationId) => '/notifications/$notificationId/read';
  static String deleteNotificationEndpoint(String notificationId) => '/notifications/$notificationId';

  // Post Endpoints
  static const String createPostEndpoint = '/posts';
  static const String getAllPostsEndpoint = '/posts';
  static String getPostByIdEndpoint(String postId) => '/posts/$postId';
  static String updatePostEndpoint(String postId) => '/posts/$postId';
  static String deletePostEndpoint(String postId) => '/posts/$postId';
  static String togglePostInterestEndpoint(String postId) => '/posts/$postId/interest';
  static String markAttendanceEndpoint(String postId) => '/posts/$postId/attend';
  static const String getInterestedPostsEndpoint = '/posts/my/interested';
  static String togglePostAttendanceEndpoint(String postId) => '/posts/$postId/attendance';
  static const String getAttendedPostsEndpoint = '/posts/my/attended';


  static String getUserProfileEndpoint(String userId) => '/users/$userId';
  static String updateUserProfileEndpoint(String userId) => '/users/$userId';
  static String getUserPostsEndpoint(String userId) => '/users/$userId/posts';
  static String followUserEndpoint(String userId) => '/users/$userId/follow';
  static String unfollowUserEndpoint(String userId) => '/users/$userId/unfollow';
}
