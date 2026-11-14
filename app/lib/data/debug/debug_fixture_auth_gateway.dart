import '../../domain/models/auth_session.dart';
import '../../domain/services/auth_session_gateway.dart';

/// Fixture auth tách riêng trong `lib/data/debug/` chỉ dùng cho demo/dev local có nhãn rõ ràng.
class DebugFixtureAuthGateway implements AuthSessionGateway {
  AuthSession _session = const AuthSession.guest();

  @override
  bool get isDebugFixture => true;

  @override
  Future<AuthSession> loadSavedSession() async => _session;

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final String normalized = email.trim().toLowerCase();
    _session = AuthSession(
      status: AuthStatus.authenticated,
      uid: 'debug_${normalized.hashCode.abs()}',
      email: normalized,
      idToken: 'debug-fixture-token',
      refreshToken: 'debug-fixture-refresh',
      emailVerified: true,
      isDebugFixture: true,
      statusMessageVi: 'Đang dùng Fixture debug (không phải Firebase Auth thật).',
    );
    return _session;
  }

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return signInWithEmail(email: email, password: password);
  }

  @override
  Future<AuthSession> refreshIdToken() async => _session;

  @override
  Future<AuthSession> markSessionExpired({String? messageVi}) async {
    _session = _session.copyWith(
      status: AuthStatus.reauthRequired,
      idToken: '',
      statusMessageVi: messageVi ?? 'Fixture debug: phiên mô phỏng hết hạn.',
    );
    return _session;
  }

  @override
  Future<void> signOut() async {
    _session = const AuthSession.guest();
  }
}
