import "package:flutter/material.dart";

class AppConstants {
  static const String appName = "TestPilot";
  static const String apiKeyStorageKey = "testpilot_api_key";

  // Android emulator default. Override when needed:
  // flutter run --dart-define=API_BASE_URL=http://localhost:8000
  static const String apiBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://10.0.2.2:8000",
  );
}

class AppColors {
  static const Color navy = Color(0xFF102050);
  static const Color sky = Color(0xFF50B0E0);
  static const Color accent = Color(0xFFE07020);
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
}
