import "package:flutter/material.dart";

import "../models/auth_models.dart";
import "../models/usage_models.dart";
import "../services/api_service.dart";
import "../utils/date_formatters.dart";
import "../widgets/plan_badge.dart";
import "../widgets/section_card.dart";

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.apiService,
    required this.apiKey,
    required this.authResponse,
    required this.onBack,
    required this.onLogout,
  });

  final ApiService apiService;
  final String apiKey;
  final AuthValidationResponse authResponse;
  final VoidCallback onBack;
  final Future<void> Function() onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UsageSummary? _usage;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usage = await widget.apiService.fetchUsage(widget.apiKey);
      if (!mounted) {
        return;
      }
      setState(() {
        _usage = usage;
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
        title: const Text("Ayarlar"),
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
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
                Text("Access key: ${_maskApiKey(widget.apiKey)}"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: "Kullanım özeti",
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _usage == null
                    ? Text(
                        _errorMessage ?? "Kullanım bilgisi alınamadı.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _errorMessage != null
                              ? theme.colorScheme.error
                              : null,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  "${_usage!.usageCount} / ${_usage!.monthlyLimit}",
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFBAE6FD),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Kalan",
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: const Color(0xFF0369A1),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _usage!.remaining.toString(),
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: const Color(0xFF0369A1),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "üretim kullanıldı",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
                            AppDateFormatters.formatResetDate(
                              _usage!.usageResetAt,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: "Plan özeti",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.authResponse.plan.toLowerCase() == "premium"
                      ? "Premium plan aktif."
                      : "Free plan aktif.",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Free plan JSON ve Markdown Export destekler. Premium; CSV/Jira Export, temiz PDF, Templates, Batch Generate ve daha geniş History kullanımı ekler.",
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              widget.onLogout();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text("Çıkış yap"),
          ),
        ],
      ),
    );
  }

  String _maskApiKey(String apiKey) {
    if (apiKey.length <= 8) {
      return "${apiKey.substring(0, 2)}••••";
    }

    return "${apiKey.substring(0, 4)}••••••${apiKey.substring(apiKey.length - 4)}";
  }
}
