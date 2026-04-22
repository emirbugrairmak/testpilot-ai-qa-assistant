import "package:flutter/material.dart";

import "../models/auth_models.dart";
import "../models/usage_models.dart";
import "../services/api_service.dart";
import "../utils/constants.dart";
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
    _loadUsage();
  }

  Future<void> _loadUsage() async {
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
        title: const Text("Settings"),
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
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
                Text("API key: ${_maskApiKey(widget.apiKey)}"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: "Usage summary",
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _usage == null
                    ? Text(
                        _errorMessage ?? "Usage information is unavailable.",
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
                            "${_usage!.usageCount} / ${_usage!.monthlyLimit} used",
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
                          Text("Remaining: ${_usage!.remaining}"),
                          Text("Reset at: ${_usage!.usageResetAt}"),
                        ],
                      ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: "API info",
            child: Text(
              "Base URL: ${AppConstants.apiBaseUrl}\nJSON and Markdown exports are available on all plans. CSV and Jira exports require premium.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              widget.onLogout();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text("Logout"),
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
