class NotificationConfig {
  final String id;
  final String userId;
  final bool gameReminders;
  final bool gameCancellations;
  final bool gameUpdates;
  final bool playerRequests;
  final bool adminNotifications;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final int reminderTime; // em minutos antes do jogo
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Campos adicionais para compatibilidade
  final bool enabled;
  final int advanceHours;
  final bool whatsappEnabled;
  final bool emailEnabled;
  final bool pushEnabled;
  final List<String> gameTypes;
  final List<String> daysOfWeek;
  final List<String> timeSlots;
  final String? whatsappNumber;
  final String? email;

  NotificationConfig({
    required this.id,
    required this.userId,
    this.gameReminders = true,
    this.gameCancellations = true,
    this.gameUpdates = true,
    this.playerRequests = true,
    this.adminNotifications = true,
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.smsNotifications = false,
    this.reminderTime = 30, // 30 minutos por padrão
    required this.createdAt,
    required this.updatedAt,
    // Campos adicionais para compatibilidade
    this.enabled = true,
    this.advanceHours = 1,
    this.whatsappEnabled = false,
    this.emailEnabled = false,
    this.pushEnabled = true,
    this.gameTypes = const [],
    this.daysOfWeek = const [],
    this.timeSlots = const [],
    this.whatsappNumber,
    this.email,
    // Parâmetro de compatibilidade
    String? playerId,
  });

  factory NotificationConfig.fromMap(Map<String, dynamic> map) {
    return NotificationConfig(
      id: map['id'].toString(),
      userId: map['user_id'] ?? '',
      gameReminders: map['game_reminders'] ?? true,
      gameCancellations: map['game_cancellations'] ?? true,
      gameUpdates: map['game_updates'] ?? true,
      playerRequests: map['player_requests'] ?? true,
      adminNotifications: map['admin_notifications'] ?? true,
      pushNotifications: map['push_notifications'] ?? true,
      emailNotifications: map['email_notifications'] ?? false,
      smsNotifications: map['sms_notifications'] ?? false,
      reminderTime: map['reminder_time'] ?? 30,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      // Campos adicionais para compatibilidade
      enabled: map['enabled'] ?? true,
      advanceHours: map['advance_hours'] ?? 1,
      whatsappEnabled: map['whatsapp_enabled'] ?? false,
      emailEnabled: map['email_enabled'] ?? false,
      pushEnabled: map['push_enabled'] ?? true,
      gameTypes: List<String>.from(map['game_types'] ?? []),
      daysOfWeek: List<String>.from(map['days_of_week'] ?? []),
      timeSlots: List<String>.from(map['time_slots'] ?? []),
      whatsappNumber: map['whatsapp_number'],
      email: map['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'game_reminders': gameReminders,
      'game_cancellations': gameCancellations,
      'game_updates': gameUpdates,
      'player_requests': playerRequests,
      'admin_notifications': adminNotifications,
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'sms_notifications': smsNotifications,
      'reminder_time': reminderTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NotificationConfig copyWith({
    String? id,
    String? userId,
    bool? gameReminders,
    bool? gameCancellations,
    bool? gameUpdates,
    bool? playerRequests,
    bool? adminNotifications,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    int? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gameReminders: gameReminders ?? this.gameReminders,
      gameCancellations: gameCancellations ?? this.gameCancellations,
      gameUpdates: gameUpdates ?? this.gameUpdates,
      playerRequests: playerRequests ?? this.playerRequests,
      adminNotifications: adminNotifications ?? this.adminNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationConfig(id: $id, userId: $userId, gameReminders: $gameReminders)';
  }
}
