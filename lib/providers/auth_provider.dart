import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/auth_error_handler.dart';

// Provider para o estado de autenticação
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Provider para o usuário atual
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

// Provider para verificar se está autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});

// Provider para verificar se está carregando
final isLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isLoading;
});

// Provider para erros de autenticação
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.error;
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initializeAuth();
  }

  /// Inicializar estado de autenticação
  /// Sempre inicia na tela de login, independente de sessões anteriores
  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);

    try {
      // Sempre definir como não autenticado na inicialização
      // para forçar o usuário a fazer login novamente
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: null,
      );

      print('🔐 Aplicativo configurado para sempre iniciar na tela de login');
    } catch (e) {
      print('❌ Erro na inicialização da autenticação: $e');
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: 'Erro ao inicializar autenticação: ${e.toString()}',
      );
    }
  }

  /// Fazer login
  Future<bool> signIn(String email, String password) async {
    print('🔍 DEBUG - AuthProvider: Iniciando signIn para: $email');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await AuthService.signInWithEmail(email, password);
      print('🔍 DEBUG - AuthProvider: Usuário retornado: ${user?.email}');

      if (user != null) {
        print(
            '🔍 DEBUG - AuthProvider: Login bem-sucedido, atualizando estado');
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );
        print('🔍 DEBUG - AuthProvider: Estado atualizado com sucesso');
        return true;
      } else {
        print('🔍 DEBUG - AuthProvider: Usuário null, definindo erro');
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
          error: 'Credenciais inválidas',
        );
        return false;
      }
    } catch (e) {
      print('🔍 DEBUG - AuthProvider: Exceção capturada: $e');
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: AuthErrorHandler.getFriendlyErrorMessage(e),
      );
      return false;
    }
  }

  /// Registrar novo usuário
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    // Campos adicionais do jogador
    DateTime? birthDate,
    String? primaryPosition,
    String? secondaryPosition,
    String? preferredFoot,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await AuthService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
        // Campos adicionais do jogador
        birthDate: birthDate,
        primaryPosition: primaryPosition,
        secondaryPosition: secondaryPosition,
        preferredFoot: preferredFoot,
      );

      if (user != null) {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
          error: 'Erro ao criar conta',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: AuthErrorHandler.getFriendlyErrorMessage(e),
      );
      return false;
    }
  }

  /// Fazer logout
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await AuthService.signOut();
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Redefinir senha
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await AuthService.resetPassword(email);
      state = state.copyWith(
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AuthErrorHandler.getFriendlyErrorMessage(e),
      );
      return false;
    }
  }

  /// Atualizar perfil
  Future<bool> updateProfile({
    String? name,
    String? phone,
  }) async {
    if (state.user == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedUser = await AuthService.updateProfile(
        userId: state.user!.id,
        name: name,
        phone: phone,
      );

      if (updatedUser != null) {
        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Erro ao atualizar perfil',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Atualizar email
  Future<bool> updateEmail({
    required String newEmail,
    String password = '', // Não é obrigatório para usuários já autenticados
  }) async {
    print('🔍 DEBUG - AuthProvider: Iniciando updateEmail para: $newEmail');

    if (state.user == null) {
      print('❌ AuthProvider: Usuário null');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await AuthService.updateEmail(
        newEmail: newEmail,
        password: password,
      );

      print('🔍 DEBUG - AuthProvider: Resultado do AuthService: $success');

      if (success) {
        // Atualizar o estado do usuário com o novo email
        final updatedUser = state.user!.copyWith(email: newEmail);
        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
          error: null,
        );
        print('✅ AuthProvider: Email atualizado com sucesso');
        return true;
      }

      print('❌ AuthProvider: AuthService retornou false');
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar email',
      );
      return false;
    } catch (e) {
      print('❌ AuthProvider: Exceção capturada: $e');
      state = state.copyWith(
        isLoading: false,
        error: AuthErrorHandler.getFriendlyErrorMessage(e),
      );
      return false;
    }
  }

  /// Atualizar senha
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.user == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await AuthService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          error: null,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar senha',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AuthErrorHandler.getFriendlyErrorMessage(e),
      );
      return false;
    }
  }

  /// Atualizar usuário
  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  /// Limpar erro
  void clearError() {
    state = state.copyWith(error: null);
  }
}
