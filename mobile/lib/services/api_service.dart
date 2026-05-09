import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:http/http.dart" as http;

import "../models/auth_models.dart";
import "../models/batch_models.dart";
import "../models/generation_models.dart";
import "../models/history_models.dart";
import "../models/system_models.dart";
import "../models/template_models.dart";
import "../models/usage_models.dart";

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  Future<AccessKeyCreateResponse> createFreeAccess({
    String? ownerName,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse("$baseUrl/api/v1/auth/access/free"),
        headers: _jsonHeaders(),
        body: jsonEncode({
          if (ownerName != null && ownerName.trim().isNotEmpty)
            "owner_name": ownerName.trim(),
        }),
      ),
    );

    return _parseJsonResponse(
      response,
      (json) => AccessKeyCreateResponse.fromJson(json),
    );
  }

  Future<AccessKeyCreateResponse> createPremiumAccess({
    required String ownerName,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse("$baseUrl/api/v1/auth/access/premium"),
        headers: _jsonHeaders(),
        body: jsonEncode({
          "owner_name": ownerName.trim(),
          "plan_summary": "Premium monthly simulation",
        }),
      ),
    );

    return _parseJsonResponse(
      response,
      (json) => AccessKeyCreateResponse.fromJson(json),
    );
  }

  Future<SystemStatus> fetchSystemStatus() async {
    final response = await _send(
      () => http.get(Uri.parse("$baseUrl/health")),
      timeout: const Duration(seconds: 8),
    );

    return _parseJsonResponse(
      response,
      (json) => SystemStatus.fromJson(json),
    );
  }

  Future<AuthValidationResponse> validateApiKey(String apiKey) async {
    final response = await _send(
      () => http.post(
        Uri.parse("$baseUrl/api/v1/auth/validate"),
        headers: _headers(apiKey),
      ),
    );

    return _parseJsonResponse(
      response,
      (json) => AuthValidationResponse.fromJson(json),
    );
  }

  Future<UsageSummary> fetchUsage(String apiKey) async {
    final response = await _send(
      () => http.get(
        Uri.parse("$baseUrl/api/v1/usage"),
        headers: _headers(apiKey),
      ),
    );

    return _parseJsonResponse(
      response,
      (json) => UsageSummary.fromJson(json),
    );
  }

  Future<HistoryListResponse> fetchHistory(String apiKey) async {
    return fetchHistoryWithFilters(apiKey: apiKey);
  }

  Future<HistoryListResponse> fetchHistoryWithFilters({
    required String apiKey,
    GenerationMode? mode,
    String? query,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/history").replace(
      queryParameters: {
        if (mode != null) "mode": mode.apiValue,
        if (query != null && query.trim().isNotEmpty) "q": query.trim(),
      },
    );

    final response = await _send(
      () => http.get(
        uri,
        headers: _headers(apiKey),
      ),
    );

    return _parseJsonResponse(
      response,
      (json) => HistoryListResponse.fromJson(json),
    );
  }

  Future<GenerationDetail> fetchHistoryDetail({
    required String apiKey,
    required int generationId,
  }) async {
    final response = await _send(
      () => http.get(
        Uri.parse("$baseUrl/api/v1/history/$generationId"),
        headers: _headers(apiKey),
      ),
    );

    return _parseJsonResponse(
      response,
      (json) => GenerationDetail.fromJson(json),
    );
  }

  Future<void> deleteHistoryItem({
    required String apiKey,
    required int generationId,
  }) async {
    final response = await _send(
      () => http.delete(
        Uri.parse("$baseUrl/api/v1/history/$generationId"),
        headers: _headers(apiKey),
      ),
    );

    _ensureSuccessfulResponse(response);
  }

  Future<GenerationResult> generate({
    required String apiKey,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse("$baseUrl/api/v1/generate"),
        headers: _headers(apiKey, withJson: true),
        body: jsonEncode(payload),
      ),
      timeout: const Duration(seconds: 80),
    );

    return _parseJsonResponse(
      response,
      (json) => GenerationResult.fromJson(json),
    );
  }

  Future<BatchGenerateResponse> batchGenerate({
    required String apiKey,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse("$baseUrl/api/v1/generate/batch"),
        headers: _headers(apiKey, withJson: true),
        body: jsonEncode(payload),
      ),
      timeout: const Duration(seconds: 140),
    );

    return _parseJsonResponse(
      response,
      (json) => BatchGenerateResponse.fromJson(json),
    );
  }

  Future<TemplateListResponse> fetchTemplates(String apiKey) async {
    final response = await _send(
      () => http.get(
        Uri.parse("$baseUrl/api/v1/templates"),
        headers: _headers(apiKey),
      ),
    );

    return _parseJsonResponse(
      response,
      (json) => TemplateListResponse.fromJson(json),
    );
  }

  Future<TemplateItem> createTemplate({
    required String apiKey,
    required String name,
    required String promptText,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse("$baseUrl/api/v1/templates"),
        headers: _headers(apiKey, withJson: true),
        body: jsonEncode({
          "name": name.trim(),
          "prompt_text": promptText.trim(),
        }),
      ),
    );

    return _parseJsonResponse(
      response,
      (json) => TemplateItem.fromJson(json),
    );
  }

  Future<TemplateItem> updateTemplate({
    required String apiKey,
    required int templateId,
    required String name,
    required String promptText,
  }) async {
    final response = await _send(
      () => http.put(
        Uri.parse("$baseUrl/api/v1/templates/$templateId"),
        headers: _headers(apiKey, withJson: true),
        body: jsonEncode({
          "name": name.trim(),
          "prompt_text": promptText.trim(),
        }),
      ),
    );

    return _parseJsonResponse(
      response,
      (json) => TemplateItem.fromJson(json),
    );
  }

  Future<void> deleteTemplate({
    required String apiKey,
    required int templateId,
  }) async {
    final response = await _send(
      () => http.delete(
        Uri.parse("$baseUrl/api/v1/templates/$templateId"),
        headers: _headers(apiKey),
      ),
    );

    _ensureSuccessfulResponse(response);
  }

  Future<ExportedFile> exportGeneration({
    required String apiKey,
    required int generationId,
    required ExportFormat format,
  }) async {
    final response = await _send(
      () => http.get(
        Uri.parse("$baseUrl/api/v1/export/$generationId/${format.apiValue}"),
        headers: _headers(apiKey),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessageFromResponse(
          response,
          fallback: "Export işlemi tamamlanamadı.",
        ),
      );
    }

    final contentDisposition = response.headers["content-disposition"] ?? "";
    final filenameMatch = RegExp(r'filename="?([^"]+)"?').firstMatch(
      contentDisposition,
    );
    final fallbackExtension =
        format == ExportFormat.markdown ? "md" : format.apiValue;
    final filename = filenameMatch?.group(1) ??
        "generation-$generationId.$fallbackExtension";

    return ExportedFile(
      filename: filename,
      bytes: response.bodyBytes,
      contentType:
          response.headers["content-type"] ?? "application/octet-stream",
    );
  }

  Map<String, String> _headers(String apiKey, {bool withJson = false}) {
    return {
      "Authorization": "Bearer $apiKey",
      if (withJson) "Content-Type": "application/json",
    };
  }

  Map<String, String> _jsonHeaders() {
    return {"Content-Type": "application/json"};
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw ApiException(
        "Backend yanıt vermedi. API servisinin çalıştığını ve bağlantı adresinin doğru olduğunu kontrol edin.",
      );
    } on SocketException {
      throw ApiException(
        "Backend bağlantısı kurulamadı. Aynı ağda olduğunuzdan ve API adresinin doğru olduğundan emin olun.",
      );
    } on http.ClientException {
      throw ApiException(
        "Backend bağlantısı kurulamadı. API servisinin açık olduğundan emin olun.",
      );
    }
  }

  T _parseJsonResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic> json) parser,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessageFromResponse(
          response,
          fallback: "İstek tamamlanamadı.",
        ),
      );
    }

    final responseBody = _decodeJsonBody(response);
    return parser(responseBody);
  }

  void _ensureSuccessfulResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessageFromResponse(
          response,
          fallback: "İstek tamamlanamadı.",
        ),
      );
    }
  }

  Map<String, dynamic> _decodeJsonBody(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException("Backend beklenmeyen bir yanıt döndürdü.");
    }
  }

  String _errorMessageFromResponse(
    http.Response response, {
    required String fallback,
  }) {
    String? detail;

    try {
      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      detail = responseBody["detail"] as String?;
    } catch (_) {
      detail = null;
    }

    return _localizeApiError(detail, response.statusCode, fallback);
  }

  String _localizeApiError(String? detail, int statusCode, String fallback) {
    if (detail == null || detail.isEmpty) {
      return "$fallback Durum kodu: $statusCode.";
    }

    if (detail.startsWith("Gemini generation failed:")) {
      return "Gemini yanıtı alınamadı. Lütfen bağlantıyı kontrol edip tekrar deneyin.";
    }

    if (detail.contains("GEMINI_API_KEY is empty")) {
      return "Gemini API key bulunamadı. Backend ortam ayarlarını kontrol edin.";
    }

    const knownMessages = {
      "Invalid or inactive API key": "Geçersiz veya pasif erişim anahtarı.",
      "Generation not found": "Üretim bulunamadı.",
      "This export format is available for premium plans only":
          "Bu export formatı yalnızca Premium planda kullanılabilir.",
      "Premium plan required":
          "Bu özellik yalnızca Premium kullanıcılar için kullanılabilir.",
      "Custom templates are available for Premium plan users only.":
          "Custom Template özelliği yalnızca Premium kullanıcılar için kullanılabilir.",
      "Template-based generation is available for Premium plan users only.":
          "Template ile üretim yalnızca Premium kullanıcılar için kullanılabilir.",
      "Template not found or access denied.":
          "Template bulunamadı veya bu anahtar ile erişilemez.",
      "Monthly usage limit exceeded":
          "Aylık kullanım limitiniz doldu. Premium plan veya yeni bir dönem gerekir.",
      "Batch generation is available for Premium plan users only.":
          "Batch Generate yalnızca Premium plan kullanıcıları için kullanılabilir.",
    };

    if (knownMessages.containsKey(detail)) {
      return knownMessages[detail]!;
    }

    if (statusCode == 401) {
      return "Erişim anahtarı doğrulanamadı. Anahtarı kontrol edip tekrar deneyin.";
    }

    if (statusCode == 422) {
      return "Girilen bilgiler eksik veya hatalı. Form alanlarını kontrol edin.";
    }

    if (statusCode == 403) {
      return "Bu işlem için Premium erişim gerekir.";
    }

    if (statusCode == 429) {
      return "Aylık kullanım limitiniz doldu.";
    }

    if (statusCode >= 500) {
      return "Backend tarafında bir sorun oluştu. API servisinin durumunu kontrol edin.";
    }

    return detail;
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExportedFile {
  ExportedFile({
    required this.filename,
    required this.bytes,
    required this.contentType,
  });

  final String filename;
  final Uint8List bytes;
  final String contentType;
}
