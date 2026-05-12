import "package:flutter/material.dart";

import "../models/auth_models.dart";
import "../models/template_models.dart";
import "../services/api_service.dart";
import "../utils/date_formatters.dart";
import "../widgets/plan_badge.dart";
import "../widgets/primary_action_button.dart";
import "../widgets/section_card.dart";

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({
    super.key,
    required this.apiService,
    required this.apiKey,
    required this.authResponse,
    required this.onBack,
  });

  final ApiService apiService;
  final String apiKey;
  final AuthValidationResponse authResponse;
  final VoidCallback onBack;

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  List<TemplateItem> _templates = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;
  int? _editingTemplateId;

  bool get _isPremium => widget.authResponse.plan.toLowerCase() == "premium";

  @override
  void initState() {
    super.initState();
    if (_isPremium) {
      _loadTemplates();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await widget.apiService.fetchTemplates(widget.apiKey);

      if (!mounted) {
        return;
      }

      setState(() {
        _templates = response.items;
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

  Future<void> _saveTemplate() async {
    final name = _nameController.text.trim();
    final promptText = _promptController.text.trim();

    if (name.isEmpty || promptText.length < 10) {
      setState(() {
        _errorMessage =
            "Template adı ve en az 10 karakterlik prompt metni girin.";
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final isEditing = _editingTemplateId != null;
      if (_editingTemplateId == null) {
        await widget.apiService.createTemplate(
          apiKey: widget.apiKey,
          name: name,
          promptText: promptText,
        );
      } else {
        await widget.apiService.updateTemplate(
          apiKey: widget.apiKey,
          templateId: _editingTemplateId!,
          name: name,
          promptText: promptText,
        );
      }

      if (!mounted) {
        return;
      }

      _clearForm();
      await _loadTemplates();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? "Template güncellendi." : "Template oluşturuldu.",
          ),
        ),
      );
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
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteTemplate(TemplateItem template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Template sil"),
        content: Text(
          "\"${template.name}\" template’i silinecek. Devam edilsin mi?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Vazgeç"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await widget.apiService.deleteTemplate(
        apiKey: widget.apiKey,
        templateId: template.id,
      );

      if (!mounted) {
        return;
      }

      if (_editingTemplateId == template.id) {
        _clearForm();
      }

      await _loadTemplates();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Template silindi.")),
      );
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
          _isDeleting = false;
        });
      }
    }
  }

  void _startEditing(TemplateItem template) {
    setState(() {
      _editingTemplateId = template.id;
      _nameController.text = template.name;
      _promptController.text = template.promptText;
      _errorMessage = null;
    });
  }

  void _clearForm() {
    setState(() {
      _editingTemplateId = null;
      _nameController.clear();
      _promptController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Templates"),
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: "Yenile",
            onPressed: !_isPremium || _isLoading ? null : _loadTemplates,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: "Plan durumu",
            trailing: PlanBadge(plan: widget.authResponse.plan),
            child: Text(
              _isPremium
                  ? "Premium plan ile kendi Template’lerinizi oluşturup üretim sırasında seçebilirsiniz."
                  : "Templates yalnızca Premium kullanıcılar için açıktır. Login ekranındaki Premium simülasyonu ile Premium access key oluşturabilirsiniz.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (_isPremium) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: _editingTemplateId == null
                  ? "Yeni Template"
                  : "Template düzenle",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Template adı",
                      hintText: "Regression checklist",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _promptController,
                    minLines: 5,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: "Prompt metni",
                      hintText:
                          "Üretilen testlerde edge case ve negatif senaryolara ağırlık ver.",
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isSaving) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 12),
                  ],
                  PrimaryActionButton(
                    label: _editingTemplateId == null
                        ? "Template oluştur"
                        : "Template güncelle",
                    icon: Icons.save_rounded,
                    onPressed: _isSaving ? null : _saveTemplate,
                  ),
                  if (_editingTemplateId != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _isSaving ? null : _clearForm,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text("Düzenlemeyi iptal et"),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: "Template listesi",
              trailing: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text("${_templates.length} kayıt"),
              child: _buildTemplateList(theme),
            ),
          ],
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

  Widget _buildTemplateList(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_templates.isEmpty) {
      return Text(
        "Henüz Template yok. İlk Template’i oluşturup Generate ekranında seçebilirsiniz.",
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      children: _templates
          .map(
            (template) => Container(
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
                    template.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _templateDateLabel(template),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.promptText,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isSaving || _isDeleting
                            ? null
                            : () {
                                _startEditing(template);
                              },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text("Düzenle"),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                        ),
                        onPressed: _isSaving || _isDeleting
                            ? null
                            : () {
                                _deleteTemplate(template);
                              },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text("Sil"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _templateDateLabel(TemplateItem template) {
    final updatedAt = template.updatedAt.trim();
    if (updatedAt.isNotEmpty) {
      return "Güncellendi: ${AppDateFormatters.formatDateTime(updatedAt)}";
    }

    return "Oluşturuldu: ${AppDateFormatters.formatDateTime(template.createdAt)}";
  }
}
