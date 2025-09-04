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
    
    // Check if we're running on staging domain
    if (Uri.base.host == 'staging.sharedance.com.ar') {
      return 'https://staging.sharedance.com.ar';
    }
    
    // Check if we're running on production domain
    if (Uri.base.host == 'sharedance.com.ar') {
      return 'https://sharedance.com.ar';
    }

    // Fallback to flavor-based detection
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
    
    // If running on staging domain, it's definitely staging
    if (Uri.base.host == 'staging.sharedance.com.ar') {
      return true;
    }
    
    // If running on production domain, it's definitely not staging
    if (Uri.base.host == 'sharedance.com.ar') {
      return false;
    }
    
    // Fallback to flavor-based detection
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
