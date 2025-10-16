class GamePlayer {
  final String id;
  final String gameId;
  final String playerId;
  final String playerType; // 'monthly' ou 'casual'
  final String status; // 'active', 'inactive', 'suspended'
  final bool isAdmin; // Indica se é administrador do jogo
  final DateTime joinedAt;
  final DateTime? updatedAt;

  GamePlayer({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.playerType,
    required this.status,
    required this.isAdmin,
    required this.joinedAt,
    this.updatedAt,
  });

  factory GamePlayer.fromMap(Map<String, dynamic> map) {
    return GamePlayer(
      id: map['id'].toString(),
      gameId: map['game_id'].toString(),
      playerId: map['player_id'].toString(),
      playerType: map['player_type'] ?? 'casual',
      status: map['status'] ?? 'active',
      isAdmin: map['is_admin'] ?? false,
      joinedAt: DateTime.parse(map['joined_at']),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'player_id': playerId,
      'player_type': playerType,
      'status': status,
      'is_admin': isAdmin,
      'joined_at': joinedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  GamePlayer copyWith({
    String? id,
    String? gameId,
    String? playerId,
    String? playerType,
    String? status,
    bool? isAdmin,
    DateTime? joinedAt,
    DateTime? updatedAt,
  }) {
    return GamePlayer(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      playerId: playerId ?? this.playerId,
      playerType: playerType ?? this.playerType,
      status: status ?? this.status,
      isAdmin: isAdmin ?? this.isAdmin,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GamePlayer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GamePlayer(id: $id, gameId: $gameId, playerId: $playerId, playerType: $playerType, status: $status, isAdmin: $isAdmin)';
  }

  // Métodos de conveniência
  bool get isMonthly => playerType == 'monthly';
  bool get isCasual => playerType == 'casual';
  bool get isActive => status == 'active';
  bool get isInactive => status == 'inactive';
  bool get isSuspended => status == 'suspended';
}
