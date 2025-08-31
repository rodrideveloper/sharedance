import 'package:flutter/material.dart';

class FlavorHelper {
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'staging',
  );

  static bool get isStaging => flavor == 'staging';
  static bool get isProduction => flavor == 'production';

  static String get flavorName => flavor.toUpperCase();

  /// Widget que muestra un banner de staging si estamos en modo staging
  static Widget? getStagingBanner() {
    if (!isStaging) return null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Colors.orange,
      child: Text(
        '🚧 STAGING ENVIRONMENT 🚧',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Widget pequeño para mostrar en esquinas
  static Widget? getStagingCornerIndicator() {
    if (!isStaging) return null;

    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
        ),
        child: const Text(
          'STAGING',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
