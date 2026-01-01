import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// Auth State - Trạng thái đăng nhập
class AuthState {
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.isLoggedIn = false,
    this.userData,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    Map<String, dynamic>? userData,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userData: userData ?? this.userData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Auth Provider - Quản lý state đăng nhập
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState()) {
    _checkLoginStatus();
  }

  /// Kiểm tra trạng thái login từ SharedPreferences
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final username = prefs.getString('username');
      final displayName = prefs.getString('displayName');
      final userId = prefs.getString('userId');

      state = state.copyWith(
        isLoggedIn: true,
        userData: {
          'id': userId,
          'username': username,
          'displayName': displayName,
        },
      );
    }
  }

  /// Login với username và password
  Future<bool> login(String username, String password) async {
    // Set loading state
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Call auth service
      final userData = await _authService.login(username, password);

      if (userData != null) {
        // Login success - lưu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', userData['username'] ?? '');
        await prefs.setString('displayName', userData['displayName'] ?? '');
        await prefs.setString('userId', userData['id'] ?? '');

        // Update state
        state = state.copyWith(
          isLoggedIn: true,
          userData: userData,
          isLoading: false,
        );

        return true;
      } else {
        // Login failed
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Tên đăng nhập hoặc mật khẩu không đúng',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi đăng nhập: $e',
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    state = AuthState(); // Reset to initial state
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Auth Provider instance
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
