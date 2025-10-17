class ConfirmationSendConfig {
  final String id;
  final String gameConfirmationConfigId;
  final String playerType; // 'monthly' ou 'casual'
  final int confirmationOrder; // 1, 2, 3...
  final int hoursBeforeGame; // 24, 12, 6...
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConfirmationSendConfig({
    required this.id,
    required this.gameConfirmationConfigId,
    required this.playerType,
    required this.confirmationOrder,
    required this.hoursBeforeGame,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConfirmationSendConfig.fromMap(Map<String, dynamic> map) {
    return ConfirmationSendConfig(
      id: map['id'].toString(),
      gameConfirmationConfigId: map['game_confirmation_config_id'].toString(),
      playerType: map['player_type'] ?? '',
      confirmationOrder: map['confirmation_order'] ?? 1,
      hoursBeforeGame: map['hours_before_game'] ?? 24,
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_confirmation_config_id': gameConfirmationConfigId,
      'player_type': playerType,
      'confirmation_order': confirmationOrder,
      'hours_before_game': hoursBeforeGame,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ConfirmationSendConfig copyWith({
    String? id,
    String? gameConfirmationConfigId,
    String? playerType,
    int? confirmationOrder,
    int? hoursBeforeGame,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConfirmationSendConfig(
      id: id ?? this.id,
      gameConfirmationConfigId:
          gameConfirmationConfigId ?? this.gameConfirmationConfigId,
      playerType: playerType ?? this.playerType,
      confirmationOrder: confirmationOrder ?? this.confirmationOrder,
      hoursBeforeGame: hoursBeforeGame ?? this.hoursBeforeGame,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConfirmationSendConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ConfirmationSendConfig(id: $id, playerType: $playerType, order: $confirmationOrder, hoursBefore: $hoursBeforeGame)';
  }
}
