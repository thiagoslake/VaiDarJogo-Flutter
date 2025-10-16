class Notification {
  final String id;
  final String playerId;
  final String gameId;
  final String
      type; // 'game_reminder', 'game_confirmation', 'game_cancelled', 'game_updated'
  final String title;
  final String message;
  final String status; // 'pending', 'sent', 'delivered', 'failed', 'read'
  final List<String> channels; // ['whatsapp', 'email', 'push']
  final Map<String, dynamic> metadata; // Dados específicos do canal
  final DateTime scheduledFor;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? errorMessage;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notification({
    required this.id,
    required this.playerId,
    required this.gameId,
    required this.type,
    required this.title,
    required this.message,
    required this.status,
    required this.channels,
    required this.metadata,
    required this.scheduledFor,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.errorMessage,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'].toString(),
      playerId: map['player_id'].toString(),
      gameId: map['game_id'].toString(),
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      channels: List<String>.from(map['channels'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      scheduledFor: DateTime.parse(map['scheduled_for']),
      sentAt: map['sent_at'] != null ? DateTime.parse(map['sent_at']) : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.parse(map['delivered_at'])
          : null,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      errorMessage: map['error_message'],
      retryCount: map['retry_count'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'player_id': playerId,
      'game_id': gameId,
      'type': type,
      'title': title,
      'message': message,
      'status': status,
      'channels': channels,
      'metadata': metadata,
      'scheduled_for': scheduledFor.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'error_message': errorMessage,
      'retry_count': retryCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Notification copyWith({
    String? id,
    String? playerId,
    String? gameId,
    String? type,
    String? title,
    String? message,
    String? status,
    List<String>? channels,
    Map<String, dynamic>? metadata,
    DateTime? scheduledFor,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? errorMessage,
    int? retryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      gameId: gameId ?? this.gameId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      status: status ?? this.status,
      channels: channels ?? this.channels,
      metadata: metadata ?? this.metadata,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Notification(id: $id, type: $type, status: $status, channels: $channels)';
  }
}

class NotificationTemplate {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, String> variables; // Variáveis que podem ser substituídas
  final List<String> requiredChannels;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.variables,
    required this.requiredChannels,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationTemplate.fromMap(Map<String, dynamic> map) {
    return NotificationTemplate(
      id: map['id'].toString(),
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      variables: Map<String, String>.from(map['variables'] ?? {}),
      requiredChannels: List<String>.from(map['required_channels'] ?? []),
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'variables': variables,
      'required_channels': requiredChannels,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Substituir variáveis na mensagem
  String formatMessage(Map<String, String> values) {
    String formattedMessage = message;
    values.forEach((key, value) {
      formattedMessage = formattedMessage.replaceAll('{{$key}}', value);
    });
    return formattedMessage;
  }

  String formatTitle(Map<String, String> values) {
    String formattedTitle = title;
    values.forEach((key, value) {
      formattedTitle = formattedTitle.replaceAll('{{$key}}', value);
    });
    return formattedTitle;
  }
}

class NotificationLog {
  final String id;
  final String notificationId;
  final String channel;
  final String status;
  final String? errorMessage;
  final Map<String, dynamic>? response;
  final DateTime timestamp;

  NotificationLog({
    required this.id,
    required this.notificationId,
    required this.channel,
    required this.status,
    this.errorMessage,
    this.response,
    required this.timestamp,
  });

  factory NotificationLog.fromMap(Map<String, dynamic> map) {
    return NotificationLog(
      id: map['id'].toString(),
      notificationId: map['notification_id'].toString(),
      channel: map['channel'] ?? '',
      status: map['status'] ?? '',
      errorMessage: map['error_message'],
      response: map['response'] != null
          ? Map<String, dynamic>.from(map['response'])
          : null,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notification_id': notificationId,
      'channel': channel,
      'status': status,
      'error_message': errorMessage,
      'response': response,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
