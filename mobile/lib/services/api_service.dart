import "dart:convert";

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
    final response = await http.get(
      Uri.parse("$baseUrl/api/v1/history"),
      headers: _headers(apiKey),
    );

    return _parseJsonResponse(
      response,
      (json) => HistoryListResponse.fromJson(json),
    );
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
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
