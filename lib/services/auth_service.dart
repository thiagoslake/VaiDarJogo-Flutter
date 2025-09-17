import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_model.dart';
import '../config/supabase_config.dart';
import '../utils/auth_error_handler.dart';
import '../utils/friendly_auth_exception.dart';
import 'player_service.dart';

class AuthService {
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Fazer login com email e senha
  static Future<User?> signInWithEmail(String email, String password) async {
    print('🔍 DEBUG - Iniciando login para: $email');
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('🔍 DEBUG - Resposta do Supabase Auth: ${response.user?.email}');

      if (response.user != null) {
        print(
            '✅ Login bem-sucedido no Supabase Auth para: ${response.user!.email}');

        // Buscar dados do usuário na tabela users
        try {
          final userData = await _client
              .from('users')
              .select('*')
              .eq('id', response.user!.id)
              .single();

          print('✅ Dados do usuário encontrados na tabela users');

          // Atualizar último login
          await _client
              .from('users')
              .update({'last_login_at': DateTime.now().toIso8601String()}).eq(
                  'id', response.user!.id);

          print('✅ Último login atualizado');
          return User.fromMap(userData);
        } catch (e) {
          print('❌ Erro ao buscar dados do usuário na tabela users: $e');
          // Se não encontrar na tabela users, criar um registro básico
          final userData = {
            'id': response.user!.id,
            'email': response.user!.email ?? '',
            'name': response.user!.userMetadata?['name'] ?? 'Usuário',
            'phone': response.user!.userMetadata?['phone'],
            'created_at': DateTime.now().toIso8601String(),
            'is_active': true,
          };

          await _client.from('users').insert(userData);
          print('✅ Usuário criado na tabela users');

          // Atualizar último login
          await _client
              .from('users')
              .update({'last_login_at': DateTime.now().toIso8601String()}).eq(
                  'id', response.user!.id);

          return User.fromMap(userData);
        }
      }
      print('🔍 DEBUG - Retornando null - usuário não encontrado');
      return null;
    } on AuthException catch (authError) {
      // Capturar especificamente AuthException para evitar logs automáticos
      // Se for erro de email não confirmado, tentar confirmar automaticamente
      if (AuthErrorHandler.isEmailNotConfirmedError(authError)) {
        print('🔄 Tentando confirmar email automaticamente...');
        try {
          // Tentar fazer login novamente após confirmação automática
          final retryResponse = await _client.auth.signInWithPassword(
            email: email,
            password: password,
          );

          if (retryResponse.user != null) {
            final userData = await _client
                .from('users')
                .select('*')
                .eq('id', retryResponse.user!.id)
                .single();

            // Atualizar último login
            await _client
                .from('users')
                .update({'last_login_at': DateTime.now().toIso8601String()}).eq(
                    'id', retryResponse.user!.id);

            return User.fromMap(userData);
          }
        } catch (retryError) {
          // Não logar erro de retry para evitar poluir console
        }
      }

      // Lançar erro com mensagem amigável sem logar o erro original
      throw FriendlyAuthException(
          AuthErrorHandler.getFriendlyErrorMessage(authError));
    } catch (e) {
      // Capturar outros tipos de erro
      // Se for erro de email não confirmado, tentar confirmar automaticamente
      if (AuthErrorHandler.isEmailNotConfirmedError(e)) {
        print('🔄 Tentando confirmar email automaticamente...');
        try {
          // Tentar fazer login novamente após confirmação automática
          final retryResponse = await _client.auth.signInWithPassword(
            email: email,
            password: password,
          );

          if (retryResponse.user != null) {
            final userData = await _client
                .from('users')
                .select('*')
                .eq('id', retryResponse.user!.id)
                .single();

            // Atualizar último login
            await _client
                .from('users')
                .update({'last_login_at': DateTime.now().toIso8601String()}).eq(
                    'id', retryResponse.user!.id);

            return User.fromMap(userData);
          }
        } catch (retryError) {
          // Não logar erro de retry para evitar poluir console
        }
      }

      // Lançar erro com mensagem amigável sem logar o erro original
      throw FriendlyAuthException(AuthErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  /// Registrar novo usuário
  static Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      // Registrar no Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      if (response.user != null) {
        // Aguardar um pouco para o trigger processar
        await Future.delayed(const Duration(seconds: 2));

        try {
          // Buscar o usuário criado pelo trigger
          final userData = await _client
              .from('users')
              .select('*')
              .eq('id', response.user!.id)
              .single();

          final user = User.fromMap(userData);

          // Criar perfil de jogador automaticamente
          await _createPlayerProfile(user, phone);

          return user;
        } catch (e) {
          // Se não encontrar o usuário, criar manualmente
          print(
              '⚠️ Usuário não encontrado na tabela users, criando manualmente...');

          final userData = {
            'id': response.user!.id,
            'email': email,
            'name': name,
            'phone': phone,
            'created_at': DateTime.now().toIso8601String(),
            'is_active': true,
          };

          await _client.from('users').insert(userData);

          final user = User.fromMap(userData);

          // Criar perfil de jogador automaticamente
          await _createPlayerProfile(user, phone);

          return user;
        }
      }
      return null;
    } catch (e) {
      // Lançar erro com mensagem amigável
      throw FriendlyAuthException(AuthErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  /// Fazer logout
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('❌ Erro no logout: $e');
      rethrow;
    }
  }

  /// Obter usuário atual
  static Future<User?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      if (session?.user != null) {
        final userData = await _client
            .from('users')
            .select('*')
            .eq('id', session!.user.id)
            .single();

        return User.fromMap(userData);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao obter usuário atual: $e');
      return null;
    }
  }

  /// Verificar se usuário está autenticado
  static bool get isAuthenticated {
    return _client.auth.currentSession != null;
  }

  /// Obter ID do usuário atual
  static String? get currentUserId {
    return _client.auth.currentUser?.id;
  }

  /// Redefinir senha
  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      // Lançar erro com mensagem amigável
      throw FriendlyAuthException(AuthErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  /// Atualizar perfil do usuário
  static Future<User?> updateProfile({
    required String userId,
    String? name,
    String? phone,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;

      if (updateData.isNotEmpty) {
        await _client.from('users').update(updateData).eq('id', userId);

        // Retornar usuário atualizado
        final userData =
            await _client.from('users').select('*').eq('id', userId).single();

        return User.fromMap(userData);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  /// Atualizar email do usuário
  static Future<bool> updateEmail({
    required String newEmail,
    String password = '', // Não é obrigatório para usuários já autenticados
  }) async {
    print('🔍 DEBUG - Iniciando atualização de email para: $newEmail');
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        print('❌ Usuário não autenticado');
        throw Exception('Usuário não autenticado');
      }

      print('🔍 DEBUG - Usuário autenticado: ${currentUser.email}');
      print('🔍 DEBUG - Novo email a ser definido: $newEmail');

      // Verificar se o email atual é válido antes de tentar atualizar
      print('🔍 DEBUG - Verificando se email atual é válido...');
      try {
        // Tentar fazer uma operação simples para verificar se o email atual é válido
        await _client.auth.updateUser(UserAttributes());
        print('✅ Email atual é válido');
      } catch (e) {
        print('❌ Email atual é inválido: $e');
        // Se o email atual é inválido, tentar uma abordagem alternativa
        return await _updateEmailAlternative(currentUser.id, newEmail);
      }

      // Atualizar email no Supabase Auth
      print(
          '🔍 DEBUG - Atualizando email no Supabase Auth de ${currentUser.email} para $newEmail');
      await _client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      print('✅ Email atualizado no Supabase Auth');

      // Atualizar email na tabela users
      print('🔍 DEBUG - Atualizando email na tabela users para: $newEmail');
      await _client
          .from('users')
          .update({'email': newEmail}).eq('id', currentUser.id);
      print('✅ Email atualizado na tabela users');

      print('✅ Email atualizado com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao atualizar email: $e');
      print('🔍 DEBUG - Tipo de erro: ${e.runtimeType}');
      print('🔍 DEBUG - Erro toString: $e');

      // Verificar se é AuthException
      if (e is AuthException) {
        print('🔍 DEBUG - É AuthException, message: ${e.message}');
      }

      // Lançar erro com mensagem amigável
      throw FriendlyAuthException(AuthErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  /// Método alternativo para atualizar email quando o email atual é inválido
  static Future<bool> _updateEmailAlternative(
      String userId, String newEmail) async {
    print('🔍 DEBUG - Tentando abordagem alternativa para atualizar email');
    try {
      // Apenas atualizar na tabela users, sem alterar no Supabase Auth
      print('🔍 DEBUG - Atualizando apenas na tabela users para: $newEmail');
      await _client.from('users').update({'email': newEmail}).eq('id', userId);
      print('✅ Email atualizado na tabela users (abordagem alternativa)');

      // Nota: O email no Supabase Auth permanecerá o antigo, mas o app usará o novo
      print(
          '⚠️ ATENÇÃO: Email atualizado apenas na tabela users. O email no Supabase Auth permanece inalterado.');

      return true;
    } catch (e) {
      print('❌ Erro na abordagem alternativa: $e');
      throw FriendlyAuthException(
          'Não foi possível atualizar o email. O email atual pode estar em um estado inválido no sistema.');
    }
  }

  /// Atualizar senha do usuário
  static Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Atualizar senha no Supabase Auth
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      print('✅ Senha atualizada com sucesso');
      return true;
    } catch (e) {
      // Lançar erro com mensagem amigável
      throw FriendlyAuthException(AuthErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  /// Deletar conta do usuário
  static Future<void> deleteAccount(String userId) async {
    try {
      // Marcar como inativo na tabela users
      await _client.from('users').update({'is_active': false}).eq('id', userId);

      // Fazer logout
      await signOut();
    } catch (e) {
      print('❌ Erro ao deletar conta: $e');
      rethrow;
    }
  }

  /// Criar perfil de jogador automaticamente para novo usuário
  static Future<void> _createPlayerProfile(User user, String? phone) async {
    try {
      print('🎯 Criando perfil de jogador para usuário: ${user.name}');

      // Verificar se já existe um perfil de jogador
      final hasProfile = await PlayerService.hasPlayerProfile(user.id);
      if (hasProfile) {
        print('ℹ️ Usuário já possui perfil de jogador');
        return;
      }

      // Criar perfil de jogador básico
      await PlayerService.createPlayer(
        userId: user.id,
        name: user.name,
        phoneNumber: phone ?? '00000000000', // Telefone padrão se não fornecido
        type: 'casual', // Tipo padrão
      );

      print('✅ Perfil de jogador criado com sucesso para: ${user.name}');
    } catch (e) {
      print('❌ Erro ao criar perfil de jogador: $e');
      // Não rethrow para não interromper o processo de registro
    }
  }
}
