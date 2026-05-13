import "package:flutter/material.dart";

import "../models/auth_models.dart";
import "../models/generation_models.dart";
import "../models/history_models.dart";
import "../models/usage_models.dart";
import "../services/api_service.dart";
import "../utils/date_formatters.dart";
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
    required this.onOpenTemplates,
    required this.onOpenBatch,
    required this.onOpenResult,
    required this.onLogout,
  });

  final ApiService apiService;
  final String apiKey;
  final AuthValidationResponse authResponse;
  final void Function(GenerationMode mode) onOpenGenerate;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenTemplates;
  final VoidCallback onOpenBatch;
  final void Function(int generationId) onOpenResult;
  final Future<void> Function() onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UsageSummary? _usage;
  HistoryListResponse? _history;
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isPremium {
    return widget.authResponse.plan.toLowerCase() == "premium";
  }

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
        title: const Text("Kontrol paneli"),
        actions: [
          IconButton(
            tooltip: "History",
            onPressed: widget.onOpenHistory,
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: "Ayarlar",
            onPressed: widget.onOpenSettings,
            icon: const Icon(Icons.settings_rounded),
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
            Row(
              children: [
                Image.asset(
                  "assets/icons/testpilot_launcher.png",
                  width: 36,
                  height: 36,
                ),
                const SizedBox(width: 10),
                Text(
                  "TestPilot",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Fikirden test senaryolarına, dakikalar içinde.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
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
                    label: "Batch Generate",
                    subtitle: _isPremium
                        ? "Mod A / Mod B çoklu üretim"
                        : "Premium özellik",
                    icon: Icons.playlist_add_check_rounded,
                    onTap: widget.onOpenBatch,
                    locked: !_isPremium,
                  ),
                  const SizedBox(height: 12),
                  _QuickActionTile(
                    label: "Templates",
                    subtitle: _isPremium
                        ? "Premium Template’leri yönet"
                        : "Premium özellik",
                    icon: Icons.dashboard_customize_rounded,
                    onTap: widget.onOpenTemplates,
                    locked: !_isPremium,
                  ),
                  const SizedBox(height: 12),
                  _QuickActionTile(
                    label: "History",
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
              title: "Son History",
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                "${_usage!.usageCount} / ${_usage!.monthlyLimit}",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Kalan",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF0369A1),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _usage!.remaining.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0369A1),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _usage!.monthlyLimit == 0
              ? 0
              : _usage!.usageCount / _usage!.monthlyLimit,
        ),
        const SizedBox(height: 12),
        Text(
          AppDateFormatters.formatResetDate(_usage!.usageResetAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(ThemeData theme) {
    final items = _history?.items.take(5).toList() ?? const <HistoryItem>[];

    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bu Access key ile yapılan son üretimler.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Henüz History kaydı yok. Yeni bir üretimle başlayın.",
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map<Widget>(
            (item) => InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => widget.onOpenResult(item.generationId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModeBadge(mode: item.mode),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.outputSummary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "#${item.generationId} • ${AppDateFormatters.formatDateTime(item.createdAt)}",
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          )
          .toList()
        ..insertAll(0, [
          Text(
            "Bu Access key ile yapılan son üretimler.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ]),
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool locked;

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
            Icon(
              locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
