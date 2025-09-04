import 'dart:js' as js;

class AppConfig {
  static const String _flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'production',
  );

  static String get baseUrl {
    // First try to get from JavaScript window object
    try {
      final jsConfig = js.context['sharedanceConfig'];
      if (jsConfig != null) {
        final baseUrlFunc = jsConfig['baseUrl'];
        if (baseUrlFunc != null) {
          final baseUrl = jsConfig.callMethod('baseUrl', []);
          print('🔗 AppConfig: Using JS baseUrl: $baseUrl');
          return baseUrl;
        }
      }
    } catch (e) {
      print('⚠️ AppConfig: JS baseUrl detection failed: $e');
    }

    // Fallback to Uri.base.host detection
    final hostname = Uri.base.host;
    print('🌐 AppConfig Debug - Current hostname: $hostname');
    print('🌐 AppConfig Debug - Current Uri.base: ${Uri.base}');
    
    // Check if we're running on localhost for development
    if (hostname == 'localhost' || hostname == '127.0.0.1') {
      // For localhost development, use staging backend
      print('🏠 AppConfig: Detected localhost - using staging backend');
      return 'https://staging.sharedance.com.ar';
    }
    
    // Check if we're running on staging domain
    if (hostname == 'staging.sharedance.com.ar') {
      print('🔧 AppConfig: Detected staging domain - using staging backend');
      return 'https://staging.sharedance.com.ar';
    }
    
    // Check if we're running on production domain
    if (hostname == 'sharedance.com.ar') {
      print('🏭 AppConfig: Detected production domain - using production backend');
      return 'https://sharedance.com.ar';
    }

    // Fallback to flavor-based detection
    print('⚠️ AppConfig: Using fallback flavor detection - flavor: $_flavor');
    switch (_flavor) {
      case 'staging':
        print('🔧 AppConfig: Flavor staging - using staging backend');
        return 'https://staging.sharedance.com.ar';
      case 'production':
      default:
        print('🏭 AppConfig: Flavor production (default) - using production backend');
        return 'https://sharedance.com.ar';
    }
  }

  static bool get isStaging {
    // First try to get from JavaScript window object
    try {
      final jsConfig = js.context['sharedanceConfig'];
      if (jsConfig != null) {
        final isStaging = jsConfig['isStaging'];
        print('🔧 AppConfig: Using JS detection - isStaging: $isStaging');
        return isStaging == true;
      }
    } catch (e) {
      print('⚠️ AppConfig: JS detection failed: $e');
    }

    // Fallback to Uri.base.host detection
    final hostname = Uri.base.host;
    print('🌐 AppConfig Debug - Current hostname: $hostname');
    
    if (hostname == 'localhost' || hostname == '127.0.0.1' || hostname == 'staging.sharedance.com.ar') {
      print('🔧 AppConfig: Fallback hostname detection - isStaging: true');
      return true;
    }

    // Final fallback to flavor
    print('⚠️ AppConfig: Using fallback flavor detection - flavor: $_flavor');
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
