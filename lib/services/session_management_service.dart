import '../config/supabase_config.dart';

class SessionManagementService {
  /// Remove todas as sessões existentes de um jogo
  static Future<int> removeAllGameSessions(String gameId) async {
    try {
      print('🗑️ Removendo sessões existentes do jogo $gameId...');

      // Primeiro, contar quantas sessões serão removidas
      final countResponse = await SupabaseConfig.client
          .from('game_sessions')
          .select('id')
          .eq('game_id', gameId);

      final sessionCount = countResponse.length;

      if (sessionCount == 0) {
        print('ℹ️ Nenhuma sessão encontrada para remover');
        return 0;
      }

      // Remover todas as sessões
      await SupabaseConfig.client
          .from('game_sessions')
          .delete()
          .eq('game_id', gameId);

      print('✅ Removidas $sessionCount sessões do jogo $gameId');
      return sessionCount;
    } catch (e) {
      print('❌ Erro ao remover sessões: $e');
      rethrow;
    }
  }

  /// Cria novas sessões baseadas nas configurações do jogo
  static Future<List<Map<String, dynamic>>> createNewSessions(
      Map<String, dynamic> gameData) async {
    try {
      print(
          '📅 Criando novas sessões para jogo com frequência: ${gameData['frequency']}');

      final String frequency = gameData['frequency'] ?? 'Jogo Avulso';

      // Se for jogo avulso, criar apenas uma sessão
      if (frequency == 'Jogo Avulso') {
        return await _createSingleSession(gameData);
      }

      // Para jogos com frequência, criar múltiplas sessões
      return await _createRecurringSessions(gameData);
    } catch (e) {
      print('❌ Erro ao criar novas sessões: $e');
      rethrow;
    }
  }

  /// Cria uma sessão única (jogo avulso)
  static Future<List<Map<String, dynamic>>> _createSingleSession(
      Map<String, dynamic> gameData) async {
    try {
      final sessionData = {
        'game_id': gameData['id'],
        'session_date': gameData['game_date'] ?? _formatDate(DateTime.now()),
        'start_time': gameData['start_time'],
        'end_time': gameData['end_time'],
        'status': 'scheduled'
      };

      final response = await SupabaseConfig.client
          .from('game_sessions')
          .insert([sessionData]).select();

      print('✅ Sessão avulsa criada: ${response.first['id']}');
      return response;
    } catch (e) {
      print('❌ Erro ao criar sessão avulsa: $e');
      rethrow;
    }
  }

  /// Cria sessões recorrentes baseadas na frequência
  static Future<List<Map<String, dynamic>>> _createRecurringSessions(
      Map<String, dynamic> gameData) async {
    try {
      final dayOfWeek = _getDayOfWeekNumber(gameData['day_of_week']);
      final frequency = gameData['frequency'];

      // Calcular a próxima data válida baseada na data atual e no dia da semana
      final currentDate = _calculateNextValidDate(dayOfWeek);

      print(
          '📅 Próxima data válida calculada: ${_formatDate(currentDate)} (${_getDayName(dayOfWeek)})');

      final sessions = <Map<String, dynamic>>[];
      final maxSessions = _getMaxSessionsForFrequency(frequency);

      // Criar sessões baseadas na frequência
      DateTime sessionDate = currentDate;
      for (int i = 0; i < maxSessions; i++) {
        sessions.add({
          'game_id': gameData['id'],
          'session_date': _formatDate(sessionDate),
          'start_time': gameData['start_time'],
          'end_time': gameData['end_time'],
          'status': 'scheduled'
        });

        // Calcular próxima data baseada na frequência
        sessionDate = _calculateNextDate(sessionDate, frequency);
      }

      // Inserir todas as sessões de uma vez
      final response = await SupabaseConfig.client
          .from('game_sessions')
          .insert(sessions)
          .select();

      print(
          '✅ ${response.length} sessões recorrentes criadas para o jogo ${gameData['id']}');
      return response;
    } catch (e) {
      print('❌ Erro ao criar sessões recorrentes: $e');
      rethrow;
    }
  }

  /// Recria todas as sessões de um jogo (remove existentes e cria novas)
  static Future<Map<String, dynamic>> recreateGameSessions(
      String gameId, Map<String, dynamic> gameData) async {
    try {
      print('🔄 Iniciando recriação de sessões para o jogo $gameId...');

      // Remover todas as sessões existentes
      final removedCount = await removeAllGameSessions(gameId);

      // Criar novas sessões baseadas nos dados atuais
      final newSessions = await createNewSessions(gameData);

      print(
          '✅ Recriação concluída: $removedCount removidas, ${newSessions.length} criadas');

      return {
        'game_id': gameId,
        'removed_sessions': removedCount,
        'created_sessions': newSessions.length,
        'success': true,
        'message':
            'Sessões recriadas com sucesso: $removedCount removidas, ${newSessions.length} criadas'
      };
    } catch (e) {
      print('❌ Erro na recriação de sessões: $e');
      return {
        'game_id': gameId,
        'success': false,
        'error': e.toString(),
        'message': 'Erro ao recriar sessões: $e'
      };
    }
  }

  /// Retorna o número máximo de sessões baseado na frequência
  static int _getMaxSessionsForFrequency(String frequency) {
    switch (frequency) {
      case 'Diária':
        return 30; // 1 mês
      case 'Semanal':
        return 52; // 1 ano
      case 'Mensal':
        return 12; // 1 ano
      case 'Anual':
        return 5; // 5 anos
      default:
        return 52; // Padrão: 1 ano
    }
  }

  /// Calcula a próxima data baseada na frequência
  static DateTime _calculateNextDate(DateTime currentDate, String frequency) {
    switch (frequency) {
      case 'Diária':
        return currentDate.add(const Duration(days: 1));
      case 'Semanal':
        return currentDate.add(const Duration(days: 7));
      case 'Mensal':
        return DateTime(
            currentDate.year, currentDate.month + 1, currentDate.day);
      case 'Anual':
        return DateTime(
            currentDate.year + 1, currentDate.month, currentDate.day);
      default:
        return currentDate.add(const Duration(days: 7)); // Padrão semanal
    }
  }

  /// Converte dia da semana para número (1=Segunda, 7=Domingo)
  /// Aceita tanto formato completo ('Quinta-feira') quanto abreviado ('Quinta')
  static int _getDayOfWeekNumber(String? dayName) {
    if (dayName == null) return 1; // Padrão: Segunda-feira

    // Normalizar o nome do dia (remover espaços e converter para minúsculo)
    final normalizedDay = dayName.toLowerCase().trim();

    // Mapear formatos completos e abreviados
    switch (normalizedDay) {
      // Formato completo
      case 'segunda-feira':
      case 'segunda':
        return 1;
      case 'terça-feira':
      case 'terça':
        return 2;
      case 'quarta-feira':
      case 'quarta':
        return 3;
      case 'quinta-feira':
      case 'quinta':
        return 4;
      case 'sexta-feira':
      case 'sexta':
        return 5;
      case 'sábado':
        return 6;
      case 'domingo':
        return 7;
      default:
        print(
            '⚠️ Dia da semana não reconhecido: "$dayName" - usando Segunda-feira como padrão');
        return 1; // Padrão: Segunda-feira
    }
  }

  /// Calcula a próxima data válida baseada no dia da semana
  /// Se hoje é 16/09/2025 (segunda-feira) e o jogo é às quintas-feiras,
  /// retorna 18/09/2025 (quinta-feira)
  static DateTime _calculateNextValidDate(int targetDayOfWeek) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Se hoje já é o dia correto, usar a próxima ocorrência
    int daysToAdd = targetDayOfWeek - today.weekday;

    // Se o dia já passou esta semana, ir para a próxima semana
    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }

    final nextValidDate = today.add(Duration(days: daysToAdd));

    print('📅 Cálculo da próxima data válida:');
    print('   Hoje: ${_formatDate(today)} (${_getDayName(today.weekday)})');
    print('   Dia alvo: ${_getDayName(targetDayOfWeek)}');
    print(
        '   Próxima data: ${_formatDate(nextValidDate)} (${_getDayName(nextValidDate.weekday)})');

    return nextValidDate;
  }

  /// Retorna o nome do dia da semana baseado no número
  static String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Segunda-feira';
      case 2:
        return 'Terça-feira';
      case 3:
        return 'Quarta-feira';
      case 4:
        return 'Quinta-feira';
      case 5:
        return 'Sexta-feira';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Dia inválido';
    }
  }

  /// Formata data para o formato YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
