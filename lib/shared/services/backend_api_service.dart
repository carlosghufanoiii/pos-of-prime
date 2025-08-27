import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../utils/logger.dart';

/// Backend API Service for Prime POS
/// Handles communication with Node.js/Express backend
class BackendApiService {
  static const String _baseUrl = 'http://localhost:3001/api';
  static const String _healthUrl = 'http://localhost:3001/health';
  
  /// Get authorization headers with Firebase ID token
  static Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Check backend health and mode
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(Uri.parse(_healthUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Logger.info(
          'Backend health check: ${data['mode']} mode',
          tag: 'BackendApiService',
        );
        return data;
      }
      
      throw Exception('Backend health check failed: ${response.statusCode}');
    } catch (e) {
      Logger.error(
        'Backend health check error',
        error: e,
        tag: 'BackendApiService',
      );
      rethrow;
    }
  }

  /// Create a new user with proper role assignment
  static Future<AppUser?> createUser({
    required String email,
    required String password,
    required String name,
    UserRole? role,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final body = json.encode({
        'email': email,
        'password': password,
        'name': name,
        if (role != null) 'role': role.name,
      });

      Logger.info(
        'Creating user: $email with role: ${role?.name ?? 'default (waiter)'}',
        tag: 'BackendApiService',
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final userData = data['user'];
        
        Logger.info(
          'User created successfully: ${userData['email']} with role: ${userData['role']}',
          tag: 'BackendApiService',
        );
        
        return AppUser(
          id: userData['id'],
          email: userData['email'],
          name: userData['name'],
          role: UserRole.values.firstWhere(
            (r) => r.name == userData['role'],
            orElse: () => UserRole.waiter,
          ),
          isActive: userData['isActive'] ?? true,
          createdAt: DateTime.parse(userData['createdAt'] ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.parse(userData['updatedAt'] ?? DateTime.now().toIso8601String()),
        );
      }
      
      final errorData = json.decode(response.body);
      throw Exception('Failed to create user: ${errorData['error']}');
      
    } catch (e) {
      Logger.error(
        'Error creating user via backend',
        error: e,
        tag: 'BackendApiService',
      );
      rethrow;
    }
  }

  /// Get all users (admin only)
  static Future<List<AppUser>> getAllUsers() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> usersData = data['users'];
        
        return usersData.map((userData) => AppUser(
          id: userData['id'],
          email: userData['email'],
          name: userData['name'],
          role: UserRole.values.firstWhere(
            (r) => r.name == userData['role'],
            orElse: () => UserRole.waiter,
          ),
          isActive: userData['isActive'] ?? true,
          createdAt: userData['createdAt'] != null
              ? DateTime.parse(userData['createdAt'])
              : DateTime.now(),
          updatedAt: userData['updatedAt'] != null
              ? DateTime.parse(userData['updatedAt'])
              : DateTime.now(),
        )).toList();
      }
      
      final errorData = json.decode(response.body);
      throw Exception('Failed to get users: ${errorData['error']}');
      
    } catch (e) {
      Logger.error(
        'Error getting users via backend',
        error: e,
        tag: 'BackendApiService',
      );
      rethrow;
    }
  }

  /// Get current user profile
  static Future<AppUser?> getCurrentUser() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/user/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['user'];
        
        return AppUser(
          id: userData['id'],
          email: userData['email'],
          name: userData['name'],
          role: UserRole.values.firstWhere(
            (r) => r.name == userData['role'],
            orElse: () => UserRole.waiter,
          ),
          isActive: userData['isActive'] ?? true,
          createdAt: userData['createdAt'] != null
              ? DateTime.parse(userData['createdAt'])
              : DateTime.now(),
          updatedAt: userData['updatedAt'] != null
              ? DateTime.parse(userData['updatedAt'])
              : DateTime.now(),
        );
      }
      
      return null;
      
    } catch (e) {
      Logger.error(
        'Error getting current user via backend',
        error: e,
        tag: 'BackendApiService',
      );
      return null;
    }
  }

  /// Update user (admin only)
  static Future<bool> updateUser(AppUser user) async {
    try {
      final headers = await _getHeaders();
      
      final body = json.encode({
        'name': user.name,
        'role': user.role.name,
        'isActive': user.isActive,
      });

      final response = await http.put(
        Uri.parse('$_baseUrl/users/${user.id}'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        Logger.info(
          'User updated successfully: ${user.email}',
          tag: 'BackendApiService',
        );
        return true;
      }
      
      return false;
      
    } catch (e) {
      Logger.error(
        'Error updating user via backend',
        error: e,
        tag: 'BackendApiService',
      );
      return false;
    }
  }

  /// Delete user (admin only)
  static Future<bool> deleteUser(String userId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        Logger.info(
          'User deleted successfully: $userId',
          tag: 'BackendApiService',
        );
        return true;
      }
      
      return false;
      
    } catch (e) {
      Logger.error(
        'Error deleting user via backend',
        error: e,
        tag: 'BackendApiService',
      );
      return false;
    }
  }
}