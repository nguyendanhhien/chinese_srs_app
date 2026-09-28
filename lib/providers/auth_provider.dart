import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// State management cho trạng thái đăng nhập, dùng với package Provider.
///
/// Bọc AuthService, expose các thông tin UI cần: người dùng hiện tại,
/// trạng thái loading, thông báo lỗi (nếu có) - và 3 hành động chính:
/// signUp(), login(), logout().
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    // Tự động cập nhật currentUser mỗi khi trạng thái đăng nhập Firebase
    // thay đổi (kể cả khi đăng nhập/đăng xuất xảy ra từ nơi khác).
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  final AuthService _authService;
  StreamSubscription<User?>? _authStateSubscription;

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Đăng ký tài khoản mới. Trả về true nếu thành công, false nếu thất bại
  /// (khi đó [errorMessage] sẽ được set để UI hiển thị).
  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    _startLoading();
    try {
      await _authService.signUp(
        username: username,
        email: email,
        password: password,
      );
      _stopLoading();
      return true;
    } on AuthException catch (e) {
      _failWithError(e.message);
      return false;
    }
  }

  /// Đăng nhập. Trả về true nếu thành công, false nếu thất bại.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _startLoading();
    try {
      await _authService.login(email: email, password: password);
      _stopLoading();
      return true;
    } on AuthException catch (e) {
      _failWithError(e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  /// Xoá thông báo lỗi hiện tại - gọi khi người dùng bắt đầu sửa lại form,
  /// để lỗi cũ không còn hiển thị dai dẳng trên màn hình.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void _failWithError(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
