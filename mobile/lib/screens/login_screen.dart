import "package:flutter/material.dart";

import "../services/api_service.dart";
import "../widgets/primary_action_button.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.apiService,
    required this.onLogin,
    this.initialApiKey,
  });

  final ApiService apiService;
  final Future<void> Function(String apiKey) onLogin;
  final String? initialApiKey;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _ownerNameController;
  bool _isLoading = false;
  bool _isCreatingFreeAccess = false;
  String? _errorMessage;
  String? _createdAccessKey;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(
      text: widget.initialApiKey ?? "",
    );
    _ownerNameController = TextEditingController();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        throw ApiException("Lütfen erişim anahtarınızı girin.");
      }

      await widget.onLogin(apiKey);
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

  Future<void> _createFreeAccess() async {
    setState(() {
      _isCreatingFreeAccess = true;
      _errorMessage = null;
      _infoMessage = null;
      _createdAccessKey = null;
    });

    try {
      final response = await widget.apiService.createFreeAccess(
        ownerName: _ownerNameController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _createdAccessKey = response.accessKey;
        _apiKeyController.text = response.accessKey;
        _infoMessage =
            "Free erişim anahtarınız oluşturuldu. Anahtar alana dolduruldu; giriş yapabilirsiniz.";
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
          _isCreatingFreeAccess = false;
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
                    "QA üretim alanınıza erişmek için mevcut access key ile giriş yapın ya da ücretsiz erişim oluşturun.",
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    "Mevcut erişim anahtarı",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: "Access key",
                      hintText: "tp_...",
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
                    label: "Giriş yap",
                    icon: Icons.login_rounded,
                    onPressed: _isLoading || _isCreatingFreeAccess
                        ? null
                        : () {
                            _submit();
                          },
                  ),
                  const SizedBox(height: 28),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ücretsiz erişim al",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Hesap kurmadan yeni bir Free access key oluşturur.",
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _ownerNameController,
                            decoration: const InputDecoration(
                              labelText: "Ad / ekip adı (opsiyonel)",
                              hintText: "QA Demo Ekibi",
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isLoading || _isCreatingFreeAccess
                                ? null
                                : _createFreeAccess,
                            icon: _isCreatingFreeAccess
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.key_rounded),
                            label: const Text("Ücretsiz erişim al"),
                          ),
                          if (_createdAccessKey != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              "Oluşturulan access key",
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(_createdAccessKey!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_infoMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _infoMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text("Geliştirici demo anahtarları"),
                    childrenPadding: EdgeInsets.zero,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Free: tp_free_demo_key\nPremium: tp_premium_demo_key",
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
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
