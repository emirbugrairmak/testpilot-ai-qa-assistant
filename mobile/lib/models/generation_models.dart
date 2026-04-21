enum GenerationMode { modA, modB, bugReport }

extension GenerationModeX on GenerationMode {
  String get apiValue {
    switch (this) {
      case GenerationMode.modA:
        return "mod_a";
      case GenerationMode.modB:
        return "mod_b";
      case GenerationMode.bugReport:
        return "bug_report";
    }
  }

  String get label {
    switch (this) {
      case GenerationMode.modA:
        return "Mod A";
      case GenerationMode.modB:
        return "Mod B";
      case GenerationMode.bugReport:
        return "Bug Report";
    }
  }
}

GenerationMode generationModeFromApi(String value) {
  switch (value) {
    case "mod_b":
      return GenerationMode.modB;
    case "bug_report":
      return GenerationMode.bugReport;
    case "mod_a":
    default:
      return GenerationMode.modA;
  }
}

class TestCaseItem {
  const TestCaseItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.expectedResult,
  });

  final String id;
  final String title;
  final String priority;
  final String expectedResult;

  factory TestCaseItem.fromJson(Map<String, dynamic> json) {
    return TestCaseItem(
      id: json["id"] as String? ?? "",
      title: json["title"] as String? ?? "",
      priority: json["priority"] as String? ?? "",
      expectedResult: json["expected_result"] as String? ?? "",
    );
  }
}

class BugReportOutput {
  const BugReportOutput({
    required this.title,
    required this.summary,
    required this.severity,
    required this.priority,
    required this.environment,
    required this.steps,
    required this.actualResult,
    required this.expectedResult,
  });

  final String title;
  final String summary;
  final String severity;
  final String priority;
  final String environment;
  final List<String> steps;
  final String actualResult;
  final String expectedResult;

  factory BugReportOutput.fromJson(Map<String, dynamic> json) {
    return BugReportOutput(
      title: json["title"] as String? ?? "",
      summary: json["summary"] as String? ?? "",
      severity: json["severity"] as String? ?? "",
      priority: json["priority"] as String? ?? "",
      environment: json["environment"] as String? ?? "",
      steps: (json["steps_to_reproduce"] as List<dynamic>? ?? const [])
          .map((step) => step.toString())
          .toList(),
      actualResult: json["actual_result"] as String? ?? "",
      expectedResult: json["expected_result"] as String? ?? "",
    );
  }
}

class GenerationResult {
  const GenerationResult({
    required this.generationId,
    required this.mode,
    required this.createdAt,
    this.userStory,
    this.acceptanceCriteria = const [],
    this.testCases = const [],
    this.watermark,
    this.bugReport,
  });

  final int generationId;
  final GenerationMode mode;
  final String createdAt;
  final String? userStory;
  final List<String> acceptanceCriteria;
  final List<TestCaseItem> testCases;
  final String? watermark;
  final BugReportOutput? bugReport;

  factory GenerationResult.fromJson(Map<String, dynamic> json) {
    final rawAcceptanceCriteria =
        json["acceptance_criteria"] as List<dynamic>? ?? const [];
    final rawTestCases = json["test_cases"] as List<dynamic>? ?? const [];

    return GenerationResult(
      generationId: json["generation_id"] as int? ?? 0,
      mode: generationModeFromApi(json["mode"] as String? ?? "mod_a"),
      createdAt: json["created_at"] as String? ?? "",
      userStory: json["user_story"] as String?,
      acceptanceCriteria: rawAcceptanceCriteria
          .map((item) => item.toString())
          .toList(),
      testCases: rawTestCases
          .map((item) => TestCaseItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      watermark: json["watermark"] as String?,
      bugReport: json["bug_report"] is Map<String, dynamic>
          ? BugReportOutput.fromJson(
              json["bug_report"] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
