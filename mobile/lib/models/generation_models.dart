enum GenerationMode { modA, modB, bugReport }

enum ExportFormat { json, markdown, pdf, csv, jira }

extension ExportFormatX on ExportFormat {
  String get apiValue {
    switch (this) {
      case ExportFormat.json:
        return "json";
      case ExportFormat.markdown:
        return "markdown";
      case ExportFormat.pdf:
        return "pdf";
      case ExportFormat.csv:
        return "csv";
      case ExportFormat.jira:
        return "jira";
    }
  }

  String get label {
    switch (this) {
      case ExportFormat.json:
        return "JSON";
      case ExportFormat.markdown:
        return "Markdown";
      case ExportFormat.pdf:
        return "PDF";
      case ExportFormat.csv:
        return "CSV";
      case ExportFormat.jira:
        return "Jira";
    }
  }
}

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
    required this.type,
    required this.priority,
    required this.preconditions,
    required this.steps,
    required this.expectedResult,
    required this.tags,
  });

  final String id;
  final String title;
  final String type;
  final String priority;
  final String preconditions;
  final List<String> steps;
  final String expectedResult;
  final List<String> tags;

  factory TestCaseItem.fromJson(Map<String, dynamic> json) {
    return TestCaseItem(
      id: json["id"] as String? ?? "",
      title: json["title"] as String? ?? "",
      type: json["type"] as String? ?? "",
      priority: json["priority"] as String? ?? "",
      preconditions: json["preconditions"] as String? ?? "",
      steps: (json["steps"] as List<dynamic>? ?? const [])
          .map((step) => step.toString())
          .toList(),
      expectedResult: json["expected_result"] as String? ?? "",
      tags: (json["tags"] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
    );
  }
}

class TestPlan {
  const TestPlan({
    required this.objective,
    required this.scope,
    required this.testTypes,
    required this.approach,
  });

  final String objective;
  final String scope;
  final List<String> testTypes;
  final String approach;

  factory TestPlan.fromJson(Map<String, dynamic> json) {
    return TestPlan(
      objective: json["objective"] as String? ?? "",
      scope: json["scope"] as String? ?? "",
      testTypes: (json["test_types"] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      approach: json["approach"] as String? ?? "",
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
    this.testPlan,
    this.testCases = const [],
    this.tags = const [],
    this.markdown,
    this.watermark,
    this.bugReport,
  });

  final int generationId;
  final GenerationMode mode;
  final String createdAt;
  final String? userStory;
  final List<String> acceptanceCriteria;
  final TestPlan? testPlan;
  final List<TestCaseItem> testCases;
  final List<String> tags;
  final String? markdown;
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
      acceptanceCriteria:
          rawAcceptanceCriteria.map((item) => item.toString()).toList(),
      testPlan: json["test_plan"] is Map<String, dynamic>
          ? TestPlan.fromJson(json["test_plan"] as Map<String, dynamic>)
          : null,
      testCases: rawTestCases
          .map((item) => TestCaseItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      tags: (json["tags"] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      markdown: json["markdown"] as String?,
      watermark: json["watermark"] as String?,
      bugReport: json["bug_report"] is Map<String, dynamic>
          ? BugReportOutput.fromJson(
              json["bug_report"] as Map<String, dynamic>,
            )
          : null,
    );
  }

  GenerationResult copyWith({
    int? generationId,
    GenerationMode? mode,
    String? createdAt,
    String? userStory,
    List<String>? acceptanceCriteria,
    TestPlan? testPlan,
    List<TestCaseItem>? testCases,
    List<String>? tags,
    String? markdown,
    String? watermark,
    BugReportOutput? bugReport,
  }) {
    return GenerationResult(
      generationId: generationId ?? this.generationId,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      userStory: userStory ?? this.userStory,
      acceptanceCriteria: acceptanceCriteria ?? this.acceptanceCriteria,
      testPlan: testPlan ?? this.testPlan,
      testCases: testCases ?? this.testCases,
      tags: tags ?? this.tags,
      markdown: markdown ?? this.markdown,
      watermark: watermark ?? this.watermark,
      bugReport: bugReport ?? this.bugReport,
    );
  }
}

class GenerationDetail {
  const GenerationDetail({
    required this.generationId,
    required this.mode,
    required this.input,
    required this.output,
    required this.markdown,
    required this.createdAt,
  });

  final int generationId;
  final GenerationMode mode;
  final Map<String, dynamic> input;
  final GenerationResult output;
  final String markdown;
  final String createdAt;

  factory GenerationDetail.fromJson(Map<String, dynamic> json) {
    final outputJson = (json["output"] as Map<String, dynamic>? ??
        <String, dynamic>{})
      ..putIfAbsent("generation_id", () => json["generation_id"]);
    outputJson.putIfAbsent("markdown", () => json["markdown"]);

    return GenerationDetail(
      generationId: json["generation_id"] as int? ?? 0,
      mode: generationModeFromApi(json["mode"] as String? ?? "mod_a"),
      input: (json["input"] as Map<String, dynamic>? ?? <String, dynamic>{}),
      output: GenerationResult.fromJson(outputJson),
      markdown: json["markdown"] as String? ?? "",
      createdAt: json["created_at"] as String? ?? "",
    );
  }

  factory GenerationDetail.fromGenerate({
    required Map<String, dynamic> input,
    required GenerationResult result,
  }) {
    return GenerationDetail(
      generationId: result.generationId,
      mode: result.mode,
      input: input,
      output: result,
      markdown: result.markdown ?? "",
      createdAt: result.createdAt,
    );
  }

  GenerationDetail copyWith({
    int? generationId,
    GenerationMode? mode,
    Map<String, dynamic>? input,
    GenerationResult? output,
    String? markdown,
    String? createdAt,
  }) {
    return GenerationDetail(
      generationId: generationId ?? this.generationId,
      mode: mode ?? this.mode,
      input: input ?? this.input,
      output: output ?? this.output,
      markdown: markdown ?? this.markdown,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
