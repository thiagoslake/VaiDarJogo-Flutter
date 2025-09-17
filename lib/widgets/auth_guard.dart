import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const AuthGuard({
    super.key,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Se está carregando, mostrar loading
    if (authState.isLoading) {
      return loadingWidget ??
          const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando...'),
                ],
              ),
            ),
          );
    }

    // Se não está autenticado, redirecionar para login
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    // Se há erro E está autenticado, mostrar erro
    if (authState.error != null && authState.isAuthenticated) {
      return errorWidget ??
          Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro de autenticação',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authState.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(authStateProvider.notifier).clearError();
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
    }

    // Se está autenticado, mostrar o conteúdo
    return child;
  }
}

// Widget para verificar se o usuário está autenticado antes de executar uma ação
class AuthRequired extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onUnauthenticated;

  const AuthRequired({
    super.key,
    required this.child,
    this.onUnauthenticated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      // Se não está autenticado, executar callback ou redirecionar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (onUnauthenticated != null) {
          onUnauthenticated!();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      });

      return const SizedBox.shrink();
    }

    return child;
  }
}

// Hook para verificar autenticação em qualquer widget
class AuthCheck extends ConsumerWidget {
  final Widget Function(BuildContext context, bool isAuthenticated) builder;

  const AuthCheck({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    return builder(context, isAuthenticated);
  }
}
