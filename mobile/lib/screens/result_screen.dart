import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:path_provider/path_provider.dart";
import "package:share_plus/share_plus.dart";

import "../models/auth_models.dart";
import "../models/generation_models.dart";
import "../services/api_service.dart";
import "../utils/constants.dart";
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
    final requiresPremium =
        format == ExportFormat.csv || format == ExportFormat.jira;

    if (requiresPremium && !isPremium) {
      _showSnackBar("CSV and Jira exports are available on the premium plan.");
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
        text: "TestPilot export: ${format.label}",
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _exportMessage = "${format.label} export is ready to share.";
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
        title: const Text("Result"),
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
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
                      title: "Summary",
                      trailing: PlanBadge(plan: widget.authResponse.plan),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Generation #${detail.generationId}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Mode: ${detail.output.mode.label}\nCreated: ${detail.createdAt}",
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
                      title: "Input summary",
                      child: _buildInputSummary(detail.input, theme),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: "Result blocks",
                      child: _buildResultBlocks(detail, theme),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: "Markdown preview",
                      child: detail.markdown.isNotEmpty
                          ? MarkdownBody(data: detail.markdown)
                          : Text(
                              "Markdown preview is not available for this result.",
                              style: theme.textTheme.bodyMedium,
                            ),
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
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: ExportFormat.values
                                .map(
                                  (format) => OutlinedButton.icon(
                                    onPressed: _isExporting
                                        ? null
                                        : () {
                                            _export(format);
                                          },
                                    icon: Icon(_iconForFormat(format)),
                                    label: Text(format.label),
                                  ),
                                )
                                .toList(),
                          ),
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
                      ),
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Result is not available.",
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
    final entries = input.entries.toList();

    if (entries.isEmpty) {
      return Text(
        "No input summary available.",
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
                      entry.key,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value is List
                          ? (entry.value as List<dynamic>).join("\n")
                          : entry.value.toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildResultBlocks(GenerationDetail detail, ThemeData theme) {
    final result = detail.output;

    if (result.bugReport != null) {
      final bug = result.bugReport!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextBlock("Title", bug.title, theme),
          _buildTextBlock("Summary", bug.summary, theme),
          _buildTextBlock(
            "Severity / Priority",
            "${bug.severity} / ${bug.priority}",
            theme,
          ),
          _buildTextBlock("Environment", bug.environment, theme),
          _buildListBlock("Steps", bug.steps, theme),
          _buildTextBlock("Actual result", bug.actualResult, theme),
          _buildTextBlock("Expected result", bug.expectedResult, theme),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.userStory != null)
          _buildTextBlock("User story", result.userStory!, theme),
        if (result.acceptanceCriteria.isNotEmpty)
          _buildListBlock("Acceptance criteria", result.acceptanceCriteria, theme),
        if (result.testPlan != null) ...[
          _buildTextBlock("Objective", result.testPlan!.objective, theme),
          _buildTextBlock("Scope", result.testPlan!.scope, theme),
          _buildListBlock("Test types", result.testPlan!.testTypes, theme),
          _buildTextBlock("Approach", result.testPlan!.approach, theme),
        ],
        if (result.testCases.isNotEmpty) ...[
          Text(
            "Test cases",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...result.testCases.map(
            (testCase) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${testCase.id} • ${testCase.title}",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("Type: ${testCase.type}"),
                  Text("Priority: ${testCase.priority}"),
                  if (testCase.preconditions.isNotEmpty)
                    Text("Preconditions: ${testCase.preconditions}"),
                  if (testCase.steps.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...testCase.steps.map((step) => Text("• $step")),
                  ],
                  const SizedBox(height: 8),
                  Text(testCase.expectedResult),
                  if (testCase.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: testCase.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextBlock(String label, String value, ThemeData theme) {
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
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildListBlock(String label, List<String> items, ThemeData theme) {
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
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text("• $item", style: theme.textTheme.bodyMedium),
              )),
        ],
      ),
    );
  }

  IconData _iconForFormat(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return Icons.data_object_rounded;
      case ExportFormat.markdown:
        return Icons.description_rounded;
      case ExportFormat.csv:
        return Icons.table_chart_rounded;
      case ExportFormat.jira:
        return Icons.share_rounded;
    }
  }
}
