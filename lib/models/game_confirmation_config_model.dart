class GameConfirmationConfig {
  final String id;
  final String gameId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameConfirmationConfig({
    required this.id,
    required this.gameId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GameConfirmationConfig.fromMap(Map<String, dynamic> map) {
    return GameConfirmationConfig(
      id: map['id'].toString(),
      gameId: map['game_id'].toString(),
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GameConfirmationConfig copyWith({
    String? id,
    String? gameId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameConfirmationConfig(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameConfirmationConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GameConfirmationConfig(id: $id, gameId: $gameId, isActive: $isActive)';
  }
}
