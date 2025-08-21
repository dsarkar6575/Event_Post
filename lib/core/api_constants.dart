class ApiConstants {
  static const String baseUrl = 'https://event-management-system-backend0.onrender.com/api';

  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String getAuthUserEndpoint = '/auth';
  static const String verifyOtpEndpoint = '/auth/verify'; // Added for OTP verification
  static const String refreshTokenEndpoint = '/auth/refresh-token'; // Added for token refresh

  // Chat Endpoints
  static const String startChatEndpoint = '/chat/start';
  static const String createGroupChatEndpoint = '/chat/group';
  static const String getUserChatsEndpoint = '/chat';
  static String getChatMessagesEndpoint(String chatId) => '/chat/$chatId/messages';
  static String markMessageAsReadEndpoint(String messageId) => '/chat/messages/$messageId/read';
  // ✅ CORRECTED: Added dedicated endpoint for joining event chats
  static String joinEventGroupChatEndpoint(String postId) => '/chat/join/$postId';

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
  static const String getFeedPostsEndpoint = '/posts/feed';
  static String togglePostInterestEndpoint(String postId) => '/posts/$postId/interest';
  static String markAttendanceEndpoint(String postId) => '/posts/$postId/attend';
  static const String getInterestedPostsEndpoint = '/posts/my/interested';
  static String togglePostAttendanceEndpoint(String postId) => '/posts/$postId/attendance';
  static const String getAttendedPostsEndpoint = '/posts/my/attended';

  // User Endpoints
  static String getUserProfileEndpoint(String userId) => '/users/$userId';
  static String updateUserProfileEndpoint(String userId) => '/users/$userId';
  static String getUserPostsEndpoint(String userId) => '/users/$userId/posts';
  static String followUserEndpoint(String userId) => '/users/$userId/follow';
  static String unfollowUserEndpoint(String userId) => '/users/$userId/unfollow';
}