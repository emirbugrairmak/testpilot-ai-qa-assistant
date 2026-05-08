class AuthValidationResponse {
  const AuthValidationResponse({
    required this.valid,
    required this.plan,
    required this.ownerName,
    required this.monthlyLimit,
    required this.usageCount,
    required this.remaining,
    required this.usageResetsAt,
  });

  final bool valid;
  final String plan;
  final String ownerName;
  final int monthlyLimit;
  final int usageCount;
  final int remaining;
  final String usageResetsAt;

  factory AuthValidationResponse.fromJson(Map<String, dynamic> json) {
    return AuthValidationResponse(
      valid: json["valid"] as bool? ?? false,
      plan: json["plan"] as String? ?? "free",
      ownerName: json["owner_name"] as String? ?? "",
      monthlyLimit: json["monthly_limit"] as int? ?? 0,
      usageCount: json["usage_count"] as int? ?? 0,
      remaining: json["remaining"] as int? ?? 0,
      usageResetsAt: json["usage_resets_at"] as String? ?? "",
    );
  }
}

class AccessKeyCreateResponse {
  const AccessKeyCreateResponse({
    required this.accessKey,
    required this.plan,
    required this.ownerName,
    required this.issuedVia,
    required this.monthlyLimit,
    required this.usageCount,
    required this.remaining,
    required this.usageResetsAt,
    required this.createdAt,
  });

  final String accessKey;
  final String plan;
  final String ownerName;
  final String issuedVia;
  final int monthlyLimit;
  final int usageCount;
  final int remaining;
  final String usageResetsAt;
  final String createdAt;

  factory AccessKeyCreateResponse.fromJson(Map<String, dynamic> json) {
    return AccessKeyCreateResponse(
      accessKey: json["access_key"] as String? ?? "",
      plan: json["plan"] as String? ?? "free",
      ownerName: json["owner_name"] as String? ?? "",
      issuedVia: json["issued_via"] as String? ?? "",
      monthlyLimit: json["monthly_limit"] as int? ?? 0,
      usageCount: json["usage_count"] as int? ?? 0,
      remaining: json["remaining"] as int? ?? 0,
      usageResetsAt: json["usage_resets_at"] as String? ?? "",
      createdAt: json["created_at"] as String? ?? "",
    );
  }
}
