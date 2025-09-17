class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'].toString(),
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      createdAt: DateTime.parse(map['created_at']),
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'])
          : null,
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name)';
  }
}

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Permitir null explícito para limpar erro
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  String toString() {
    return 'AuthState(user: $user, isLoading: $isLoading, error: $error, isAuthenticated: $isAuthenticated)';
  }
}
