class AppConfig {
  static late String _flavor;
  static late String _baseUrl;
  static late bool _isProduction;
  static late String _appName;

  static String get flavor => _flavor;
  static String get baseUrl => _baseUrl;
  static bool get isProduction => _isProduction;
  static bool get isStaging => !_isProduction;
  static String get appName => _appName;

  static void configure({required String flavor}) {
    _flavor = flavor;
    _isProduction = flavor == 'production';

    switch (flavor) {
      case 'production':
        _baseUrl = 'https://api.sharedance.com.ar';
        _appName = 'ShareDance';
        break;
      case 'staging':
      default:
        _baseUrl = 'https://staging-api.sharedance.com.ar';
        _appName = 'ShareDance DEV';
        break;
    }
  }

  // Firebase Collections - same names for both environments since projects are separate
  static String get usersCollection => 'users';
  static String get classesCollection => 'classes';
  static String get reservationsCollection => 'reservations';
  static String get roomsCollection => 'rooms';
  static String get packsCollection => 'packs';
  static String get purchasesCollection => 'purchases';
  static String get reportsCollection => 'reports';
  static String get notificationsCollection => 'notifications';

  // Firebase Storage paths
  static String get profileImagesPath => 'profile_images';
  static String get classImagesPath => 'class_images';

  // App settings based on flavor
  static bool get enableAnalytics => _isProduction;
  static bool get enableCrashlytics => _isProduction;
  static bool get showDebugBanner => !_isProduction;
}
