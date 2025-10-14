class AppConstants {
  // App info
  static const String appName = 'Civic Pulse';
  static const String appVersion = '1.0.0';

  // Firebase collections
  static const String usersCollection = 'users';
  static const String userStatsCollection = 'userStats';
  static const String issuesCollection = 'issues';
  static const String notificationsCollection = 'notifications';

  // User roles
  static const String citizenRole = 'Citizen';
  static const String authorityRole = 'Authority';

  // Issue statuses
  static const String pendingStatus = 'Pending';
  static const String inProgressStatus = 'In Progress';
  static const String resolvedStatus = 'Resolved';

  // Issue types
  static const List<String> issueTypes = [
    'Pothole',
    'Garbage',
    'Water Leak',
    'Street Light',
    'Traffic',
    'Road Damage',
    'Sewage',
    'Other',
  ];

  // Points system
  static const int pointsForReport = 10;
  static const int pointsForUpvote = 1;
  static const int pointsForResolution = 5;

  // Map settings
  static const double defaultZoom = 15.0;
  static const double maxZoom = 20.0;
  static const double minZoom = 5.0;

  // Image settings
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Notification types
  static const String newIssueNotification = 'new_issue';
  static const String statusUpdateNotification = 'status_update';
  static const String upvoteNotification = 'upvote';

  // API endpoints (if using external services)
  static const String googleMapsApiKey = 'AIzaSyDBm3PkR6Z-klwkdiMUFL2zLTSj3g5byvQ';
  
  // Error messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String permissionDenied = 'Permission denied. Please enable location access.';
  static const String imageUploadError = 'Failed to upload image. Please try again.';
  static const String locationError = 'Unable to get location. Please try again.';
}
