import "package:flutter/material.dart";

import "../models/generation_models.dart";
import "../models/history_models.dart";
import "../services/api_service.dart";
import "../utils/date_formatters.dart";
import "../widgets/section_card.dart";

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.apiService,
    required this.apiKey,
    required this.onBack,
    required this.onOpenResult,
  });

  final ApiService apiService;
  final String apiKey;
  final VoidCallback onBack;
  final void Function(int generationId) onOpenResult;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  GenerationMode? _selectedMode;
  HistoryListResponse? _history;
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final history = await widget.apiService.fetchHistoryWithFilters(
        apiKey: widget.apiKey,
        mode: _selectedMode,
        query: _searchController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _history = history;
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

  Future<void> _deleteItem(int generationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("History kaydını sil"),
        content: const Text(
          "Bu üretim History'den kaldırılacak. Devam edilsin mi?",
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
    });

    try {
      await widget.apiService.deleteHistoryItem(
        apiKey: widget.apiKey,
        generationId: generationId,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("History kaydı silindi.")),
      );
      await _loadHistory();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _history?.items ?? const <HistoryItem>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
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
                    _loadHistory();
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: "Filtreler",
            child: Column(
              children: [
                DropdownButtonFormField<GenerationMode?>(
                  initialValue: _selectedMode,
                  items: [
                    const DropdownMenuItem<GenerationMode?>(
                      value: null,
                      child: Text("Tüm modlar"),
                    ),
                    ...GenerationMode.values.map(
                      (mode) => DropdownMenuItem<GenerationMode?>(
                        value: mode,
                        child: Text(mode.label),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMode = value;
                    });
                    _loadHistory();
                  },
                  decoration: const InputDecoration(
                    labelText: "Mod",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: "Ara",
                    hintText: "Girdi veya çıktıda ara",
                    suffixIcon: IconButton(
                      onPressed: () {
                        _loadHistory();
                      },
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ),
                  onSubmitted: (_) {
                    _loadHistory();
                  },
                ),
                if (_history?.limit != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Free plan son ${_history!.limit} kaydı gösterir.",
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: "Sonuçlar",
            trailing: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (_history != null
                    ? Text(
                        "${_history!.count} kayıt",
                        style: theme.textTheme.labelMedium,
                      )
                    : null),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : items.isEmpty
                        ? Text(
                            "Bu filtrelerle eşleşen History kaydı yok.",
                            style: theme.textTheme.bodyMedium,
                          )
                        : Column(
                            children: items
                                .map(
                                  (item) => Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            _ModeBadge(mode: item.mode),
                                            Text(
                                              "#${item.displayId}",
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppDateFormatters.formatDateTime(
                                            item.createdAt,
                                          ),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.outputSummary,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            OutlinedButton(
                                              onPressed: () {
                                                widget.onOpenResult(
                                                  item.generationId,
                                                );
                                              },
                                              child: const Text("Aç"),
                                            ),
                                            const SizedBox(width: 10),
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    theme.colorScheme.error,
                                                side: BorderSide(
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                              ),
                                              onPressed: _isDeleting
                                                  ? null
                                                  : () {
                                                      _deleteItem(
                                                        item.generationId,
                                                      );
                                                    },
                                              child: const Text("Sil"),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode});

  final GenerationMode mode;

  @override
  Widget build(BuildContext context) {
    final colors = _modeColors(mode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        mode.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

({Color background, Color border, Color foreground}) _modeColors(
  GenerationMode mode,
) {
  switch (mode) {
    case GenerationMode.modA:
      return (
        background: const Color(0xFFE0F2FE),
        border: const Color(0xFFBAE6FD),
        foreground: const Color(0xFF0369A1),
      );
    case GenerationMode.modB:
      return (
        background: const Color(0xFFD1FAE5),
        border: const Color(0xFFA7F3D0),
        foreground: const Color(0xFF047857),
      );
    case GenerationMode.bugReport:
      return (
        background: const Color(0xFFFEF3C7),
        border: const Color(0xFFFDE68A),
        foreground: const Color(0xFFB45309),
      );
  }
}
