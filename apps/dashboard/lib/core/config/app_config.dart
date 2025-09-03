class AppConfig {
  static const String _flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'production',
  );

  static String get baseUrl {
    // Check if we're running on localhost for development
    if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
      // For localhost development, use staging backend
      return 'https://staging.sharedance.com.ar';
    }

    switch (_flavor) {
      case 'staging':
        return 'https://staging.sharedance.com.ar';
      case 'production':
      default:
        return 'https://sharedance.com.ar';
    }
  }

  static bool get isStaging {
    // If running on localhost, consider it staging for development
    if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
      return true;
    }
    return _flavor == 'staging';
  }

  static bool get isProduction => !isStaging;

  static String get environment {
    if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
      return 'staging';
    }
    return _flavor;
  }
}
