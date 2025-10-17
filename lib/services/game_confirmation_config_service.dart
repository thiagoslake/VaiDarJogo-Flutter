import '../config/supabase_config.dart';
import '../models/game_confirmation_config_model.dart';
import '../models/confirmation_send_config_model.dart';
import '../models/confirmation_config_complete_model.dart';

class GameConfirmationConfigService {
  static final _client = SupabaseConfig.client;

  /// Obter configuração completa de confirmação de um jogo
  static Future<ConfirmationConfigComplete?> getGameConfirmationConfig(
      String gameId) async {
    try {
      print('🔍 Buscando configuração para o jogo: $gameId');

      // Buscar configuração principal do jogo
      final gameConfigResponse = await _client
          .from('game_confirmation_configs')
          .select('*')
          .eq('game_id', gameId)
          .eq('is_active', true)
          .maybeSingle();

      if (gameConfigResponse == null) {
        print(
            'ℹ️ Nenhuma configuração principal encontrada para o jogo: $gameId');
        return null;
      }

      print('✅ Configuração principal encontrada: ${gameConfigResponse['id']}');
      final gameConfig = GameConfirmationConfig.fromMap(gameConfigResponse);

      // Buscar configurações de envio
      final sendConfigsResponse = await _client
          .from('confirmation_send_configs')
          .select('*')
          .eq('game_confirmation_config_id', gameConfig.id)
          .eq('is_active', true)
          .order('player_type', ascending: true)
          .order('confirmation_order', ascending: true);

      print(
          '📊 Configurações de envio encontradas: ${sendConfigsResponse.length}');

      final monthlyConfigs = <ConfirmationSendConfig>[];
      final casualConfigs = <ConfirmationSendConfig>[];

      for (final configData in sendConfigsResponse) {
        final sendConfig = ConfirmationSendConfig.fromMap(configData);
        if (sendConfig.playerType == 'monthly') {
          monthlyConfigs.add(sendConfig);
          print(
              '📝 Mensalista: Ordem ${sendConfig.confirmationOrder}, ${sendConfig.hoursBeforeGame}h');
        } else if (sendConfig.playerType == 'casual') {
          casualConfigs.add(sendConfig);
          print(
              '📝 Avulso: Ordem ${sendConfig.confirmationOrder}, ${sendConfig.hoursBeforeGame}h');
        }
      }

      print(
          '✅ Configuração completa carregada: ${monthlyConfigs.length} mensalistas, ${casualConfigs.length} avulsos');

      return ConfirmationConfigComplete(
        gameConfig: gameConfig,
        monthlyConfigs: monthlyConfigs,
        casualConfigs: casualConfigs,
      );
    } catch (e) {
      print('❌ Erro ao obter configuração de confirmação: $e');
      return null;
    }
  }

  /// Criar configuração de confirmação para um jogo
  static Future<ConfirmationConfigComplete?> createGameConfirmationConfig({
    required String gameId,
    required List<ConfirmationSendConfig> monthlyConfigs,
    required List<ConfirmationSendConfig> casualConfigs,
  }) async {
    try {
      // Validar configurações
      if (!_validateConfigurations(monthlyConfigs, casualConfigs)) {
        throw Exception(
            'Configurações inválidas: mensalistas devem receber confirmações antes dos avulsos');
      }

      // Criar configuração principal
      final gameConfigData = {
        'game_id': gameId,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final gameConfigResponse = await _client
          .from('game_confirmation_configs')
          .insert(gameConfigData)
          .select()
          .single();

      final gameConfig = GameConfirmationConfig.fromMap(gameConfigResponse);

      // Criar configurações de envio para mensalistas
      for (final config in monthlyConfigs) {
        final sendConfigData = {
          'game_confirmation_config_id': gameConfig.id,
          'player_type': 'monthly',
          'confirmation_order': config.confirmationOrder,
          'hours_before_game': config.hoursBeforeGame,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _client.from('confirmation_send_configs').insert(sendConfigData);
      }

      // Criar configurações de envio para avulsos
      for (final config in casualConfigs) {
        final sendConfigData = {
          'game_confirmation_config_id': gameConfig.id,
          'player_type': 'casual',
          'confirmation_order': config.confirmationOrder,
          'hours_before_game': config.hoursBeforeGame,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _client.from('confirmation_send_configs').insert(sendConfigData);
      }

      // Retornar configuração completa
      return await getGameConfirmationConfig(gameId);
    } catch (e) {
      print('❌ Erro ao criar configuração de confirmação: $e');
      return null;
    }
  }

  /// Atualizar configuração de confirmação de um jogo
  static Future<ConfirmationConfigComplete?> updateGameConfirmationConfig({
    required String gameId,
    required List<ConfirmationSendConfig> monthlyConfigs,
    required List<ConfirmationSendConfig> casualConfigs,
  }) async {
    try {
      // Validar configurações
      if (!_validateConfigurations(monthlyConfigs, casualConfigs)) {
        throw Exception(
            'Configurações inválidas: mensalistas devem receber confirmações antes dos avulsos');
      }

      // Buscar configuração existente
      final existingConfig = await getGameConfirmationConfig(gameId);
      if (existingConfig == null) {
        // Se não existe configuração, criar uma nova
        return await createGameConfirmationConfig(
          gameId: gameId,
          monthlyConfigs: monthlyConfigs,
          casualConfigs: casualConfigs,
        );
      }

      // Primeiro, desativar TODAS as configurações antigas
      await _client.from('confirmation_send_configs').update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('game_confirmation_config_id', existingConfig.gameConfig.id);

      // Aguardar um pouco para garantir que a atualização foi processada
      await Future.delayed(const Duration(milliseconds: 100));

      // Agora inserir as novas configurações usando UPSERT
      final allConfigs = [...monthlyConfigs, ...casualConfigs];

      for (final config in allConfigs) {
        final sendConfigData = {
          'game_confirmation_config_id': existingConfig.gameConfig.id,
          'player_type': config.playerType,
          'confirmation_order': config.confirmationOrder,
          'hours_before_game': config.hoursBeforeGame,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Usar upsert para evitar conflitos de chave única
        await _client.from('confirmation_send_configs').upsert(
              sendConfigData,
              onConflict:
                  'game_confirmation_config_id,player_type,confirmation_order',
            );
      }

      // Atualizar timestamp da configuração principal
      await _client
          .from('game_confirmation_configs')
          .update({'updated_at': DateTime.now().toIso8601String()}).eq(
              'id', existingConfig.gameConfig.id);

      // Retornar configuração atualizada
      return await getGameConfirmationConfig(gameId);
    } catch (e) {
      print('❌ Erro ao atualizar configuração de confirmação: $e');
      return null;
    }
  }

  /// Desativar configuração de confirmação de um jogo
  static Future<bool> deactivateGameConfirmationConfig(String gameId) async {
    try {
      await _client.from('game_confirmation_configs').update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('game_id', gameId);

      return true;
    } catch (e) {
      print('❌ Erro ao desativar configuração de confirmação: $e');
      return false;
    }
  }

  /// Verificar se um jogo tem configuração de confirmação ativa
  static Future<bool> hasActiveConfirmationConfig(String gameId) async {
    try {
      final response = await _client
          .from('game_confirmation_configs')
          .select('id')
          .eq('game_id', gameId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Erro ao verificar configuração ativa: $e');
      return false;
    }
  }

  /// Validar configurações de envio
  static bool _validateConfigurations(
    List<ConfirmationSendConfig> monthlyConfigs,
    List<ConfirmationSendConfig> casualConfigs,
  ) {
    // Verificar se há pelo menos uma configuração para cada tipo
    if (monthlyConfigs.isEmpty || casualConfigs.isEmpty) {
      return false;
    }

    // Verificar se a menor hora dos mensalistas é maior que a maior hora dos avulsos
    // Isso garante que mensalistas sempre recebam confirmações antes dos avulsos
    final monthlyMinHours = monthlyConfigs
        .map((config) => config.hoursBeforeGame)
        .reduce((a, b) => a < b ? a : b);

    final casualMaxHours = casualConfigs
        .map((config) => config.hoursBeforeGame)
        .reduce((a, b) => a > b ? a : b);

    return monthlyMinHours > casualMaxHours;
  }

  /// Obter configurações de envio por tipo
  static Future<List<ConfirmationSendConfig>> getSendConfigsByType(
    String gameId,
    String playerType,
  ) async {
    try {
      final response = await _client
          .from('game_confirmation_configs')
          .select('''
            id,
            confirmation_send_configs(*)
          ''')
          .eq('game_id', gameId)
          .eq('is_active', true)
          .eq('confirmation_send_configs.player_type', playerType)
          .eq('confirmation_send_configs.is_active', true)
          .order('confirmation_send_configs.confirmation_order',
              ascending: true);

      if (response.isEmpty) {
        return [];
      }

      final sendConfigs = <ConfirmationSendConfig>[];
      for (final configData in response.first['confirmation_send_configs']) {
        sendConfigs.add(ConfirmationSendConfig.fromMap(configData));
      }

      return sendConfigs;
    } catch (e) {
      print('❌ Erro ao obter configurações de envio por tipo: $e');
      return [];
    }
  }

  /// Obter estatísticas de configuração
  static Future<Map<String, dynamic>> getConfigStats(String gameId) async {
    try {
      final config = await getGameConfirmationConfig(gameId);
      if (config == null) {
        return {
          'has_config': false,
          'monthly_count': 0,
          'casual_count': 0,
          'is_valid': false,
        };
      }

      return {
        'has_config': true,
        'monthly_count': config.monthlyConfigs.length,
        'casual_count': config.casualConfigs.length,
        'is_valid': config.isValid(),
        'summary': config.getSummary(),
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas de configuração: $e');
      return {
        'has_config': false,
        'monthly_count': 0,
        'casual_count': 0,
        'is_valid': false,
        'error': e.toString(),
      };
    }
  }
}
