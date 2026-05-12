import "dart:io";

import "package:flutter/material.dart";
import "package:path_provider/path_provider.dart";
import "package:share_plus/share_plus.dart";

import "../models/auth_models.dart";
import "../models/generation_models.dart";
import "../services/api_service.dart";
import "../utils/constants.dart";
import "../utils/date_formatters.dart";
import "../widgets/plan_badge.dart";
import "../widgets/section_card.dart";

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.apiService,
    required this.apiKey,
    required this.authResponse,
    required this.generationId,
    required this.onBack,
    this.initialDetail,
  });

  final ApiService apiService;
  final String apiKey;
  final AuthValidationResponse authResponse;
  final int generationId;
  final VoidCallback onBack;
  final GenerationDetail? initialDetail;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  GenerationDetail? _detail;
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;
  String? _exportMessage;

  bool get _isPremium => widget.authResponse.plan.toLowerCase() == "premium";

  @override
  void initState() {
    super.initState();
    _detail = widget.initialDetail;
    _loadDetail(forceRefresh: _detail == null || _detail!.markdown.isEmpty);
  }

  Future<void> _loadDetail({bool forceRefresh = true}) async {
    if (!forceRefresh && _detail != null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await widget.apiService.fetchHistoryDetail(
        apiKey: widget.apiKey,
        generationId: widget.generationId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _export(ExportFormat format) async {
    final isPremium = widget.authResponse.plan.toLowerCase() == "premium";
    final requiresPremium = _requiresPremium(format);
    final label = _labelForFormat(format, mode: _detail?.mode);

    if (requiresPremium && !isPremium) {
      _showSnackBar(
        "$label yalnızca Premium planda kullanılabilir.",
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _exportMessage = null;
    });

    try {
      final file = await widget.apiService.exportGeneration(
        apiKey: widget.apiKey,
        generationId: widget.generationId,
        format: format,
      );
      final tempDir = await getTemporaryDirectory();
      final path = "${tempDir.path}/${file.filename}";
      final outputFile = File(path);

      await outputFile.writeAsBytes(file.bytes, flush: true);

      await Share.shareXFiles(
        [XFile(path, mimeType: file.contentType)],
        text: "TestPilot export: $label",
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _exportMessage = "$label paylaşmaya hazır.";
      });
      _showSnackBar(_exportMessage!);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _exportMessage = error.toString();
      });
      _showSnackBar(_exportMessage!);
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sonuç"),
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: "Yenile",
            onPressed: _isLoading
                ? null
                : () {
                    _loadDetail();
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? _buildEmptyState(theme)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SectionCard(
                      title: "Özet",
                      trailing: PlanBadge(plan: widget.authResponse.plan),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Üretim #${detail.generationId}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Mod: ${detail.output.mode.label}\nOluşturulma: ${AppDateFormatters.formatDateTime(detail.createdAt)}",
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (detail.output.watermark != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                detail.output.watermark!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: "Girdi özeti",
                      child: _buildInputSummary(detail.input, theme),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: "Sonuç blokları",
                      child: _buildResultBlocks(detail, theme),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: "Export",
                      trailing: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : PlanBadge(plan: widget.authResponse.plan),
                      child: _buildExportSection(detail, theme),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildExportSection(GenerationDetail detail, ThemeData theme) {
    final advancedFormats = _formatsForMode(detail.mode)
        .where((format) => format != ExportFormat.pdf)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isPremium
              ? "Premium kullanıcılar temiz PDF export alabilir."
              : "Free kullanıcılar PDF export alabilir; çıktıda TestPilot Free watermark yer alır.",
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          "Paylaşım menüsünden Dosyalar'a kaydedebilirsiniz.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isExporting
              ? null
              : () {
                  _export(ExportFormat.pdf);
                },
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: const Text("PDF paylaş / kaydet"),
        ),
        if (advancedFormats.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              "Gelişmiş exportlar",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: advancedFormats
                      .map(
                          (format) => _buildExportButton(format, detail, theme))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
        if (_exportMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _exportMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExportButton(
    ExportFormat format,
    GenerationDetail detail,
    ThemeData theme,
  ) {
    final locked = _requiresPremium(format) && !_isPremium;
    final label = _labelForFormat(format, mode: detail.mode);

    return OutlinedButton.icon(
      onPressed: _isExporting
          ? null
          : () {
              _export(format);
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: locked ? AppColors.textSecondary : null,
        backgroundColor:
            locked ? AppColors.textSecondary.withValues(alpha: 0.05) : null,
        side: BorderSide(
          color: locked
              ? AppColors.textSecondary.withValues(alpha: 0.24)
              : theme.colorScheme.outline,
        ),
      ),
      icon: Icon(
        locked ? Icons.lock_rounded : _iconForFormat(format, mode: detail.mode),
        size: 18,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (locked) ...[
            const SizedBox(width: 6),
            _buildSmallBadge(
              "Premium",
              foreground: AppColors.accent,
              background: AppColors.accent.withValues(alpha: 0.10),
            ),
          ],
        ],
      ),
    );
  }

  List<ExportFormat> _formatsForMode(GenerationMode mode) {
    switch (mode) {
      case GenerationMode.modA:
      case GenerationMode.modB:
        return const [
          ExportFormat.json,
          ExportFormat.markdown,
          ExportFormat.pdf,
          ExportFormat.csv,
          ExportFormat.jira,
        ];
      case GenerationMode.bugReport:
        return const [
          ExportFormat.json,
          ExportFormat.markdown,
          ExportFormat.pdf,
          ExportFormat.jira,
        ];
    }
  }

  bool _requiresPremium(ExportFormat format) {
    return format == ExportFormat.csv || format == ExportFormat.jira;
  }

  String _labelForFormat(ExportFormat format, {GenerationMode? mode}) {
    switch (format) {
      case ExportFormat.json:
        return "JSON";
      case ExportFormat.markdown:
        return "Markdown";
      case ExportFormat.pdf:
        return "PDF";
      case ExportFormat.csv:
        return "TestRail CSV";
      case ExportFormat.jira:
        if (mode == GenerationMode.bugReport) {
          return "Jira Bug Draft";
        }
        return "Jira QA Task";
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Sonuç bulunamadı.",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputSummary(Map<String, dynamic> input, ThemeData theme) {
    final entries = input.entries
        .where((entry) => !_isBlankValue(entry.value))
        .map(
          (entry) => MapEntry(
            entry.key,
            _displayValue(entry.value),
          ),
        )
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (entries.isEmpty) {
      return Text(
        "Girdi özeti yok.",
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      _labelForInputKey(entry.key),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildBodyText(entry.value, theme),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _labelForInputKey(String key) {
    switch (key) {
      case "mode":
        return "Mod";
      case "feature_idea":
        return "Feature fikri";
      case "user_story":
        return "User Story";
      case "acceptance_criteria":
        return "AC";
      case "title":
        return "Başlık";
      case "summary":
        return "Özet";
      case "steps_to_reproduce":
        return "Adımlar";
      case "actual_result":
        return "Gerçek sonuç";
      case "expected_result":
        return "Beklenen sonuç";
      case "environment":
        return "Ortam";
      case "severity":
        return "Severity";
      default:
        return key;
    }
  }

  Widget _buildResultBlocks(GenerationDetail detail, ThemeData theme) {
    final result = detail.output;

    if (result.bugReport != null) {
      final bug = result.bugReport!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextBlock("Başlık", bug.title, theme),
          _buildTextBlock("Özet", bug.summary, theme),
          _buildTextBlock(
            "Severity / Priority",
            "${bug.severity} / ${bug.priority}",
            theme,
          ),
          _buildTextBlock("Ortam", bug.environment, theme),
          _buildListBlock("Adımlar", bug.steps, theme),
          _buildTextBlock("Gerçek sonuç", bug.actualResult, theme),
          _buildTextBlock("Beklenen sonuç", bug.expectedResult, theme),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.userStory != null)
          _buildTextBlock("User Story", result.userStory!, theme),
        if (result.acceptanceCriteria.isNotEmpty)
          _buildAcceptanceCriteriaBlock(
            result.acceptanceCriteria,
            theme,
          ),
        if (result.testPlan != null) ...[
          _buildTextBlock("Amaç", result.testPlan!.objective, theme),
          _buildTextBlock("Kapsam", result.testPlan!.scope, theme),
          _buildListBlock("Test türleri", result.testPlan!.testTypes, theme),
          _buildTextBlock("Yaklaşım", result.testPlan!.approach, theme),
        ],
        if (result.testCases.isNotEmpty) ...[
          Text(
            "Test Case’ler",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...result.testCases.map(
            (testCase) => _buildTestCaseCard(testCase, theme),
          ),
        ],
      ],
    );
  }

  Widget _buildTextBlock(String label, String value, ThemeData theme) {
    if (_isBlankValue(value)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _buildBodyText(value, theme),
        ],
      ),
    );
  }

  Widget _buildListBlock(String label, List<String> items, ThemeData theme) {
    final visibleItems = items.where((item) => !_isBlankValue(item)).toList();

    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...visibleItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildBodyText("• $item", theme),
              )),
        ],
      ),
    );
  }

  Widget _buildAcceptanceCriteriaBlock(
    List<String> items,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "AC / Acceptance Criteria",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildAcceptanceCriteriaItem(item, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptanceCriteriaItem(String item, ThemeData theme) {
    final parts = _acceptanceCriteriaParts(item);

    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parts.asMap().entries.map((entry) {
          final isLast = entry.key == parts.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: _buildAcceptanceCriteriaRow(entry.value, theme),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAcceptanceCriteriaRow(
    MapEntry<String, String> part,
    ThemeData theme,
  ) {
    final label = part.key;

    if (label.isEmpty) {
      return _buildBodyText(part.value, theme);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: _buildBodyText(part.value, theme),
        ),
      ],
    );
  }

  Widget _buildTestCaseCard(TestCaseItem testCase, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTestCaseHeader(testCase, theme),
          const SizedBox(height: 12),
          _buildLabeledValue("Type", testCase.type, theme),
          _buildPriorityField(testCase.priority, theme),
          _buildLabeledValue("Preconditions", testCase.preconditions, theme),
          _buildStepsBlock(testCase.steps, theme),
          _buildLabeledValue(
            "Beklenen sonuç",
            testCase.expectedResult,
            theme,
          ),
          if (testCase.tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "Tags",
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: testCase.tags
                  .map(
                    (tag) => _buildSmallBadge(
                      tag,
                      foreground: const Color(0xFF175CD3),
                      background: const Color(0xFFEFF8FF),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestCaseHeader(TestCaseItem testCase, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                testCase.id.isEmpty ? "Test Case" : testCase.id,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              _buildBodyText(
                testCase.title.isEmpty ? "Başlıksız test case" : testCase.title,
                theme,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _buildPriorityBadge(testCase.priority),
      ],
    );
  }

  Widget _buildLabeledValue(String label, String value, ThemeData theme) {
    if (_isBlankValue(value)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          _buildBodyText(value, theme),
        ],
      ),
    );
  }

  Widget _buildPriorityField(String priority, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Priority",
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _buildPriorityBadge(priority),
        ],
      ),
    );
  }

  Widget _buildStepsBlock(List<String> steps, ThemeData theme) {
    final visibleSteps = steps.where((step) => !_isBlankValue(step)).toList();

    if (visibleSteps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Steps",
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ...visibleSteps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: _buildBodyText(
                    "${entry.key + 1}. ${entry.value}",
                    theme,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final normalized = priority.trim().toUpperCase();

    switch (normalized) {
      case "P0":
        return _buildSmallBadge(
          "P0",
          foreground: const Color(0xFFB42318),
          background: const Color(0xFFFEE4E2),
        );
      case "P1":
        return _buildSmallBadge(
          "P1",
          foreground: const Color(0xFFB54708),
          background: const Color(0xFFFEF0C7),
        );
      default:
        return _buildSmallBadge(
          normalized.isEmpty ? "P2" : normalized,
          foreground: const Color(0xFF344054),
          background: const Color(0xFFF2F4F7),
        );
    }
  }

  Widget _buildSmallBadge(
    String label, {
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBodyText(
    String value,
    ThemeData theme, {
    TextStyle? style,
  }) {
    final effectiveStyle = style ?? theme.textTheme.bodyMedium;

    if (_isPremium) {
      return SelectableText(value, style: effectiveStyle);
    }

    return Text(value, style: effectiveStyle);
  }

  List<MapEntry<String, String>> _acceptanceCriteriaParts(String item) {
    final cleanItem =
        _stripLeadingBullet(item).replaceAll(RegExp(r"\s+"), " ").trim();

    if (cleanItem.isEmpty) {
      return const [];
    }

    final markerPattern = RegExp(
      r"\b(Given|When|Then|And|But)\b",
      caseSensitive: false,
    );
    final matches = markerPattern.allMatches(cleanItem).toList();

    if (matches.isEmpty) {
      return [MapEntry("", cleanItem)];
    }

    final leadingText = cleanItem.substring(0, matches.first.start).trim();
    final parts = <MapEntry<String, String>>[
      if (leadingText.isNotEmpty) MapEntry("", leadingText),
    ];

    for (var index = 0; index < matches.length; index += 1) {
      final match = matches[index];
      final nextStart = index + 1 < matches.length
          ? matches[index + 1].start
          : cleanItem.length;
      final text = cleanItem.substring(match.start, nextStart).trim();

      if (text.isNotEmpty) {
        parts.add(_gherkinPart(text));
      }
    }

    return parts;
  }

  String _stripLeadingBullet(String value) {
    return value.replaceFirst(RegExp(r"^\s*(?:[-*•]\s+|\d+[.)]\s*)"), "");
  }

  MapEntry<String, String> _gherkinPart(String value) {
    final normalized = value.replaceFirstMapped(
      RegExp(r"^(given|when|then|and|but)\b", caseSensitive: false),
      (match) {
        final word = match.group(1)!.toLowerCase();

        switch (word) {
          case "given":
            return "Given";
          case "when":
            return "When";
          case "then":
            return "Then";
          case "and":
            return "And";
          case "but":
            return "But";
          default:
            return match.group(1)!;
        }
      },
    );

    final separator = normalized.indexOf(" ");
    if (separator == -1) {
      return MapEntry(normalized, "");
    }

    return MapEntry(
      normalized.substring(0, separator),
      _stripLeadingPunctuation(normalized.substring(separator + 1)),
    );
  }

  String _stripLeadingPunctuation(String value) {
    return value.replaceFirst(RegExp(r"^\s*[:\-–]\s*"), "").trim();
  }

  bool _isBlankValue(dynamic value) {
    if (value == null) {
      return true;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized.isEmpty || normalized == "null";
    }

    if (value is Iterable) {
      return value.where((item) => !_isBlankValue(item)).isEmpty;
    }

    if (value is Map) {
      return value.values.where((item) => !_isBlankValue(item)).isEmpty;
    }

    return false;
  }

  String _displayValue(dynamic value) {
    if (value is Iterable) {
      return value
          .where((item) => !_isBlankValue(item))
          .map(_displayValue)
          .join("\n");
    }

    return value.toString().trim();
  }

  IconData _iconForFormat(ExportFormat format, {GenerationMode? mode}) {
    switch (format) {
      case ExportFormat.json:
        return Icons.data_object_rounded;
      case ExportFormat.markdown:
        return Icons.description_rounded;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf_rounded;
      case ExportFormat.csv:
        return Icons.table_chart_rounded;
      case ExportFormat.jira:
        if (mode == GenerationMode.bugReport) {
          return Icons.bug_report_rounded;
        }
        return Icons.assignment_turned_in_rounded;
    }
  }
}
