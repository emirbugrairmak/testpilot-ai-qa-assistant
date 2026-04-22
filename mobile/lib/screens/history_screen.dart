import "package:flutter/material.dart";

import "../models/generation_models.dart";
import "../models/history_models.dart";
import "../services/api_service.dart";
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
        title: const Text("Delete history item"),
        content: const Text(
          "This generation will be removed from your history. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
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
        const SnackBar(content: Text("History item deleted.")),
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
            tooltip: "Refresh",
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
            title: "Filters",
            child: Column(
              children: [
                DropdownButtonFormField<GenerationMode?>(
                  initialValue: _selectedMode,
                  items: [
                    const DropdownMenuItem<GenerationMode?>(
                      value: null,
                      child: Text("All modes"),
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
                    labelText: "Mode",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: "Search",
                    hintText: "Search in input or output",
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
                      "Free plan returns the last ${_history!.limit} records.",
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: "Results",
            trailing: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (_history != null
                    ? Text(
                        "${_history!.count} items",
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
                            "No history records match the current filters.",
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
                                        Text(
                                          "${item.mode.label} • #${item.generationId}",
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.outputSummary,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item.createdAt,
                                          style: theme.textTheme.bodySmall,
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
                                              child: const Text("Open"),
                                            ),
                                            const SizedBox(width: 10),
                                            OutlinedButton(
                                              onPressed: _isDeleting
                                                  ? null
                                                  : () {
                                                      _deleteItem(
                                                        item.generationId,
                                                      );
                                                    },
                                              child: const Text("Delete"),
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
