import "package:flutter/material.dart";

import "../models/auth_models.dart";
import "../models/batch_models.dart";
import "../models/generation_models.dart";
import "../models/template_models.dart";
import "../services/api_service.dart";
import "../widgets/plan_badge.dart";
import "../widgets/primary_action_button.dart";
import "../widgets/section_card.dart";

class BatchGenerateScreen extends StatefulWidget {
  const BatchGenerateScreen({
    super.key,
    required this.apiService,
    required this.apiKey,
    required this.authResponse,
    required this.onBack,
    required this.onOpenResult,
  });

  final ApiService apiService;
  final String apiKey;
  final AuthValidationResponse authResponse;
  final VoidCallback onBack;
  final void Function(GenerationDetail detail) onOpenResult;

  @override
  State<BatchGenerateScreen> createState() => _BatchGenerateScreenState();
}

class _BatchGenerateScreenState extends State<BatchGenerateScreen> {
  GenerationMode _mode = GenerationMode.modA;
  final List<_BatchInputControllers> _items = [_BatchInputControllers()];

  BatchGenerateResponse? _response;
  bool _isSubmitting = false;
  bool _isLoadingTemplates = false;
  String? _errorMessage;
  String? _templateMessage;
  List<TemplateItem> _templates = const [];
  int? _selectedTemplateId;

  bool get _isPremium => widget.authResponse.plan.toLowerCase() == "premium";

  @override
  void initState() {
    super.initState();
    if (_isPremium) {
      _loadTemplates();
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _response = null;
    });

    try {
      final response = await widget.apiService.batchGenerate(
        apiKey: widget.apiKey,
        payload: _buildPayload(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _response = response;
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
          _isSubmitting = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      "mode": _mode.apiValue,
      if (_selectedTemplateId != null) "template_id": _selectedTemplateId,
      "items": _items.map((item) {
        if (_mode == GenerationMode.modA) {
          return {
            "feature_idea": item.featureIdeaController.text.trim(),
          };
        }

        return {
          "user_story": item.userStoryController.text.trim(),
          "acceptance_criteria": item.acceptanceCriteriaController.text.trim(),
        };
      }).toList(),
    };
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

  String? _validateInputs() {
    if (!_isPremium) {
      return "Batch Generate yalnızca Premium kullanıcılar için kullanılabilir.";
    }

    if (_items.isEmpty) {
      return "En az bir batch öğesi ekleyin.";
    }

    for (var index = 0; index < _items.length; index += 1) {
      final item = _items[index];
      if (_mode == GenerationMode.modA &&
          item.featureIdeaController.text.trim().length < 5) {
        return "${index + 1}. öğe için en az 5 karakterlik özellik fikri girin.";
      }

      if (_mode == GenerationMode.modB) {
        if (item.userStoryController.text.trim().length < 10 ||
            item.acceptanceCriteriaController.text.trim().length < 10) {
          return "${index + 1}. öğe için en az 10 karakterlik User Story ve AC girin.";
        }
      }
    }

    return null;
  }

  void _addItem() {
    if (_items.length >= 10) {
      setState(() {
        _errorMessage = "Backend batch limiti en fazla 10 öğe destekler.";
      });
      return;
    }

    setState(() {
      _items.add(_BatchInputControllers());
      _errorMessage = null;
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) {
      setState(() {
        _errorMessage = "En az bir öğe kalmalı.";
      });
      return;
    }

    final removed = _items.removeAt(index);
    removed.dispose();

    setState(() {
      _response = null;
      _errorMessage = null;
    });
  }

  void _openBatchResult(BatchResultItem item) {
    final result = item.result;
    if (result == null) {
      return;
    }

    widget.onOpenResult(
      GenerationDetail.fromGenerate(
        input: _inputForIndex(item.index),
        result: result,
      ),
    );
  }

  Map<String, dynamic> _inputForIndex(int index) {
    if (index < 0 || index >= _items.length) {
      return {"mode": _mode.apiValue};
    }

    final item = _items[index];
    if (_mode == GenerationMode.modA) {
      return {
        "mode": _mode.apiValue,
        if (_selectedTemplateId != null) "template_id": _selectedTemplateId,
        "feature_idea": item.featureIdeaController.text.trim(),
      };
    }

    return {
      "mode": _mode.apiValue,
      if (_selectedTemplateId != null) "template_id": _selectedTemplateId,
      "user_story": item.userStoryController.text.trim(),
      "acceptance_criteria": item.acceptanceCriteriaController.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Batch Generate"),
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: "Plan durumu",
            trailing: PlanBadge(plan: widget.authResponse.plan),
            child: Text(
              _isPremium
                  ? "Premium plan ile Mod A ve Mod B için çoklu üretim yapabilirsiniz."
                  : "Batch Generate yalnızca Premium kullanıcılar için açıktır. Premium Access key ile giriş yapın.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (_isPremium) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: "Batch modu",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<GenerationMode>(
                    segments: const [
                      ButtonSegment<GenerationMode>(
                        value: GenerationMode.modA,
                        label: Text("Mod A"),
                      ),
                      ButtonSegment<GenerationMode>(
                        value: GenerationMode.modB,
                        label: Text("Mod B"),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _mode = selection.first;
                        _response = null;
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Bug Report için Batch Generate desteklenmiyor.",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: "Template",
              child: _buildTemplateSelector(theme),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: "Batch öğeleri",
              trailing: Text("${_items.length} / 10"),
              child: Column(
                children: [
                  ..._items.asMap().entries.map(
                        (entry) => _buildInputItem(
                          context: context,
                          index: entry.key,
                          item: entry.value,
                        ),
                      ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _addItem,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text("Öğe ekle"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isSubmitting) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ],
            PrimaryActionButton(
              label: "Batch Generate başlat",
              icon: Icons.playlist_play_rounded,
              onPressed: _isSubmitting ? null : _submit,
            ),
            if (_response != null) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: "Batch sonuçları",
                child: _buildResults(theme),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateSelector(ThemeData theme) {
    if (_isLoadingTemplates) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_templates.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Template seçerek tüm batch çıktısını güvenlik, edge case veya regresyon gibi belirli bir odağa yönlendirebilirsiniz.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "Henüz Template yok.",
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
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadTemplates,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Template listesini yenile"),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int?>(
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
          onChanged: _isSubmitting
              ? null
              : (value) {
                  setState(() {
                    _selectedTemplateId = value;
                    _response = null;
                    _errorMessage = null;
                  });
                },
          decoration: const InputDecoration(
            labelText: "Template seçimi",
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Seçilen Template, Batch Generate isteğine uygulanır.",
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

  Widget _buildInputItem({
    required BuildContext context,
    required int index,
    required _BatchInputControllers item,
  }) {
    final theme = Theme.of(context);

    return Container(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  "Öğe ${index + 1}",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: "Öğe sil",
                onPressed: _isSubmitting
                    ? null
                    : () {
                        _removeItem(index);
                      },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (_mode == GenerationMode.modA)
            TextField(
              controller: item.featureIdeaController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Özellik fikri",
                hintText: "Kullanıcı e-posta ve şifre ile giriş yapabilsin",
              ),
            )
          else ...[
            TextField(
              controller: item.userStoryController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: "User Story"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: item.acceptanceCriteriaController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: "AC"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final response = _response!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${response.successCount} başarılı, ${response.failedCount} başarısız / ${response.totalItems} öğe",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...response.results.map((item) => _buildResultItem(item, theme)),
      ],
    );
  }

  Widget _buildResultItem(BatchResultItem item, ThemeData theme) {
    final result = item.result;
    final title = _summaryForResult(result);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.success
            ? Colors.green.withValues(alpha: 0.08)
            : theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Öğe ${item.index + 1} • ${item.success ? "Başarılı" : "Başarısız"}",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: item.success
                  ? Colors.green.shade800
                  : theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.success
                ? title
                : (item.error ?? "Bu öğe için üretim tamamlanamadı."),
          ),
          if (item.success && result != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openBatchResult(item),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text("Sonucu aç"),
            ),
          ],
        ],
      ),
    );
  }

  String _summaryForResult(GenerationResult? result) {
    if (result == null) {
      return "Üretim başarılı ancak sonuç özeti alınamadı.";
    }

    if (result.userStory != null && result.userStory!.isNotEmpty) {
      return result.userStory!;
    }

    if (result.testCases.isNotEmpty) {
      return result.testCases.first.title;
    }

    return "Generation #${result.generationId}";
  }
}

class _BatchInputControllers {
  final TextEditingController featureIdeaController = TextEditingController();
  final TextEditingController userStoryController = TextEditingController();
  final TextEditingController acceptanceCriteriaController =
      TextEditingController();

  void dispose() {
    featureIdeaController.dispose();
    userStoryController.dispose();
    acceptanceCriteriaController.dispose();
  }
}
