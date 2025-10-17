import 'game_confirmation_config_model.dart';
import 'confirmation_send_config_model.dart';

class ConfirmationConfigComplete {
  final GameConfirmationConfig gameConfig;
  final List<ConfirmationSendConfig> monthlyConfigs;
  final List<ConfirmationSendConfig> casualConfigs;

  ConfirmationConfigComplete({
    required this.gameConfig,
    required this.monthlyConfigs,
    required this.casualConfigs,
  });

  factory ConfirmationConfigComplete.fromMap(Map<String, dynamic> map) {
    final gameConfig = GameConfirmationConfig.fromMap(map);

    final monthlyConfigs = <ConfirmationSendConfig>[];
    final casualConfigs = <ConfirmationSendConfig>[];

    // Se houver configurações de envio no map
    if (map['send_configs'] != null) {
      final sendConfigs = List<Map<String, dynamic>>.from(map['send_configs']);

      for (final config in sendConfigs) {
        final sendConfig = ConfirmationSendConfig.fromMap(config);
        if (sendConfig.playerType == 'monthly') {
          monthlyConfigs.add(sendConfig);
        } else if (sendConfig.playerType == 'casual') {
          casualConfigs.add(sendConfig);
        }
      }
    }

    return ConfirmationConfigComplete(
      gameConfig: gameConfig,
      monthlyConfigs: monthlyConfigs,
      casualConfigs: casualConfigs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'game_config': gameConfig.toMap(),
      'monthly_configs':
          monthlyConfigs.map((config) => config.toMap()).toList(),
      'casual_configs': casualConfigs.map((config) => config.toMap()).toList(),
    };
  }

  // Validar se as configurações estão corretas
  bool isValid() {
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

  // Obter configuração por tipo e ordem
  ConfirmationSendConfig? getConfigByTypeAndOrder(
      String playerType, int order) {
    final configs = playerType == 'monthly' ? monthlyConfigs : casualConfigs;

    try {
      return configs.firstWhere((config) => config.confirmationOrder == order);
    } catch (e) {
      return null;
    }
  }

  // Obter todas as configurações ordenadas por tipo
  List<ConfirmationSendConfig> getAllConfigsOrdered() {
    final allConfigs = <ConfirmationSendConfig>[];
    allConfigs.addAll(monthlyConfigs);
    allConfigs.addAll(casualConfigs);

    allConfigs.sort((a, b) {
      if (a.playerType != b.playerType) {
        return a.playerType.compareTo(b.playerType);
      }
      return a.confirmationOrder.compareTo(b.confirmationOrder);
    });

    return allConfigs;
  }

  // Obter resumo das configurações
  String getSummary() {
    final monthlyCount = monthlyConfigs.length;
    final casualCount = casualConfigs.length;

    return 'Mensalistas: $monthlyCount confirmações | Avulsos: $casualCount confirmações';
  }

  @override
  String toString() {
    return 'ConfirmationConfigComplete(gameId: ${gameConfig.gameId}, ${getSummary()})';
  }
}
