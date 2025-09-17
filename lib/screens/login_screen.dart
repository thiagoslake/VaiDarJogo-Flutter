import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'user_dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      // O AuthGuard irá redirecionar automaticamente para UserDashboardScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
      );
    } else if (mounted) {
      final error = ref.read(authErrorProvider);
      if (error != null) {
        // Mostrar diálogo de erro mais amigável
        _showErrorDialog(error);
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('Erro no Login'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dicas para resolver:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildErrorTips(error),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authStateProvider.notifier).clearError();
              },
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authStateProvider.notifier).clearError();
                // Limpar campos para nova tentativa
                _passwordController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorTips(String error) {
    List<String> tips = [];

    if (error.contains('Email ou senha incorretos')) {
      tips = [
        '• Verifique se o email está digitado corretamente',
        '• Confirme se a senha está correta',
        '• Verifique se a tecla Caps Lock está ativada',
        '• Tente usar a opção "Esqueci a senha" se necessário',
      ];
    } else if (error.contains('Email não foi confirmado')) {
      tips = [
        '• Verifique sua caixa de entrada',
        '• Procure por emails na pasta de spam',
        '• Clique no link de confirmação no email',
        '• Aguarde alguns minutos e tente novamente',
      ];
    } else if (error.contains('Muitas tentativas')) {
      tips = [
        '• Aguarde alguns minutos antes de tentar novamente',
        '• Verifique sua conexão com a internet',
        '• Tente usar a opção "Esqueci a senha"',
      ];
    } else if (error.contains('Usuário não encontrado')) {
      tips = [
        '• Verifique se o email está correto',
        '• Crie uma nova conta se necessário',
        '• Tente usar outro email',
      ];
    } else if (error.contains('Erro de conexão')) {
      tips = [
        '• Verifique sua conexão com a internet',
        '• Tente novamente em alguns instantes',
        '• Verifique se o WiFi está funcionando',
      ];
    } else {
      tips = [
        '• Verifique sua conexão com a internet',
        '• Tente novamente em alguns instantes',
        '• Entre em contato com o suporte se o problema persistir',
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips
          .map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  tip,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite seu email primeiro'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await ref.read(authStateProvider.notifier).resetPassword(
          _emailController.text.trim(),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Email de recuperação enviado!'
                : 'Erro ao enviar email de recuperação',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(authErrorProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo e título
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        size: 50,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'VaiDarJogo',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Faça login para gerenciar seus jogos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Formulário de login
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Campo de email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite seu email';
                            }
                            if (!value.contains('@')) {
                              return 'Digite um email válido';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Campo de senha
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!isLoading) {
                              _handleLogin();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite sua senha';
                            }
                            if (value.length < 6) {
                              return 'A senha deve ter pelo menos 6 caracteres';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Lembrar-me e esqueci a senha
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                const Text('Lembrar-me'),
                              ],
                            ),
                            TextButton(
                              onPressed: _handleForgotPassword,
                              child: const Text('Esqueci a senha'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Botão de login
                        ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Entrar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 16),

                        // Link para registro
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Não tem uma conta? '),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Criar conta',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Exibir erro se houver
                if (error != null)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              ref.read(authStateProvider.notifier).clearError();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
