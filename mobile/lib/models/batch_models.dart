import "generation_models.dart";

class BatchGenerateResponse {
  const BatchGenerateResponse({
    required this.mode,
    required this.totalItems,
    required this.successCount,
    required this.failedCount,
    required this.results,
  });

  final GenerationMode mode;
  final int totalItems;
  final int successCount;
  final int failedCount;
  final List<BatchResultItem> results;

  factory BatchGenerateResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json["results"] as List<dynamic>? ?? const [];

    return BatchGenerateResponse(
      mode: generationModeFromApi(json["mode"] as String? ?? "mod_a"),
      totalItems: json["total_items"] as int? ?? 0,
      successCount: json["success_count"] as int? ?? 0,
      failedCount: json["failed_count"] as int? ?? 0,
      results: rawResults
          .map((item) => BatchResultItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BatchResultItem {
  const BatchResultItem({
    required this.index,
    required this.success,
    this.generationId,
    this.result,
    this.error,
  });

  final int index;
  final bool success;
  final int? generationId;
  final GenerationResult? result;
  final String? error;

  factory BatchResultItem.fromJson(Map<String, dynamic> json) {
    final rawResult = json["result"];
    final generationId = json["generation_id"] as int?;
    GenerationResult? parsedResult;

    if (rawResult is Map<String, dynamic>) {
      final resultJson = Map<String, dynamic>.from(rawResult);
      if (generationId != null) {
        resultJson.putIfAbsent("generation_id", () => generationId);
      }
      parsedResult = GenerationResult.fromJson(resultJson);
    }

    return BatchResultItem(
      index: json["index"] as int? ?? 0,
      success: json["success"] as bool? ?? false,
      generationId: generationId ?? parsedResult?.generationId,
      result: parsedResult,
      error: json["error"] as String?,
    );
  }
}
