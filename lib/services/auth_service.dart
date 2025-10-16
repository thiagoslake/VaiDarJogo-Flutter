import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_model.dart';
import '../config/supabase_config.dart';
import '../utils/auth_error_handler.dart';
import '../utils/friendly_auth_exception.dart';
import '../utils/error_handler.dart';
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
    // Campos adicionais do jogador
    DateTime? birthDate,
    String? primaryPosition,
    String? secondaryPosition,
    String? preferredFoot,
  }) async {
    try {
      // Registrar no Supabase Auth com telefone nos metadados
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      print('🔍 DEBUG - Usuário registrado no Auth: ${response.user?.email}');
      print('🔍 DEBUG - Metadados enviados: name=$name, phone=$phone');
      print('🔍 DEBUG - Telefone será salvo em users.phone via trigger');

      if (response.user != null) {
        // Aguardar um pouco para o trigger processar (se existir)
        await Future.delayed(const Duration(seconds: 2));

        try {
          // Buscar o usuário criado pelo trigger
          final userData = await _client
              .from('users')
              .select('*')
              .eq('id', response.user!.id)
              .single();

          print('🔍 DEBUG - Usuário encontrado na tabela users: $userData');
          print('🔍 DEBUG - Telefone na tabela users: ${userData['phone']}');

          // Verificar se o telefone foi inserido pelo trigger
          User user;
          if (userData['phone'] == null || userData['phone'] == '') {
            print(
                '⚠️ Telefone não foi inserido pelo trigger, inserindo manualmente...');

            // Atualizar o telefone na tabela users
            await _client
                .from('users')
                .update({'phone': phone}).eq('id', response.user!.id);

            print('✅ Telefone inserido manualmente na tabela users: $phone');

            // Buscar novamente os dados atualizados
            final updatedUserData = await _client
                .from('users')
                .select('*')
                .eq('id', response.user!.id)
                .single();

            user = User.fromMap(updatedUserData);
          } else {
            print('✅ Telefone salvo em users.phone via trigger');
            user = User.fromMap(userData);
          }

          // Criar perfil de jogador automaticamente
          await _createPlayerProfile(
            user,
            phone,
            birthDate: birthDate,
            primaryPosition: primaryPosition,
            secondaryPosition: secondaryPosition,
            preferredFoot: preferredFoot,
          );

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

          print('🔍 DEBUG - Criando usuário manualmente: $userData');
          print('🔍 DEBUG - Telefone a ser inserido: $phone');
          print('✅ Telefone será salvo em users.phone via inserção manual');

          await _client.from('users').insert(userData);

          final user = User.fromMap(userData);

          // Criar perfil de jogador automaticamente
          await _createPlayerProfile(
            user,
            phone,
            birthDate: birthDate,
            primaryPosition: primaryPosition,
            secondaryPosition: secondaryPosition,
            preferredFoot: preferredFoot,
          );

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

        print('🔍 DEBUG - Dados do usuário carregados: $userData');
        print('🔍 DEBUG - Telefone do usuário: ${userData['phone']}');

        return User.fromMap(userData);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao obter usuário atual: $e');
      // Se não conseguir buscar da tabela users, tentar criar um usuário básico
      try {
        final session = _client.auth.currentSession;
        if (session?.user != null) {
          final basicUser = User(
            id: session!.user.id,
            email: session.user.email ?? '',
            name: session.user.userMetadata?['name'] ?? 'Usuário',
            phone: session.user.userMetadata?['phone'],
            createdAt: DateTime.now(),
            isActive: true,
          );
          return basicUser;
        }
      } catch (fallbackError) {
        print('❌ Erro no fallback do usuário: $fallbackError');
      }
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
      print('🔍 DEBUG - Iniciando atualização de perfil para userId: $userId');
      print('🔍 DEBUG - Dados a atualizar: name=$name, phone=$phone');

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;

      if (updateData.isNotEmpty) {
        // Atualizar dados na tabela users
        await _client.from('users').update(updateData).eq('id', userId);
        print('✅ Dados atualizados na tabela users');

        // Se telefone foi alterado, sincronizar com a tabela players
        if (phone != null) {
          print('🔍 DEBUG - Sincronizando telefone com tabela players');

          try {
            // Buscar o player associado ao usuário
            final player = await PlayerService.getPlayerByUserId(userId);

            if (player != null) {
              // Verificar se o telefone já está sendo usado por outro jogador
              final isPhoneInUse =
                  await PlayerService.isPhoneNumberInUse(phone);

              if (isPhoneInUse && player.phoneNumber != phone) {
                print(
                    '⚠️ Telefone $phone já está sendo usado por outro jogador');
                print(
                    'ℹ️ Mantendo telefone atual na tabela players para evitar conflito');
              } else {
                // Atualizar telefone na tabela players
                await _client
                    .from('players')
                    .update({'phone_number': phone}).eq('user_id', userId);

                print('✅ Telefone sincronizado na tabela players: $phone');
              }
            } else {
              print('ℹ️ Usuário não possui perfil de jogador ainda');
            }
          } catch (e) {
            print('⚠️ Erro ao sincronizar telefone com players: $e');
            // Não falhar a atualização do usuário por causa disso
          }
        }

        // Retornar usuário atualizado
        final userData =
            await _client.from('users').select('*').eq('id', userId).single();

        print('✅ Perfil de usuário atualizado com sucesso');
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
      throw const FriendlyAuthException(
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
  static Future<void> _createPlayerProfile(
    User user,
    String? phone, {
    DateTime? birthDate,
    String? primaryPosition,
    String? secondaryPosition,
    String? preferredFoot,
  }) async {
    try {
      print('🎯 Criando perfil de jogador para usuário: ${user.name}');

      // Verificar se já existe um perfil de jogador
      final hasProfile = await PlayerService.hasPlayerProfile(user.id);
      if (hasProfile) {
        print('ℹ️ Usuário já possui perfil de jogador');
        return;
      }

      // Definir telefone para usar - priorizar o telefone fornecido
      String phoneToUse = phone ?? '00000000000';

      // Se telefone foi fornecido, verificar se já está em uso
      if (phone != null && phone.isNotEmpty && phone != '00000000000') {
        final isPhoneInUse = await PlayerService.isPhoneNumberInUse(phone);
        if (isPhoneInUse) {
          print('⚠️ Telefone $phone já está sendo usado por outro jogador');
          print('ℹ️ Usando telefone padrão para evitar conflito');
          phoneToUse = '00000000000';
        } else {
          print('✅ Telefone $phone disponível para uso');
        }
      }

      // Criar perfil de jogador básico
      await PlayerService.createPlayer(
        userId: user.id,
        name: user.name,
        phoneNumber: phoneToUse,
        birthDate: birthDate,
        primaryPosition: primaryPosition,
        secondaryPosition: secondaryPosition,
        preferredFoot: preferredFoot,
      );

      print('✅ Perfil de jogador criado com sucesso para: ${user.name}');
      print('✅ Telefone salvo na tabela players.phone_number: $phoneToUse');
      print('🎯 INSERÇÃO DUPLA CONCLUÍDA: users.phone + players.phone_number');

      if (phoneToUse == '00000000000' && phone != null && phone.isNotEmpty) {
        print(
            'ℹ️ Telefone $phone estava em uso, usando telefone padrão. Usuário pode atualizar depois.');
      }
    } catch (e) {
      print('❌ Erro ao criar perfil de jogador: $e');

      // Se for erro de telefone duplicado, mostrar mensagem específica
      if (ErrorHandler.isPhoneDuplicateError(e)) {
        print(
            '⚠️ Telefone duplicado detectado durante criação automática do perfil');
        // Tentar criar com telefone padrão
        try {
          await PlayerService.createPlayer(
            userId: user.id,
            name: user.name,
            phoneNumber: '00000000000',
          );
          print('✅ Perfil criado com telefone padrão após conflito');
        } catch (retryError) {
          print(
              '❌ Falha ao criar perfil mesmo com telefone padrão: $retryError');
        }
      } else {
        // Para outros erros, também não rethrow para não interromper o registro
        print('⚠️ Outro erro na criação do perfil, continuando com o registro');
      }
    }
  }
}
