import "package:flutter/material.dart";

import "models/auth_models.dart";
import "models/generation_models.dart";
import "screens/dashboard_screen.dart";
import "screens/generate_screen.dart";
import "screens/history_screen.dart";
import "screens/login_screen.dart";
import "screens/result_screen.dart";
import "screens/settings_screen.dart";
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
  result,
  history,
  settings,
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
  AppScreen _resultBackScreen = AppScreen.dashboard;
  String? _apiKey;
  AuthValidationResponse? _authResponse;
  GenerationMode _activeMode = GenerationMode.modA;
  int? _currentResultGenerationId;
  GenerationDetail? _currentResultDetail;

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
      _currentResultGenerationId = null;
      _currentResultDetail = null;
      _screen = AppScreen.login;
    });
  }

  void _openGenerate(GenerationMode mode) {
    setState(() {
      _activeMode = mode;
      _screen = AppScreen.generate;
    });
  }

  void _openHistory() {
    setState(() {
      _screen = AppScreen.history;
    });
  }

  void _openSettings() {
    setState(() {
      _screen = AppScreen.settings;
    });
  }

  void _openResult({
    required int generationId,
    GenerationDetail? detail,
    required AppScreen backScreen,
  }) {
    setState(() {
      _currentResultGenerationId = generationId;
      _currentResultDetail = detail;
      _resultBackScreen = backScreen;
      _screen = AppScreen.result;
    });
  }

  void _backFromResult() {
    setState(() {
      _screen = _resultBackScreen;
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
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
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
          apiService: _apiService,
          onLogin: _handleLogin,
          initialApiKey: _apiKey,
        );
      case AppScreen.dashboard:
        if (_apiKey == null || _authResponse == null) {
          return LoginScreen(
            apiService: _apiService,
            onLogin: _handleLogin,
            initialApiKey: _apiKey,
          );
        }

        return DashboardScreen(
          apiService: _apiService,
          apiKey: _apiKey!,
          authResponse: _authResponse!,
          onOpenGenerate: _openGenerate,
          onOpenHistory: _openHistory,
          onOpenSettings: _openSettings,
          onOpenResult: (generationId) {
            _openResult(
              generationId: generationId,
              backScreen: AppScreen.dashboard,
            );
          },
          onLogout: _handleLogout,
        );
      case AppScreen.generate:
        if (_apiKey == null) {
          return LoginScreen(
            apiService: _apiService,
            onLogin: _handleLogin,
            initialApiKey: _apiKey,
          );
        }

        return GenerateScreen(
          apiService: _apiService,
          apiKey: _apiKey!,
          initialMode: _activeMode,
          onBack: _backToDashboard,
          onOpenHistory: _openHistory,
          onOpenSettings: _openSettings,
          onOpenResult: (detail) {
            _openResult(
              generationId: detail.generationId,
              detail: detail,
              backScreen: AppScreen.generate,
            );
          },
        );
      case AppScreen.result:
        if (_apiKey == null ||
            _authResponse == null ||
            _currentResultGenerationId == null) {
          return LoginScreen(
            apiService: _apiService,
            onLogin: _handleLogin,
            initialApiKey: _apiKey,
          );
        }

        return ResultScreen(
          apiService: _apiService,
          apiKey: _apiKey!,
          authResponse: _authResponse!,
          generationId: _currentResultGenerationId!,
          initialDetail: _currentResultDetail,
          onBack: _backFromResult,
        );
      case AppScreen.history:
        if (_apiKey == null) {
          return LoginScreen(
            apiService: _apiService,
            onLogin: _handleLogin,
            initialApiKey: _apiKey,
          );
        }

        return HistoryScreen(
          apiService: _apiService,
          apiKey: _apiKey!,
          onBack: _backToDashboard,
          onOpenResult: (generationId) {
            _openResult(
              generationId: generationId,
              backScreen: AppScreen.history,
            );
          },
        );
      case AppScreen.settings:
        if (_apiKey == null || _authResponse == null) {
          return LoginScreen(
            apiService: _apiService,
            onLogin: _handleLogin,
            initialApiKey: _apiKey,
          );
        }

        return SettingsScreen(
          apiService: _apiService,
          apiKey: _apiKey!,
          authResponse: _authResponse!,
          onBack: _backToDashboard,
          onLogout: _handleLogout,
        );
    }
  }
}
