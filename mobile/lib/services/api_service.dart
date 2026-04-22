import "dart:convert";
import "dart:typed_data";

import "package:http/http.dart" as http;

import "../models/auth_models.dart";
import "../models/generation_models.dart";
import "../models/history_models.dart";
import "../models/usage_models.dart";

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  Future<AuthValidationResponse> validateApiKey(String apiKey) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/v1/auth/validate"),
      headers: _headers(apiKey),
    );

    return _parseJsonResponse(
      response,
      (json) => AuthValidationResponse.fromJson(json),
    );
  }

  Future<UsageSummary> fetchUsage(String apiKey) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/v1/usage"),
      headers: _headers(apiKey),
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

    final response = await http.get(
      uri,
      headers: _headers(apiKey),
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
    final response = await http.get(
      Uri.parse("$baseUrl/api/v1/history/$generationId"),
      headers: _headers(apiKey),
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
    final response = await http.delete(
      Uri.parse("$baseUrl/api/v1/history/$generationId"),
      headers: _headers(apiKey),
    );

    _ensureSuccessfulResponse(response);
  }

  Future<GenerationResult> generate({
    required String apiKey,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/v1/generate"),
      headers: _headers(apiKey, withJson: true),
      body: jsonEncode(payload),
    );

    return _parseJsonResponse(
      response,
      (json) => GenerationResult.fromJson(json),
    );
  }

  Future<ExportedFile> exportGeneration({
    required String apiKey,
    required int generationId,
    required ExportFormat format,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/v1/export/$generationId/${format.apiValue}"),
      headers: _headers(apiKey),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      throw ApiException(
        responseBody["detail"] as String? ??
            "Export failed with status ${response.statusCode}.",
      );
    }

    final contentDisposition = response.headers["content-disposition"] ?? "";
    final filenameMatch = RegExp(r'filename="?([^"]+)"?').firstMatch(
      contentDisposition,
    );
    final filename = filenameMatch?.group(1) ??
        "testpilot-generation-$generationId.${format.apiValue}";

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

  T _parseJsonResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic> json) parser,
  ) {
    final responseBody = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        responseBody["detail"] as String? ??
            "Request failed with status ${response.statusCode}.",
      );
    }

    return parser(responseBody);
  }

  void _ensureSuccessfulResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      throw ApiException(
        responseBody["detail"] as String? ??
            "Request failed with status ${response.statusCode}.",
      );
    }
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
