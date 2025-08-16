import 'user_role.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? photoUrl;
  final String? phoneNumber;
  final String? employeeId;
  final String? address;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.photoUrl,
    this.phoneNumber,
    this.employeeId,
    this.address,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? photoUrl,
    String? phoneNumber,
    String? employeeId,
    String? address,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      employeeId: employeeId ?? this.employeeId,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'employeeId': employeeId,
      'address': address,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: UserRole.values.firstWhere((r) => r.name == json['role']),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      employeeId: json['employeeId'] as String?,
      address: json['address'] as String?,
    );
  }
}