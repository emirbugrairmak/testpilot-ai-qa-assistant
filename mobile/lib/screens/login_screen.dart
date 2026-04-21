import "package:flutter/material.dart";

import "../widgets/primary_action_button.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    this.initialApiKey,
  });

  final Future<void> Function(String apiKey) onLogin;
  final String? initialApiKey;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _apiKeyController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(
      text: widget.initialApiKey ?? "tp_free_demo_key",
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onLogin(_apiKeyController.text.trim());
    } catch (error) {
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TestPilot",
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Sign in with your API key to restore your QA workspace.",
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: "API key",
                      hintText: "tp_free_demo_key",
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      _submit();
                    },
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
                  const SizedBox(height: 24),
                  if (_isLoading) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                  ],
                  PrimaryActionButton(
                    label: "Validate API key",
                    icon: Icons.login_rounded,
                    onPressed: _isLoading
                        ? null
                        : () {
                            _submit();
                          },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Demo keys",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Free: tp_free_demo_key\nPremium: tp_premium_demo_key",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
