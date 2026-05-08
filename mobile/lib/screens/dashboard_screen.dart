import "package:flutter/material.dart";

import "../models/auth_models.dart";
import "../models/generation_models.dart";
import "../models/history_models.dart";
import "../models/system_models.dart";
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
    required this.onOpenGenerate,
    required this.onOpenHistory,
    required this.onOpenSettings,
    required this.onOpenResult,
    required this.onLogout,
  });

  final ApiService apiService;
  final String apiKey;
  final AuthValidationResponse authResponse;
  final void Function(GenerationMode mode) onOpenGenerate;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;
  final void Function(int generationId) onOpenResult;
  final Future<void> Function() onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UsageSummary? _usage;
  HistoryListResponse? _history;
  SystemStatus? _systemStatus;
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
      SystemStatus? systemStatus;
      try {
        systemStatus = await widget.apiService.fetchSystemStatus();
      } catch (_) {
        systemStatus = null;
      }

      final usage = await widget.apiService.fetchUsage(widget.apiKey);
      final history = await widget.apiService.fetchHistory(widget.apiKey);

      if (!mounted) {
        return;
      }

      setState(() {
        _usage = usage;
        _history = history;
        _systemStatus = systemStatus;
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
        title: const Text("Kontrol paneli"),
        actions: [
          IconButton(
            tooltip: "Geçmiş",
            onPressed: widget.onOpenHistory,
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: "Ayarlar",
            onPressed: widget.onOpenSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
          IconButton(
            tooltip: "Yenile",
            onPressed: _isLoading
                ? null
                : () {
                    _loadDashboardData();
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: "Çıkış yap",
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
              title: "Hesap",
              trailing: PlanBadge(plan: widget.authResponse.plan),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.authResponse.ownerName.isNotEmpty
                        ? widget.authResponse.ownerName
                        : "Access key oturumu",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Mod A, Mod B veya Bug Report ile hızlıca QA çıktısı üretin.",
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_systemStatus != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "AI motoru: ${_systemStatus!.ai.displayName}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: "Hızlı işlemler",
              child: Column(
                children: [
                  _QuickActionTile(
                    label: "Yeni Mod A",
                    subtitle: "Feature fikrinden QA çıktıları üret",
                    icon: Icons.auto_awesome_rounded,
                    onTap: () => widget.onOpenGenerate(GenerationMode.modA),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionTile(
                    label: "Yeni Mod B",
                    subtitle: "User Story ve AC’den Test Case üret",
                    icon: Icons.fact_check_rounded,
                    onTap: () => widget.onOpenGenerate(GenerationMode.modB),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionTile(
                    label: "Yeni Bug Report",
                    subtitle: "Hata notlarından rapor taslağı üret",
                    icon: Icons.bug_report_rounded,
                    onTap: () =>
                        widget.onOpenGenerate(GenerationMode.bugReport),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionTile(
                    label: "Geçmişi aç",
                    subtitle: "Önceki üretimleri incele",
                    icon: Icons.history_rounded,
                    onTap: widget.onOpenHistory,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: "Kullanım özeti",
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildUsageSection(theme),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: "Son geçmiş",
              trailing: _history?.limit != null
                  ? Text(
                      "Son ${_history!.limit}",
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
        "Kullanım bilgisi şu anda alınamadı.",
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${_usage!.usageCount} / ${_usage!.monthlyLimit} üretim kullanıldı",
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
          "Kalan hak: ${_usage!.remaining}\nSıfırlanma: ${_usage!.usageResetAt}",
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildHistorySection(ThemeData theme) {
    final items = _history?.items.take(5).toList() ?? const <HistoryItem>[];

    if (items.isEmpty) {
      return Text(
        "Henüz geçmiş kaydı yok. Yeni bir üretimle başlayın.",
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      children: items
          .map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => widget.onOpenResult(item.generationId),
              title: Text(
                item.outputSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "${item.mode.label} • ${item.createdAt}",
              ),
              leading: CircleAvatar(
                child: Text(item.generationId.toString()),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
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
