class Player {
  final String id;
  final String name;
  final String phoneNumber;
  final DateTime? birthDate;
  final String? primaryPosition;
  final String? secondaryPosition;
  final String? preferredFoot;
  final String status; // 'active', 'inactive', 'suspended'
  final String? userId; // Referência ao usuário
  final DateTime createdAt;
  final DateTime updatedAt;

  Player({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.birthDate,
    this.primaryPosition,
    this.secondaryPosition,
    this.preferredFoot,
    required this.status,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      birthDate:
          map['birth_date'] != null ? DateTime.parse(map['birth_date']) : null,
      primaryPosition: map['primary_position'],
      secondaryPosition: map['secondary_position'],
      preferredFoot: map['preferred_foot'],
      status: map['status'] ?? 'active',
      userId: map['user_id']?.toString(),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'primary_position': primaryPosition,
      'secondary_position': secondaryPosition,
      'preferred_foot': preferredFoot,
      'status': status,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    DateTime? birthDate,
    String? primaryPosition,
    String? secondaryPosition,
    String? preferredFoot,
    String? status,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      primaryPosition: primaryPosition ?? this.primaryPosition,
      secondaryPosition: secondaryPosition ?? this.secondaryPosition,
      preferredFoot: preferredFoot ?? this.preferredFoot,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Player(id: $id, name: $name, status: $status)';
  }
}
