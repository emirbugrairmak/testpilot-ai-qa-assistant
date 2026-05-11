import "package:flutter/material.dart";

import "../models/auth_models.dart";
import "../models/system_models.dart";
import "../models/usage_models.dart";
import "../services/api_service.dart";
import "../utils/constants.dart";
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
  SystemStatus? _systemStatus;
  bool _isLoading = true;
  bool _isCheckingStatus = true;
  String? _errorMessage;
  String? _statusErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    setState(() {
      _isLoading = true;
      _isCheckingStatus = true;
      _errorMessage = null;
      _statusErrorMessage = null;
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

    try {
      final systemStatus = await widget.apiService.fetchSystemStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _systemStatus = systemStatus;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusErrorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
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
                          Text(
                            "${_usage!.usageCount} / ${_usage!.monthlyLimit} kullanıldı",
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
                          Text("Kalan hak: ${_usage!.remaining}"),
                          Text(
                            AppDateFormatters.formatResetDate(
                              _usage!.usageResetAt,
                            ),
                          ),
                        ],
                      ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: "Plan",
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
                if (_isCheckingStatus)
                  const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text("Bağlantı durumu kontrol ediliyor..."),
                    ],
                  )
                else if (_systemStatus != null)
                  Text(
                    _systemStatus!.isHealthy
                        ? "Bağlantı durumu: Bağlı"
                        : "Bağlantı durumu: ${_systemStatus!.status}",
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Text(
                    _statusErrorMessage ?? "Bağlantı durumu alınamadı.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    "Geliştirici bilgileri",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SelectableText(
                            "API_BASE_URL: ${AppConstants.apiBaseUrl}",
                          ),
                          if (_systemStatus != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              "AI motoru: ${_systemStatus!.ai.displayName}",
                            ),
                          ],
                          if (_statusErrorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(_statusErrorMessage!),
                          ],
                        ],
                      ),
                    ),
                  ],
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
