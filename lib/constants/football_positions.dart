/// Constantes para posições do Futebol 7
class FootballPositions {
  /// Posições do Futebol 7
  static const List<String> positions = [
    'Goleiro',
    'Fixo',
    'Ala Direita',
    'Ala Esquerda',
    'Meio Direita',
    'Meio Esquerda',
    'Pivô',
  ];

  /// Pés preferidos
  static const List<String> preferredFeet = [
    'Direita',
    'Esquerda',
    'Ambidestro',
  ];

  /// Posições com "Nenhuma" para posição secundária
  static List<String> get secondaryPositions => ['Nenhuma', ...positions];

  /// Descrição das posições do Futebol 7
  static const Map<String, String> positionDescriptions = {
    'Goleiro': 'Responsável por defender o gol e organizar a defesa',
    'Fixo': 'Zagueiro central, último homem da defesa',
    'Ala Direita': 'Lateral direito, atua na lateral direita do campo',
    'Ala Esquerda': 'Lateral esquerdo, atua na lateral esquerda do campo',
    'Meio Direita': 'Meio-campo direito, constrói jogadas pelo lado direito',
    'Meio Esquerda': 'Meio-campo esquerdo, constrói jogadas pelo lado esquerdo',
    'Pivô': 'Atacante central, responsável por finalizar as jogadas',
  };

  /// Obter descrição de uma posição
  static String getPositionDescription(String position) {
    return positionDescriptions[position] ?? 'Posição não definida';
  }

  /// Verificar se uma posição é válida
  static bool isValidPosition(String position) {
    return positions.contains(position);
  }
}
