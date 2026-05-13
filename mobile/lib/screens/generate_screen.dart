import "package:flutter/material.dart";

import "../models/auth_models.dart";
import "../models/generation_models.dart";
import "../models/template_models.dart";
import "../services/api_service.dart";
import "../widgets/primary_action_button.dart";
import "../widgets/section_card.dart";

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({
    super.key,
    required this.apiService,
    required this.apiKey,
    required this.authResponse,
    required this.initialMode,
    required this.onBack,
    required this.onOpenHistory,
    required this.onOpenResult,
  });

  final ApiService apiService;
  final String apiKey;
  final AuthValidationResponse authResponse;
  final GenerationMode initialMode;
  final VoidCallback onBack;
  final VoidCallback onOpenHistory;
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
  bool _isLoadingTemplates = false;
  String? _errorMessage;
  String? _templateMessage;
  GenerationResult? _result;
  List<TemplateItem> _templates = const [];
  int? _selectedTemplateId;

  bool get _isPremium => widget.authResponse.plan.toLowerCase() == "premium";
  bool get _supportsTemplate => true;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (_isPremium) {
      _loadTemplates();
    }
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
          if (_selectedTemplateId != null) "template_id": _selectedTemplateId,
        };
      case GenerationMode.modB:
        return {
          "mode": _mode.apiValue,
          "user_story": _userStoryController.text.trim(),
          "acceptance_criteria": _acceptanceCriteriaController.text.trim(),
          if (_selectedTemplateId != null) "template_id": _selectedTemplateId,
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
          if (_selectedTemplateId != null) "template_id": _selectedTemplateId,
        };
    }
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoadingTemplates = true;
      _templateMessage = null;
    });

    try {
      final response = await widget.apiService.fetchTemplates(widget.apiKey);

      if (!mounted) {
        return;
      }

      setState(() {
        _templates = response.items;
        if (!_templates.any((template) => template.id == _selectedTemplateId)) {
          _selectedTemplateId = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _templateMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTemplates = false;
        });
      }
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: "Mod",
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
                  if (!_supportsTemplate) {
                    _selectedTemplateId = null;
                  }
                  _result = null;
                  _errorMessage = null;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: "Template",
            child: _buildTemplateSelector(context),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: _inputSectionTitle,
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
                  label: "Üret",
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
            title: "Çıktı önizleme",
            child: _buildResultPreview(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isPremium) {
      return Text(
        "Template, çıktının hangi teste odaklanacağını belirleyen yeniden kullanılabilir yönergedir. Premium kullanıcılar üretimlerde Template seçebilir.",
        style: theme.textTheme.bodyMedium,
      );
    }

    if (_isLoadingTemplates) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_templates.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Henüz Template yok. Dashboard üzerinden Templates ekranında oluşturabilirsiniz.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadTemplates,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Template listesini yenile"),
          ),
          if (_templateMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _templateMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int?>(
          key: ValueKey(_selectedTemplateId),
          initialValue: _selectedTemplateId,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text("Template kullanma"),
            ),
            ..._templates.map(
              (template) => DropdownMenuItem<int?>(
                value: template.id,
                child: Text(template.name),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTemplateId = value;
            });
          },
          decoration: const InputDecoration(
            labelText: "Template seçimi",
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Template seçerek çıktıyı güvenlik, edge case veya regresyon gibi belirli bir odağa yönlendirebilirsiniz.",
          style: theme.textTheme.bodySmall,
        ),
        if (_templateMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _templateMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
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
              labelText: "Özellik fikri",
              hintText: "Kullanıcı e-posta ve şifre ile giriş yapabilsin",
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
              labelText: "User Story",
              hintText:
                  "Bir kullanıcı olarak, hesabıma tekrar erişebilmek için şifremi sıfırlamak istiyorum.",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _acceptanceCriteriaController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: "AC",
              hintText:
                  "Şifre sıfırlama talebinde sıfırlama e-postası gönderilmelidir.",
            ),
          ),
        ];
      case GenerationMode.bugReport:
        return [
          TextField(
            controller: _bugTitleController,
            decoration: const InputDecoration(labelText: "Başlık"),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _severity,
            items: const [
              DropdownMenuItem(value: "Low", child: Text("Düşük")),
              DropdownMenuItem(value: "Medium", child: Text("Orta")),
              DropdownMenuItem(value: "High", child: Text("Yüksek")),
              DropdownMenuItem(value: "Critical", child: Text("Kritik")),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _severity = value;
              });
            },
            decoration: const InputDecoration(labelText: "Önem seviyesi"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stepsController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: "Yeniden üretme adımları",
              hintText: "Her satıra bir adım yazın",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _actualResultController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: "Gerçekleşen sonuç"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _expectedResultController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: "Beklenen sonuç"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _environmentController,
            decoration: const InputDecoration(labelText: "Ortam"),
          ),
        ];
    }
  }

  String get _inputSectionTitle {
    switch (_mode) {
      case GenerationMode.modA:
        return "Özellik fikri";
      case GenerationMode.modB:
        return "User Story ve AC";
      case GenerationMode.bugReport:
        return "Bug Report bilgileri";
    }
  }

  Widget _buildResultPreview(BuildContext context) {
    final theme = Theme.of(context);

    if (_result == null) {
      return Text(
        "Başarılı bir istekten sonra üretilen çıktı burada görünecek.",
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
          Text("Ortam: ${bug.environment}"),
          const SizedBox(height: 12),
          Text(
            "Adımlar",
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
            "User Story",
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
            "AC / Acceptance Criteria",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ..._result!.acceptanceCriteria.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text("• $item"),
              )),
          const SizedBox(height: 12),
        ],
        Text(
          "Test Case’ler",
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
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
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
