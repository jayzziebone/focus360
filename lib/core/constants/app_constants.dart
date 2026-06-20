class AppConstants {
  // App Info
  static const String appName = 'Focus360';

  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String employersCollection = 'employers';
  static const String locationsCollection = 'locations';
  static const String employeesCollection = 'employees';
  static const String shiftsCollection = 'shifts';
  static const String attendanceCollection = 'attendance_records';
  static const String notificationsCollection = 'notifications';

  // GPS Configuration
  static const int defaultAllowedRadiusMeters = 100;

  // Shared Preference Keys / Mock defaults if any
  static const String userRoleKey = 'user_role';

  // FCM Configuration
  static const String fcmServerKey = 'YOUR_SERVER_KEY';
}
