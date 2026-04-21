import "package:flutter/material.dart";

import "models/auth_models.dart";
import "models/generation_models.dart";
import "screens/dashboard_screen.dart";
import "screens/generate_screen.dart";
import "screens/login_screen.dart";
import "services/api_service.dart";
import "services/storage_service.dart";
import "utils/constants.dart";

void main() {
  runApp(const TestPilotMobileApp());
}

enum AppScreen {
  splash,
  login,
  dashboard,
  generate,
}

class TestPilotMobileApp extends StatefulWidget {
  const TestPilotMobileApp({super.key});

  @override
  State<TestPilotMobileApp> createState() => _TestPilotMobileAppState();
}

class _TestPilotMobileAppState extends State<TestPilotMobileApp> {
  final StorageService _storageService = StorageService();
  late final ApiService _apiService = ApiService(
    baseUrl: AppConstants.apiBaseUrl,
  );

  AppScreen _screen = AppScreen.splash;
  String? _apiKey;
  AuthValidationResponse? _authResponse;
  GenerationMode _activeMode = GenerationMode.modA;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final savedApiKey = await _storageService.getApiKey();

    if (savedApiKey == null || savedApiKey.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _screen = AppScreen.login;
      });
      return;
    }

    try {
      final authResponse = await _apiService.validateApiKey(savedApiKey);

      if (!mounted) {
        return;
      }

      setState(() {
        _apiKey = savedApiKey;
        _authResponse = authResponse;
        _screen = AppScreen.dashboard;
      });
    } catch (_) {
      await _storageService.clearApiKey();

      if (!mounted) {
        return;
      }

      setState(() {
        _screen = AppScreen.login;
      });
    }
  }

  Future<void> _handleLogin(String apiKey) async {
    final validated = await _apiService.validateApiKey(apiKey);
    await _storageService.saveApiKey(apiKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _apiKey = apiKey;
      _authResponse = validated;
      _screen = AppScreen.dashboard;
    });
  }

  Future<void> _handleLogout() async {
    await _storageService.clearApiKey();

    if (!mounted) {
      return;
    }

    setState(() {
      _apiKey = null;
      _authResponse = null;
      _screen = AppScreen.login;
    });
  }

  void _openGenerate(GenerationMode mode) {
    setState(() {
      _activeMode = mode;
      _screen = AppScreen.generate;
    });
  }

  void _backToDashboard() {
    setState(() {
      _screen = AppScreen.dashboard;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: _buildHome(),
    );
  }

  ThemeData _buildTheme() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.navy,
      secondary: AppColors.sky,
      surface: AppColors.surface,
      error: Color(0xFFB42318),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.sky, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildHome() {
    switch (_screen) {
      case AppScreen.splash:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AppScreen.login:
        return LoginScreen(
          onLogin: _handleLogin,
          initialApiKey: _apiKey,
        );
      case AppScreen.dashboard:
        if (_apiKey == null || _authResponse == null) {
          return LoginScreen(
            onLogin: _handleLogin,
            initialApiKey: _apiKey,
          );
        }

        return DashboardScreen(
          apiService: _apiService,
          apiKey: _apiKey!,
          authResponse: _authResponse!,
          onLogout: _handleLogout,
          onOpenGenerate: _openGenerate,
        );
      case AppScreen.generate:
        if (_apiKey == null) {
          return LoginScreen(
            onLogin: _handleLogin,
            initialApiKey: _apiKey,
          );
        }

        return GenerateScreen(
          apiService: _apiService,
          apiKey: _apiKey!,
          initialMode: _activeMode,
          onBack: _backToDashboard,
        );
    }
  }
}
