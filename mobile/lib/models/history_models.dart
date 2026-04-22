import "generation_models.dart";

class HistoryItem {
  const HistoryItem({
    required this.generationId,
    required this.mode,
    required this.outputSummary,
    required this.createdAt,
  });

  final int generationId;
  final GenerationMode mode;
  final String outputSummary;
  final String createdAt;

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      generationId: json["generation_id"] as int? ?? 0,
      mode: generationModeFromApi(json["mode"] as String? ?? "mod_a"),
      outputSummary: json["output_summary"] as String? ?? "",
      createdAt: json["created_at"] as String? ?? "",
    );
  }
}

class HistoryListResponse {
  const HistoryListResponse({
    required this.items,
    required this.count,
    required this.plan,
    this.limit,
  });

  final List<HistoryItem> items;
  final int count;
  final String plan;
  final int? limit;

  factory HistoryListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json["items"] as List<dynamic>? ?? const [];

    return HistoryListResponse(
      items: rawItems
          .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      count: json["count"] as int? ?? 0,
      plan: json["plan"] as String? ?? "free",
      limit: json["limit"] as int?,
    );
  }
}
