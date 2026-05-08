class SystemStatus {
  const SystemStatus({
    required this.status,
    required this.service,
    required this.version,
    required this.ai,
  });

  final String status;
  final String service;
  final String version;
  final AiStatus ai;

  bool get isHealthy => status.toLowerCase() == "healthy";

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      status: json["status"] as String? ?? "unknown",
      service: json["service"] as String? ?? "TestPilot API",
      version: json["version"] as String? ?? "",
      ai: AiStatus.fromJson(json["ai"] as Map<String, dynamic>? ?? {}),
    );
  }
}

class AiStatus {
  const AiStatus({
    required this.configuredProvider,
    required this.effectiveProvider,
    required this.model,
    required this.fallbackToMock,
    required this.geminiKeyConfigured,
  });

  final String configuredProvider;
  final String effectiveProvider;
  final String model;
  final bool fallbackToMock;
  final bool geminiKeyConfigured;

  String get displayName {
    switch (effectiveProvider.toLowerCase()) {
      case "gemini":
        return "Gemini";
      case "mock":
        return "Mock";
      case "unavailable":
        return "Kullanılamıyor";
      case "unsupported":
        return "Desteklenmiyor";
      default:
        return effectiveProvider.isEmpty ? "Bilinmiyor" : effectiveProvider;
    }
  }

  factory AiStatus.fromJson(Map<String, dynamic> json) {
    return AiStatus(
      configuredProvider: json["configured_provider"] as String? ?? "unknown",
      effectiveProvider: json["effective_provider"] as String? ?? "unknown",
      model: json["model"] as String? ?? "",
      fallbackToMock: json["fallback_to_mock"] as bool? ?? false,
      geminiKeyConfigured: json["gemini_key_configured"] as bool? ?? false,
    );
  }
}
