enum AuthStatus {
  guest,
  authenticated,
  reauthRequired,
}

/// Trạng thái phiên xác thực trực tuyến (Firebase Auth).
///
/// Tuyệt đối không đưa `idToken` hay `refreshToken` vào `toString()` hoặc log.
class AuthSession {
  const AuthSession({
    required this.status,
    this.uid,
    this.email,
    this.idToken,
    this.refreshToken,
    this.emailVerified = false,
    this.isDebugFixture = false,
    this.statusMessageVi,
  });

  const AuthSession.guest()
      : status = AuthStatus.guest,
        uid = null,
        email = null,
        idToken = null,
        refreshToken = null,
        emailVerified = false,
        isDebugFixture = false,
        statusMessageVi = null;

  final AuthStatus status;
  final String? uid;
  final String? email;
  final String? idToken;
  final String? refreshToken;
  final bool emailVerified;
  final bool isDebugFixture;
  final String? statusMessageVi;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated &&
      uid != null &&
      uid!.isNotEmpty &&
      idToken != null &&
      idToken!.isNotEmpty;

  String get ownerScopeKey =>
      (uid != null && uid!.isNotEmpty) ? 'uid:$uid' : 'guest';

  AuthSession copyWith({
    AuthStatus? status,
    String? uid,
    String? email,
    String? idToken,
    String? refreshToken,
    bool? emailVerified,
    bool? isDebugFixture,
    String? statusMessageVi,
    bool clearMessage = false,
  }) {
    return AuthSession(
      status: status ?? this.status,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      idToken: idToken ?? this.idToken,
      refreshToken: refreshToken ?? this.refreshToken,
      emailVerified: emailVerified ?? this.emailVerified,
      isDebugFixture: isDebugFixture ?? this.isDebugFixture,
      statusMessageVi:
          clearMessage ? null : (statusMessageVi ?? this.statusMessageVi),
    );
  }

  @override
  String toString() =>
      'AuthSession(status: $status, uid: $uid, verified: $emailVerified, debug: $isDebugFixture)';
}

class AuthException implements Exception {
  const AuthException({
    required this.code,
    required this.messageVi,
  });

  final String code;
  final String messageVi;

  @override
  String toString() => 'AuthException($code)';
}
