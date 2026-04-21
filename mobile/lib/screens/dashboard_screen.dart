import "package:flutter/material.dart";

import "../models/auth_models.dart";
import "../models/generation_models.dart";
import "../models/history_models.dart";
import "../models/usage_models.dart";
import "../services/api_service.dart";
import "../widgets/plan_badge.dart";
import "../widgets/section_card.dart";

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.apiService,
    required this.apiKey,
    required this.authResponse,
    required this.onLogout,
    required this.onOpenGenerate,
  });

  final ApiService apiService;
  final String apiKey;
  final AuthValidationResponse authResponse;
  final Future<void> Function() onLogout;
  final void Function(GenerationMode mode) onOpenGenerate;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UsageSummary? _usage;
  HistoryListResponse? _history;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usage = await widget.apiService.fetchUsage(widget.apiKey);
      final history = await widget.apiService.fetchHistory(widget.apiKey);

      if (!mounted) {
        return;
      }

      setState(() {
        _usage = usage;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: _isLoading
                ? null
                : () {
                    _loadDashboardData();
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: "Logout",
            onPressed: () {
              widget.onLogout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: "Account",
              trailing: PlanBadge(plan: widget.authResponse.plan),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.authResponse.ownerName.isNotEmpty
                        ? widget.authResponse.ownerName
                        : "API key session",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Use Mod A, Mod B, or Bug Report to create QA output quickly.",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: "Quick actions",
              child: Column(
                children: [
                  _QuickActionTile(
                    label: "New Mod A",
                    subtitle: "Feature idea to QA artifacts",
                    icon: Icons.auto_awesome_rounded,
                    onTap: () => widget.onOpenGenerate(GenerationMode.modA),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionTile(
                    label: "New Mod B",
                    subtitle: "User story and AC to test cases",
                    icon: Icons.fact_check_rounded,
                    onTap: () => widget.onOpenGenerate(GenerationMode.modB),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionTile(
                    label: "New Bug Report",
                    subtitle: "Issue notes to bug template",
                    icon: Icons.bug_report_rounded,
                    onTap: () => widget.onOpenGenerate(GenerationMode.bugReport),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: "Usage summary",
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildUsageSection(theme),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: "Recent history",
              trailing: _history?.limit != null
                  ? Text(
                      "Last ${_history!.limit}",
                      style: theme.textTheme.labelMedium,
                    )
                  : null,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildHistorySection(theme),
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
      ),
    );
  }

  Widget _buildUsageSection(ThemeData theme) {
    if (_usage == null) {
      return Text(
        "Usage data is not available yet.",
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${_usage!.usageCount} / ${_usage!.monthlyLimit} generations used",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _usage!.monthlyLimit == 0
              ? 0
              : _usage!.usageCount / _usage!.monthlyLimit,
        ),
        const SizedBox(height: 12),
        Text(
          "Remaining: ${_usage!.remaining}\nResets at: ${_usage!.usageResetAt}",
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildHistorySection(ThemeData theme) {
    final items = _history?.items.take(5).toList() ?? const <HistoryItem>[];

    if (items.isEmpty) {
      return Text(
        "No history yet. Start with a new generation.",
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      children: items
          .map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                item.outputSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "${item.mode} • ${item.createdAt}",
              ),
              leading: CircleAvatar(
                child: Text(item.generationId.toString()),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
