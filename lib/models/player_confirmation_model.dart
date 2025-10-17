class PlayerConfirmation {
  final String id;
  final String gameId;
  final String playerId;
  final String confirmationType; // 'confirmed', 'declined', 'pending'
  final DateTime? confirmedAt;
  final String? confirmationMethod; // 'whatsapp', 'manual', 'app'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlayerConfirmation({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.confirmationType,
    this.confirmedAt,
    this.confirmationMethod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlayerConfirmation.fromMap(Map<String, dynamic> map) {
    return PlayerConfirmation(
      id: map['id'].toString(),
      gameId: map['game_id'].toString(),
      playerId: map['player_id'].toString(),
      confirmationType: map['confirmation_type'] ?? 'pending',
      confirmedAt: map['confirmed_at'] != null
          ? DateTime.parse(map['confirmed_at'])
          : null,
      confirmationMethod: map['confirmation_method'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'player_id': playerId,
      'confirmation_type': confirmationType,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'confirmation_method': confirmationMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PlayerConfirmation copyWith({
    String? id,
    String? gameId,
    String? playerId,
    String? confirmationType,
    DateTime? confirmedAt,
    String? confirmationMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlayerConfirmation(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      playerId: playerId ?? this.playerId,
      confirmationType: confirmationType ?? this.confirmationType,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmationMethod: confirmationMethod ?? this.confirmationMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerConfirmation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlayerConfirmation(id: $id, gameId: $gameId, playerId: $playerId, type: $confirmationType)';
  }
}
