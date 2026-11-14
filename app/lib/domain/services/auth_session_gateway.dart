import '../models/auth_session.dart';

/// Giao diện xác thực tài khoản online (Firebase Auth ID token).
abstract interface class AuthSessionGateway {
  bool get isDebugFixture;

  Future<AuthSession> loadSavedSession();

  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Làm mới ID token tối đa 1 lần khi API trả `401`. Trả session mới hoặc
  /// chuyển trạng thái sang `AuthStatus.reauthRequired` nếu refresh hết hạn.
  Future<AuthSession> refreshIdToken();

  Future<AuthSession> markSessionExpired({String? messageVi});

  Future<void> signOut();
}
