class TemplateItem {
  const TemplateItem({
    required this.id,
    required this.name,
    required this.promptText,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String promptText;
  final String createdAt;
  final String updatedAt;

  factory TemplateItem.fromJson(Map<String, dynamic> json) {
    return TemplateItem(
      id: json["id"] as int? ?? 0,
      name: json["name"] as String? ?? "",
      promptText: json["prompt_text"] as String? ?? "",
      createdAt: json["created_at"] as String? ?? "",
      updatedAt: json["updated_at"] as String? ?? "",
    );
  }
}

class TemplateListResponse {
  const TemplateListResponse({
    required this.items,
    required this.count,
  });

  final List<TemplateItem> items;
  final int count;

  factory TemplateListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json["items"] as List<dynamic>? ?? const [];

    return TemplateListResponse(
      items: rawItems
          .map((item) => TemplateItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      count: json["count"] as int? ?? 0,
    );
  }
}
