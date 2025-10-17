class ConfirmationSendLog {
  final String id;
  final String gameId;
  final String playerId;
  final String? sendConfigId;
  final DateTime scheduledFor;
  final DateTime? sentAt;
  final String status; // 'pending', 'sent', 'failed', 'cancelled'
  final String? errorMessage;
  final String? channel; // 'whatsapp', 'email', 'push'
  final String? messageContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConfirmationSendLog({
    required this.id,
    required this.gameId,
    required this.playerId,
    this.sendConfigId,
    required this.scheduledFor,
    this.sentAt,
    required this.status,
    this.errorMessage,
    this.channel,
    this.messageContent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConfirmationSendLog.fromMap(Map<String, dynamic> map) {
    return ConfirmationSendLog(
      id: map['id'].toString(),
      gameId: map['game_id'].toString(),
      playerId: map['player_id'].toString(),
      sendConfigId: map['send_config_id']?.toString(),
      scheduledFor: DateTime.parse(map['scheduled_for']),
      sentAt: map['sent_at'] != null ? DateTime.parse(map['sent_at']) : null,
      status: map['status'] ?? 'pending',
      errorMessage: map['error_message'],
      channel: map['channel'],
      messageContent: map['message_content'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'player_id': playerId,
      'send_config_id': sendConfigId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'status': status,
      'error_message': errorMessage,
      'channel': channel,
      'message_content': messageContent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ConfirmationSendLog copyWith({
    String? id,
    String? gameId,
    String? playerId,
    String? sendConfigId,
    DateTime? scheduledFor,
    DateTime? sentAt,
    String? status,
    String? errorMessage,
    String? channel,
    String? messageContent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConfirmationSendLog(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      playerId: playerId ?? this.playerId,
      sendConfigId: sendConfigId ?? this.sendConfigId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      channel: channel ?? this.channel,
      messageContent: messageContent ?? this.messageContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConfirmationSendLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ConfirmationSendLog(id: $id, gameId: $gameId, playerId: $playerId, status: $status)';
  }
}
