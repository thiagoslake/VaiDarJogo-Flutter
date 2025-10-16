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

  /// Remove apenas as sessões futuras de um jogo (mantém o histórico)
  static Future<int> removeFutureGameSessions(String gameId) async {
    try {
      print('🗑️ Removendo sessões futuras do jogo $gameId...');

      // Obter data atual para filtrar apenas sessões futuras
      final today = DateTime.now();
      final todayString = _formatDate(today);

      print('🔍 Data atual para filtro: $todayString');

      // Primeiro, contar quantas sessões futuras serão removidas
      final countResponse = await SupabaseConfig.client
          .from('game_sessions')
          .select('id, session_date')
          .eq('game_id', gameId)
          .gte('session_date', todayString);

      final sessionCount = countResponse.length;

      if (sessionCount == 0) {
        print('ℹ️ Nenhuma sessão futura encontrada para remover');
        return 0;
      }

      // Log das sessões que serão removidas
      for (var session in countResponse) {
        print('   📅 Sessão futura a ser removida: ${session['session_date']}');
      }

      // Remover apenas as sessões futuras
      await SupabaseConfig.client
          .from('game_sessions')
          .delete()
          .eq('game_id', gameId)
          .gte('session_date', todayString);

      print('✅ Removidas $sessionCount sessões futuras do jogo $gameId');
      print('📚 Histórico de sessões passadas foi preservado');
      return sessionCount;
    } catch (e) {
      print('❌ Erro ao remover sessões futuras: $e');
      rethrow;
    }
  }

  /// Cria novas sessões baseadas nas configurações do jogo
  static Future<List<Map<String, dynamic>>> createNewSessions(
      Map<String, dynamic> gameData) async {
    try {
      print(
          '📅 Criando novas sessões para jogo com frequência: ${gameData['frequency']}');

      // Verificar se o jogo não está deletado
      if (gameData['id'] != null) {
        final gameStatus = await _getGameStatus(gameData['id']);
        if (gameStatus == 'deleted') {
          print('❌ Não é possível criar sessões para um jogo deletado');
          throw Exception(
              'Não é possível criar sessões para um jogo que foi deletado');
        }
      }

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
        'status': 'active'
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

      // Calcular a próxima data válida baseada na data de criação do jogo e no dia da semana
      final gameCreationDate = gameData['created_at'] != null
          ? DateTime.parse(gameData['created_at'])
          : null;
      final currentDate = _calculateNextValidDate(dayOfWeek,
          gameCreationDate: gameCreationDate);

      print(
          '📅 Próxima data válida calculada: ${_formatDate(currentDate)} (${_getDayName(dayOfWeek)})');

      final sessions = <Map<String, dynamic>>[];

      // Verificar se há data final definida
      DateTime? endDate;
      if (gameData['end_date'] != null) {
        endDate = DateTime.parse(gameData['end_date']);
        print('📅 Data limite definida: ${_formatDate(endDate)}');

        // Validar se a data limite não é anterior à data atual
        if (endDate.isBefore(currentDate)) {
          print(
              '⚠️ Data limite ${_formatDate(endDate)} é anterior à data de início ${_formatDate(currentDate)}');
          // Ajustar a data limite para ser pelo menos a data atual
          endDate = currentDate;
          print('📅 Data limite ajustada para: ${_formatDate(endDate)}');
        }

        // Validar se a data limite é muito próxima da data atual
        final daysDifference = endDate.difference(currentDate).inDays;
        if (daysDifference < 1) {
          print(
              '⚠️ Data limite muito próxima da data atual - apenas 1 sessão será criada');
        }
      } else {
        print('⚠️ Nenhuma data limite definida - usando valores padrão');
      }

      final maxSessions = _getMaxSessionsForFrequency(frequency,
          endDate: endDate, startDate: currentDate);

      print('📊 Máximo de sessões calculado: $maxSessions');

      // Criar sessões baseadas na frequência
      DateTime sessionDate = currentDate;
      int sessionsCreated = 0;

      for (int i = 0; i < maxSessions; i++) {
        // Parar se a data da sessão ultrapassar a data final
        if (endDate != null && sessionDate.isAfter(endDate)) {
          print(
              '🛑 Parando criação de sessões: data ${_formatDate(sessionDate)} ultrapassa data limite ${_formatDate(endDate)}');
          break;
        }

        // Log quando chegamos à data final
        if (endDate != null &&
            sessionDate.year == endDate.year &&
            sessionDate.month == endDate.month &&
            sessionDate.day == endDate.day) {
          print(
              '📅 Última sessão criada para a data limite: ${_formatDate(sessionDate)}');
        }

        sessions.add({
          'game_id': gameData['id'],
          'session_date': _formatDate(sessionDate),
          'start_time': gameData['start_time'],
          'end_time': gameData['end_time'],
          'status': 'active'
        });

        sessionsCreated++;
        print(
            '📅 Sessão $sessionsCreated criada para: ${_formatDate(sessionDate)}');

        // Calcular próxima data baseada na frequência
        sessionDate = _calculateNextDate(sessionDate, frequency);

        // Verificar se a próxima data ultrapassaria a data limite
        if (endDate != null && sessionDate.isAfter(endDate)) {
          print(
              '🛑 Próxima data ${_formatDate(sessionDate)} ultrapassaria data limite ${_formatDate(endDate)} - parando criação');
          break;
        }
      }

      // Validar se pelo menos uma sessão foi criada
      if (sessionsCreated == 0) {
        print(
            '⚠️ Nenhuma sessão foi criada - verifique as configurações de data e frequência');
      }

      print(
          '📊 Total de sessões criadas: $sessionsCreated de $maxSessions calculadas');

      // Inserir todas as sessões de uma vez
      if (sessions.isNotEmpty) {
        final response = await SupabaseConfig.client
            .from('game_sessions')
            .insert(sessions)
            .select();

        print(
            '✅ ${response.length} sessões recorrentes criadas para o jogo ${gameData['id']}');
        return response;
      } else {
        print(
            '⚠️ Nenhuma sessão foi criada - verifique as configurações de data');
        // Retornar uma lista vazia em vez de lançar erro
        return [];
      }
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

      // Verificar se o jogo não está deletado
      final gameStatus = await _getGameStatus(gameId);
      if (gameStatus == 'deleted') {
        print('❌ Não é possível recriar sessões para um jogo deletado');
        return {
          'game_id': gameId,
          'success': false,
          'error': 'Jogo deletado',
          'message':
              'Não é possível recriar sessões para um jogo que foi deletado'
        };
      }

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
  static int _getMaxSessionsForFrequency(String frequency,
      {DateTime? endDate, DateTime? startDate}) {
    // Se há data final, calcular baseado na diferença de datas
    if (endDate != null && startDate != null) {
      final daysDifference = endDate.difference(startDate).inDays;
      print(
          '📊 Diferença de dias entre ${_formatDate(startDate)} e ${_formatDate(endDate)}: $daysDifference dias');

      switch (frequency) {
        case 'Diária':
          return daysDifference + 1; // Incluir o dia final
        case 'Semanal':
          return (daysDifference / 7).ceil() + 1; // Incluir a semana final
        case 'Mensal':
          return (daysDifference / 30).ceil() + 1; // Aproximação mensal
        case 'Anual':
          return (daysDifference / 365).ceil() + 1; // Aproximação anual
        default:
          return (daysDifference / 7).ceil() + 1; // Padrão semanal
      }
    }

    // Fallback para valores padrão se não há data final
    print('⚠️ Usando valores padrão para frequência: $frequency');
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
        // Lidar corretamente com meses de diferentes tamanhos
        int nextMonth = currentDate.month + 1;
        int nextYear = currentDate.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }

        // Verificar se o dia existe no próximo mês
        int day = currentDate.day;
        int daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        if (day > daysInNextMonth) {
          day = daysInNextMonth;
        }

        return DateTime(nextYear, nextMonth, day);
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

  /// Calcula a próxima data válida baseada no dia da semana e data de criação do jogo
  /// Se a data de criação é o dia correto, retorna a data de criação
  /// Se não, retorna a próxima ocorrência após a data de criação
  static DateTime _calculateNextValidDate(int targetDayOfWeek,
      {DateTime? gameCreationDate}) {
    // Usar a data de criação do jogo como referência, ou hoje se não fornecida
    final referenceDate = gameCreationDate ?? DateTime.now();
    final referenceDay =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

    print('📅 Cálculo da próxima data válida:');
    print(
        '   Data de referência: ${_formatDate(referenceDay)} (${_getDayName(referenceDay.weekday)})');
    print('   Dia alvo: ${_getDayName(targetDayOfWeek)}');

    // Se a data de referência já é o dia correto, usar ela
    if (referenceDay.weekday == targetDayOfWeek) {
      print(
          '   ✅ A data de referência é o dia correto! Usando como primeira sessão.');
      return referenceDay;
    }

    // Se a data de referência não é o dia correto, calcular a próxima ocorrência
    int daysToAdd = targetDayOfWeek - referenceDay.weekday;

    // Se o dia já passou na semana da data de referência, ir para a próxima semana
    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }

    final nextValidDate = referenceDay.add(Duration(days: daysToAdd));

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

  /// Obtém o status de um jogo
  static Future<String?> _getGameStatus(String gameId) async {
    try {
      final response = await SupabaseConfig.client
          .from('games')
          .select('status')
          .eq('id', gameId)
          .maybeSingle();

      return response?['status'] as String?;
    } catch (e) {
      print('❌ Erro ao obter status do jogo: $e');
      return null;
    }
  }
}
