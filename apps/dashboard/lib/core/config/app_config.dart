class AppConfig {
  static const String _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'production');
  
  static String get baseUrl {
    switch (_flavor) {
      case 'staging':
        return 'https://staging.sharedance.com.ar';
      case 'production':
      default:
        return 'https://sharedance.com.ar';
    }
  }
  
  static bool get isStaging => _flavor == 'staging';
  static bool get isProduction => _flavor == 'production';
  
  static String get environment => _flavor;
}
