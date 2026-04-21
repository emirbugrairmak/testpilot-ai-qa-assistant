class UsageSummary {
  const UsageSummary({
    required this.plan,
    required this.monthlyLimit,
    required this.usageCount,
    required this.remaining,
    required this.usageResetAt,
  });

  final String plan;
  final int monthlyLimit;
  final int usageCount;
  final int remaining;
  final String usageResetAt;

  factory UsageSummary.fromJson(Map<String, dynamic> json) {
    return UsageSummary(
      plan: json["plan"] as String? ?? "free",
      monthlyLimit: json["monthly_limit"] as int? ?? 0,
      usageCount: json["usage_count"] as int? ?? 0,
      remaining: json["remaining"] as int? ?? 0,
      usageResetAt: json["usage_reset_at"] as String? ?? "",
    );
  }
}
