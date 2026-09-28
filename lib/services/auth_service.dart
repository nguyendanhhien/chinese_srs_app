import 'package:firebase_auth/firebase_auth.dart';

/// Lỗi xác thực đã được dịch sang thông báo tiếng Việt dễ hiểu,
/// để hiển thị trực tiếp lên UI (login_error / signup_error evidence).
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Bọc các lời gọi tới Firebase Authentication (đăng ký, đăng nhập,
/// đăng xuất, theo dõi trạng thái đăng nhập hiện tại).
///
/// AuthProvider sẽ gọi service này - các màn hình (LoginScreen,
/// SignupScreen) KHÔNG gọi thẳng Firebase.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  /// Người dùng hiện đang đăng nhập (null nếu chưa đăng nhập).
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream phát ra mỗi khi trạng thái đăng nhập thay đổi
  /// (đăng nhập / đăng xuất) - dùng để tự động điều hướng giữa
  /// LoginScreen và HomeScreen.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Đăng ký tài khoản mới bằng email/mật khẩu.
  /// Ném ra [AuthException] với thông báo tiếng Việt nếu thất bại.
  Future<User?> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(username);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapSignUpErrorMessage(e.code));
    }
  }

  /// Đăng nhập bằng email/mật khẩu.
  /// Ném ra [AuthException] với thông báo tiếng Việt nếu thất bại.
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapLoginErrorMessage(e.code));
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  String _mapSignUpErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Vui lòng đăng nhập hoặc dùng email khác.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (cần ít nhất 6 ký tự).';
      default:
        return 'Đăng ký thất bại. Vui lòng thử lại.';
    }
  }

  String _mapLoginErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hoá.';
      default:
        return 'Đăng nhập thất bại. Vui lòng thử lại.';
    }
  }
}
