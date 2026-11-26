import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/models/auth_session.dart';
import '../../domain/services/auth_session_gateway.dart';
import 'local_key_value_store.dart';

/// Cổng xác thực tài khoản online qua Firebase Authentication REST API.
///
/// Không giữ mật khẩu trong storage/log; chỉ giữ `uid`, `email`, `idToken`,
/// `refreshToken` trong vùng lưu app. Nếu chưa cấu hình Firebase Web API key,
/// báo rõ ràng thay vì giả đăng nhập thành công.
class FirebaseAuthGateway implements AuthSessionGateway {
  FirebaseAuthGateway({
    required LocalKeyValueStore store,
    required String firebaseWebApiKey,
    this.backendBaseUri,
    Uri? identityBaseUri,
    Uri? secureTokenBaseUri,
    HttpClient Function()? httpClientFactory,
    this.requestTimeout = const Duration(seconds: 15),
  })  : _store = store,
        _apiKey = firebaseWebApiKey.trim(),
        _identityBaseUri = identityBaseUri ??
            Uri.parse('https://identitytoolkit.googleapis.com/v1'),
        _secureTokenBaseUri = secureTokenBaseUri ??
            Uri.parse('https://securetoken.googleapis.com/v1'),
        _httpClientFactory = httpClientFactory ?? HttpClient.new;

  static const String sessionStorageKey = 'mindclock_firebase_auth_session_v1';

  final LocalKeyValueStore _store;
  final String _apiKey;
  final Uri? backendBaseUri;
  final Uri _identityBaseUri;
  final Uri _secureTokenBaseUri;
  final HttpClient Function() _httpClientFactory;
  final Duration requestTimeout;

  AuthSession? _cachedSession;

  @override
  bool get isDebugFixture => false;

  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Future<AuthSession> loadSavedSession() async {
    if (_cachedSession != null) return _cachedSession!;
    final String? raw = await _store.readString(sessionStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      _cachedSession = const AuthSession.guest();
      return _cachedSession!;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final String rawStatus =
            decoded['status'] as String? ?? AuthStatus.guest.name;
        final AuthStatus status = AuthStatus.values.firstWhere(
          (AuthStatus s) => s.name == rawStatus,
          orElse: () => AuthStatus.guest,
        );
        _cachedSession = AuthSession(
          status: status,
          uid: decoded['uid'] as String?,
          email: decoded['email'] as String?,
          idToken: decoded['idToken'] as String?,
          refreshToken: decoded['refreshToken'] as String?,
          emailVerified: decoded['emailVerified'] as bool? ?? false,
          isDebugFixture: false,
          statusMessageVi: decoded['statusMessageVi'] as String?,
        );
        return _cachedSession!;
      }
    } catch (_) {
      await _store.remove(sessionStorageKey);
    }
    _cachedSession = const AuthSession.guest();
    return _cachedSession!;
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _authenticate(
      action: 'accounts:signInWithPassword',
      email: email,
      password: password,
    );
  }

  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return signInWithEmail(email: email, password: password);
  }

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _authenticate(
      action: 'accounts:signUp',
      email: email,
      password: password,
    );
  }

  bool _isBackendConfigFallbackCode(String code) {
    final String c = code.toUpperCase();
    return c.contains('OPERATION_NOT_ALLOWED') ||
        c.contains('CONFIGURATION_NOT_FOUND') ||
        c.contains('API_KEY_INVALID') ||
        c.contains('FIREBASE_NOT_CONFIGURED') ||
        c.contains('ADMIN_ONLY_OPERATION') ||
        c.contains('PROJECT_NOT_FOUND');
  }

  bool _shouldFallbackToBackend(
    AuthException e, {
    required bool isSignUp,
  }) {
    if (backendBaseUri == null) return false;
    if (_isBackendConfigFallbackCode(e.code)) return true;
    final String c = e.code.toUpperCase();
    if (c == 'AUTH_TIMEOUT' || c == 'NETWORK_UNAVAILABLE') {
      return true;
    }
    if (!isSignUp &&
        (c.contains('EMAIL_NOT_FOUND') ||
            c.contains('INVALID_LOGIN_CREDENTIALS') ||
            c.contains('INVALID_PASSWORD') ||
            c.contains('USER_DISABLED'))) {
      return true;
    }
    return false;
  }

  Future<AuthSession> _authenticate({
    required String action,
    required String email,
    required String password,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();
    final bool isSignUp = action == 'accounts:signUp';
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw const AuthException(
        code: 'INVALID_EMAIL',
        messageVi: 'Vui lòng nhập email hợp lệ.',
      );
    }
    if (password.length < 6) {
      throw const AuthException(
        code: 'WEAK_PASSWORD',
        messageVi: 'Mật khẩu cần tối thiểu 6 ký tự theo chính sách Auth.',
      );
    }

    if (!isConfigured) {
      if (backendBaseUri != null) {
        return _authenticateWithBackend(
          isSignUp: isSignUp,
          email: normalizedEmail,
          password: password,
        );
      }
      throw const AuthException(
        code: 'FIREBASE_NOT_CONFIGURED',
        messageVi:
            'Chưa cấu hình dự án Firebase Authentication cho bản dựng này.',
      );
    }

    try {
      final Uri endpoint = _buildEndpoint(_identityBaseUri, action);
      final Map<String, dynamic> response = await _postJson(
        endpoint,
        <String, dynamic>{
          'email': normalizedEmail,
          'password': password,
          'returnSecureToken': true,
        },
      );

      final Object? rawUid = response['localId'];
      final Object? rawEmail = response['email'];
      final Object? rawIdToken = response['idToken'];
      final Object? rawRefreshToken = response['refreshToken'];
      final AuthSession next = AuthSession(
        status: AuthStatus.authenticated,
        uid: rawUid is String ? rawUid : null,
        email: (rawEmail is String ? rawEmail : normalizedEmail).toLowerCase(),
        idToken: rawIdToken is String ? rawIdToken : null,
        refreshToken: rawRefreshToken is String ? rawRefreshToken : null,
        emailVerified: response['emailVerified'] == true,
        isDebugFixture: false,
      );
      if (!next.isAuthenticated) {
        throw const AuthException(
          code: 'AUTH_INVALID_RESPONSE',
          messageVi: 'Phản hồi đăng nhập chưa hợp lệ.',
        );
      }
      await _persistSession(next);
      return next;
    } on AuthException catch (e) {
      if (_shouldFallbackToBackend(e, isSignUp: isSignUp)) {
        return _authenticateWithBackend(
          isSignUp: isSignUp,
          email: normalizedEmail,
          password: password,
        );
      }
      rethrow;
    }
  }

  Future<AuthSession> _authenticateWithBackend({
    required bool isSignUp,
    required String email,
    required String password,
  }) async {
    final Uri base = backendBaseUri!;
    final String suffix = isSignUp ? 'v1/auth/register' : 'v1/auth/login';
    final Uri endpoint = _buildBackendEndpoint(base, suffix);
    final Map<String, dynamic> response = await _postJson(
      endpoint,
      <String, dynamic>{
        'email': email,
        'password': password,
      },
    );
    final Object? rawUid = response['uid'];
    final Object? rawEmail = response['email'];
    final Object? rawIdToken = response['idToken'];
    final Object? rawRefreshToken = response['refreshToken'];
    final AuthSession next = AuthSession(
      status: AuthStatus.authenticated,
      uid: rawUid is String ? rawUid : null,
      email: (rawEmail is String ? rawEmail : email).toLowerCase(),
      idToken: rawIdToken is String ? rawIdToken : null,
      refreshToken: rawRefreshToken is String ? rawRefreshToken : null,
      emailVerified: response['emailVerified'] != false,
      isDebugFixture: false,
    );
    if (!next.isAuthenticated) {
      throw const AuthException(
        code: 'AUTH_INVALID_RESPONSE',
        messageVi: 'Phản hồi đăng nhập từ máy chủ chưa hợp lệ.',
      );
    }
    await _persistSession(next);
    return next;
  }

  Uri _buildBackendEndpoint(Uri base, String suffix) {
    final String cleanBase = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final String cleanSuffix = suffix.startsWith('/') ? suffix.substring(1) : suffix;
    return base.replace(
      path: '$cleanBase/$cleanSuffix',
      queryParameters: null,
    );
  }

  @override
  Future<AuthSession> refreshIdToken() async {
    final AuthSession current = await loadSavedSession();
    final String? refresh = current.refreshToken;
    if (refresh == null || refresh.isEmpty) {
      return markSessionExpired(
        messageVi:
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại (chuông local vẫn giữ nguyên).',
      );
    }

    if (backendBaseUri != null &&
        ((current.uid?.startsWith('loc_') ?? false) || !isConfigured)) {
      try {
        final Uri endpoint =
            _buildBackendEndpoint(backendBaseUri!, 'v1/auth/refresh');
        final Map<String, dynamic> response = await _postJson(
          endpoint,
          <String, dynamic>{'refreshToken': refresh},
        );
        final Object? rawId = response['idToken'];
        final Object? rawRefresh = response['refreshToken'];
        final Object? rawUid = response['uid'];
        final String? newIdToken = rawId is String ? rawId : null;
        final String? newRefreshToken = rawRefresh is String ? rawRefresh : null;
        final String? uid = (rawUid is String ? rawUid : null) ?? current.uid;
        if (newIdToken == null || newIdToken.isEmpty || uid == null) {
          return await markSessionExpired();
        }
        final AuthSession updated = current.copyWith(
          status: AuthStatus.authenticated,
          uid: uid,
          idToken: newIdToken,
          refreshToken: newRefreshToken ?? refresh,
          clearMessage: true,
        );
        await _persistSession(updated);
        return updated;
      } on AuthException catch (e) {
        return markSessionExpired(messageVi: e.messageVi);
      }
    }

    if (!isConfigured) {
      return markSessionExpired(
        messageVi:
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại (chuông local vẫn giữ nguyên).',
      );
    }

    final Uri endpoint = _buildEndpoint(_secureTokenBaseUri, 'token');
    try {
      final Map<String, dynamic> response = await _postJson(
        endpoint,
        <String, dynamic>{
          'grant_type': 'refresh_token',
          'refresh_token': refresh,
        },
      );
      final Object? rawId = response['id_token'];
      final Object? rawRefresh = response['refresh_token'];
      final Object? rawUid = response['user_id'];
      final String? newIdToken = rawId is String ? rawId : null;
      final String? newRefreshToken = rawRefresh is String ? rawRefresh : null;
      final String? uid = (rawUid is String ? rawUid : null) ?? current.uid;
      if (newIdToken == null || newIdToken.isEmpty || uid == null) {
        return await markSessionExpired();
      }
      final AuthSession updated = current.copyWith(
        status: AuthStatus.authenticated,
        uid: uid,
        idToken: newIdToken,
        refreshToken: newRefreshToken ?? refresh,
        clearMessage: true,
      );
      await _persistSession(updated);
      return updated;
    } on AuthException catch (e) {
      return markSessionExpired(messageVi: e.messageVi);
    }
  }

  @override
  Future<AuthSession> markSessionExpired({String? messageVi}) async {
    final AuthSession current = await loadSavedSession();
    final AuthSession expired = current.copyWith(
      status: AuthStatus.reauthRequired,
      idToken: '',
      statusMessageVi: messageVi ??
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại (chuông local vẫn hoạt động).',
    );
    await _persistSession(expired);
    return expired;
  }

  @override
  Future<void> signOut() async {
    _cachedSession = const AuthSession.guest();
    await _store.remove(sessionStorageKey);
  }

  Uri _buildEndpoint(Uri base, String suffix) {
    final String cleanBasePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final String cleanSuffix = suffix.startsWith('/') ? suffix.substring(1) : suffix;
    return base.replace(
      path: '$cleanBasePath/$cleanSuffix',
      queryParameters: <String, String>{'key': _apiKey},
    );
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final HttpClient client = _httpClientFactory();
    client.connectionTimeout = requestTimeout;
    try {
      final HttpClientRequest req =
          await client.postUrl(uri).timeout(requestTimeout);
      final List<int> bodyBytes = utf8.encode(jsonEncode(payload));
      req.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      req.contentLength = bodyBytes.length;
      req.add(bodyBytes);

      final HttpClientResponse res = await req.close().timeout(requestTimeout);
      final String raw =
          await utf8.decodeStream(res).timeout(requestTimeout);
      Map<String, dynamic> jsonMap = <String, dynamic>{};
      if (raw.trim().isNotEmpty) {
        try {
          final Object? decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            jsonMap = decoded;
          }
        } on FormatException {
          throw AuthException(
            code: 'AUTH_INVALID_JSON_${res.statusCode}',
            messageVi:
                'Phản hồi xác thực chưa đúng định dạng (HTTP ${res.statusCode}).',
          );
        }
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonMap;
      }
      final Object? rawErr = jsonMap['error'];
      final Map<String, dynamic>? err =
          rawErr is Map<String, dynamic> ? rawErr : null;
      final Object? rawCode = err?['code'];
      final String? stringCode =
          rawCode is String && rawCode.trim().isNotEmpty ? rawCode.trim() : null;
      final String? msgField = err?['message']?.toString();
      final String code = stringCode ??
          (msgField != null && msgField.trim().isNotEmpty
              ? msgField.trim()
              : null) ??
          'AUTH_FAILED';
      final String? serverMsg = stringCode != null ? msgField : null;
      throw AuthException(
        code: code,
        messageVi: (serverMsg != null && serverMsg.trim().isNotEmpty)
            ? serverMsg
            : _mapAuthErrorVi(code),
      );
    } on TimeoutException {
      throw const AuthException(
        code: 'AUTH_TIMEOUT',
        messageVi: 'Quá thời gian kết nối xác thực. Báo thức local vẫn hoạt động.',
      );
    } on SocketException {
      throw const AuthException(
        code: 'NETWORK_UNAVAILABLE',
        messageVi:
            'Không có mạng để đăng nhập lúc này. Báo thức trên máy vẫn chạy bình thường.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _persistSession(AuthSession session) async {
    _cachedSession = session;
    await _store.writeString(
      sessionStorageKey,
      jsonEncode(<String, dynamic>{
        'status': session.status.name,
        'uid': session.uid,
        'email': session.email,
        'idToken': session.idToken,
        'refreshToken': session.refreshToken,
        'emailVerified': session.emailVerified,
        'statusMessageVi': session.statusMessageVi,
      }),
    );
  }

  static String _mapAuthErrorVi(String code) {
    if (code.contains('EMAIL_EXISTS')) {
      return 'Email này đã có tài khoản. Vui lòng chọn đăng nhập.';
    }
    if (code.contains('INVALID_LOGIN_CREDENTIALS') ||
        code.contains('INVALID_PASSWORD') ||
        code.contains('EMAIL_NOT_FOUND')) {
      return 'Email hoặc mật khẩu chưa đúng.';
    }
    if (code.contains('CONFIGURATION_NOT_FOUND') ||
        code.contains('OPERATION_NOT_ALLOWED')) {
      return 'Firebase Auth chưa bật tính năng Email/Password. Vui lòng bật tại Firebase Console (Authentication > Sign-in method).';
    }
    if (code.contains('API_KEY_INVALID')) {
      return 'Firebase Web API key không hợp lệ. Vui lòng kiểm tra lại cấu hình Project settings.';
    }
    if (code.contains('TOKEN_EXPIRED') || code.contains('INVALID_REFRESH_TOKEN')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (code.contains('TOO_MANY_ATTEMPTS')) {
      return 'Bạn thao tác quá nhanh, vui lòng thử lại sau ít phút.';
    }
    return 'Không thể xác thực tài khoản lúc này ($code).';
  }
}
