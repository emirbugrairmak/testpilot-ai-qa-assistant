import "package:flutter/material.dart";

import "../models/generation_models.dart";
import "../services/api_service.dart";
import "../widgets/primary_action_button.dart";
import "../widgets/section_card.dart";

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({
    super.key,
    required this.apiService,
    required this.apiKey,
    required this.initialMode,
    required this.onBack,
    required this.onOpenHistory,
    required this.onOpenSettings,
    required this.onOpenResult,
  });

  final ApiService apiService;
  final String apiKey;
  final GenerationMode initialMode;
  final VoidCallback onBack;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;
  final void Function(GenerationDetail detail) onOpenResult;

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  late GenerationMode _mode;

  final TextEditingController _featureIdeaController = TextEditingController();
  final TextEditingController _userStoryController = TextEditingController();
  final TextEditingController _acceptanceCriteriaController =
      TextEditingController();
  final TextEditingController _bugTitleController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _actualResultController = TextEditingController();
  final TextEditingController _expectedResultController =
      TextEditingController();
  final TextEditingController _environmentController = TextEditingController();

  String _severity = "Medium";
  bool _isSubmitting = false;
  String? _errorMessage;
  GenerationResult? _result;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _featureIdeaController.dispose();
    _userStoryController.dispose();
    _acceptanceCriteriaController.dispose();
    _bugTitleController.dispose();
    _stepsController.dispose();
    _actualResultController.dispose();
    _expectedResultController.dispose();
    _environmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final payload = _buildPayload();
      final result = await widget.apiService.generate(
        apiKey: widget.apiKey,
        payload: payload,
      );

      if (!mounted) {
        return;
      }

      final detail = GenerationDetail.fromGenerate(
        input: payload,
        result: result,
      );

      setState(() {
        _result = result;
      });

      widget.onOpenResult(detail);
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
          _isSubmitting = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildPayload() {
    switch (_mode) {
      case GenerationMode.modA:
        return {
          "mode": _mode.apiValue,
          "feature_idea": _featureIdeaController.text.trim(),
        };
      case GenerationMode.modB:
        return {
          "mode": _mode.apiValue,
          "user_story": _userStoryController.text.trim(),
          "acceptance_criteria": _acceptanceCriteriaController.text.trim(),
        };
      case GenerationMode.bugReport:
        return {
          "mode": _mode.apiValue,
          "title": _bugTitleController.text.trim(),
          "steps_to_reproduce": _stepsController.text
              .split("\n")
              .map((step) => step.trim())
              .where((step) => step.isNotEmpty)
              .toList(),
          "actual_result": _actualResultController.text.trim(),
          "expected_result": _expectedResultController.text.trim(),
          "environment": _environmentController.text.trim(),
          "severity": _severity,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_mode.label),
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: "History",
            onPressed: widget.onOpenHistory,
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: "Settings",
            onPressed: widget.onOpenSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: "Mode",
            child: SegmentedButton<GenerationMode>(
              segments: GenerationMode.values
                  .map(
                    (mode) => ButtonSegment<GenerationMode>(
                      value: mode,
                      label: Text(mode.label),
                    ),
                  )
                  .toList(),
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() {
                  _mode = selection.first;
                  _result = null;
                  _errorMessage = null;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: "Input",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildFormFields(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                const SizedBox(height: 20),
                if (_isSubmitting) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                ],
                PrimaryActionButton(
                  label: "Generate",
                  icon: Icons.play_arrow_rounded,
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          _submit();
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: "Output preview",
            child: _buildResultPreview(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormFields() {
    switch (_mode) {
      case GenerationMode.modA:
        return [
          TextField(
            controller: _featureIdeaController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: "Feature idea",
              hintText: "User login with email and password",
            ),
          ),
        ];
      case GenerationMode.modB:
        return [
          TextField(
            controller: _userStoryController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: "User story",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _acceptanceCriteriaController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: "Acceptance criteria",
            ),
          ),
        ];
      case GenerationMode.bugReport:
        return [
          TextField(
            controller: _bugTitleController,
            decoration: const InputDecoration(labelText: "Title"),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _severity,
            items: const [
              DropdownMenuItem(value: "Critical", child: Text("Critical")),
              DropdownMenuItem(value: "High", child: Text("High")),
              DropdownMenuItem(value: "Medium", child: Text("Medium")),
              DropdownMenuItem(value: "Low", child: Text("Low")),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _severity = value;
              });
            },
            decoration: const InputDecoration(labelText: "Severity"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stepsController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: "Steps to reproduce",
              hintText: "One step per line",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _actualResultController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: "Actual result"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _expectedResultController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: "Expected result"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _environmentController,
            decoration: const InputDecoration(labelText: "Environment"),
          ),
        ];
    }
  }

  Widget _buildResultPreview(BuildContext context) {
    final theme = Theme.of(context);

    if (_result == null) {
      return Text(
        "Generated output will appear here after a successful request.",
        style: theme.textTheme.bodyMedium,
      );
    }

    if (_result!.bugReport != null) {
      final bug = _result!.bugReport!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bug.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(bug.summary),
          const SizedBox(height: 12),
          Text("Severity: ${bug.severity}"),
          Text("Priority: ${bug.priority}"),
          Text("Environment: ${bug.environment}"),
          const SizedBox(height: 12),
          Text(
            "Steps",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...bug.steps.map((step) => Text("• $step")),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_result!.userStory != null) ...[
          Text(
            "User story",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(_result!.userStory!),
          const SizedBox(height: 12),
        ],
        if (_result!.acceptanceCriteria.isNotEmpty) ...[
          Text(
            "Acceptance criteria",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ..._result!.acceptanceCriteria
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text("• $item"),
                  )),
          const SizedBox(height: 12),
        ],
        Text(
          "Test cases",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ..._result!.testCases.take(4).map(
              (testCase) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
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
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Priority: ${testCase.priority}"),
                      const SizedBox(height: 4),
                      Text(testCase.expectedResult),
                    ],
                  ),
                ),
              ),
            ),
        if (_result!.watermark != null) ...[
          const SizedBox(height: 12),
          Text(
            _result!.watermark!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
