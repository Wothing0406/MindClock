import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/models/auth_session.dart';
import '../../domain/models/personal_flow_models.dart';
import '../../domain/services/auth_session_gateway.dart';
import '../../domain/services/camera_capture_gateway.dart';

/// Client HTTP `/v1` chuẩn hóa theo `docs/07` & `docs/18`.
///
/// - Gắn `Authorization: Bearer <Firebase ID token>` và `Idempotency-Key`.
/// - Timeout mặc định 15 giây cho thao tác API/chấm bài (`docs/07 §5`).
/// - Khi gặp `401`, refresh token tối đa 1 lần rồi thử lại đúng 1 lần với cùng `Idempotency-Key`.
/// - Không ghi token, ảnh hoặc lời giải cá nhân vào log.
class PersonalApiClient {
  PersonalApiClient({
    required this.baseUri,
    required AuthSessionGateway authGateway,
    HttpClient Function()? httpClientFactory,
    this.requestTimeout = const Duration(seconds: 15),
  })  : _authGateway = authGateway,
        _httpClientFactory = httpClientFactory ?? HttpClient.new;

  final Uri? baseUri;
  final AuthSessionGateway _authGateway;
  final HttpClient Function() _httpClientFactory;
  final Duration requestTimeout;

  Uri _resolvePath(String relativePath, [Map<String, String>? queryParameters]) {
    final Uri? base = baseUri;
    if (base == null || base.host.isEmpty) {
      throw const PersonalApiException(
        code: 'BACKEND_NOT_CONFIGURED',
        messageVi:
            'Chưa cấu hình máy chủ backend (/v1). Vui lòng hoàn tất T016 hoặc dùng chế độ offline.',
        isNetworkError: true,
      );
    }
    final String normalizedBase = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final String cleanRel =
        relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return base.replace(
      path: '$normalizedBase/v1$cleanRel',
      queryParameters:
          (queryParameters == null || queryParameters.isEmpty)
              ? null
              : queryParameters,
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return _executeWithSingleAuthRefresh<Map<String, dynamic>>(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      sender: (String token) => _sendJson(
        method: 'GET',
        uri: _resolvePath(path, queryParameters),
        token: token,
      ),
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) {
    return _executeWithSingleAuthRefresh<Map<String, dynamic>>(
      method: 'POST',
      path: path,
      sender: (String token) => _sendJson(
        method: 'POST',
        uri: _resolvePath(path),
        token: token,
        idempotencyKey: idempotencyKey,
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
  }) {
    return _executeWithSingleAuthRefresh<Map<String, dynamic>>(
      method: 'PUT',
      path: path,
      sender: (String token) => _sendJson(
        method: 'PUT',
        uri: _resolvePath(path),
        token: token,
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> postMultipartAttempt({
    required String path,
    required Map<String, String> fields,
    required PhotoAttemptUpload photo,
    required String idempotencyKey,
  }) {
    if (photo.bytes.lengthInBytes > CameraCaptureGateway.maxImageBytes) {
      throw const PersonalApiException(
        code: 'PAYLOAD_TOO_LARGE',
        messageVi: 'Ảnh vượt quá giới hạn 5 MB. Vui lòng chụp lại hoặc nhập chữ.',
        httpStatus: 413,
      );
    }
    if (!CameraCaptureGateway.allowedMimeTypes.contains(photo.mimeType)) {
      throw const PersonalApiException(
        code: 'UNSUPPORTED_MEDIA_TYPE',
        messageVi: 'Định dạng ảnh chưa được hỗ trợ. Vui lòng chọn ảnh JPEG/PNG/WebP hoặc nhập chữ.',
        httpStatus: 415,
      );
    }

    return _executeWithSingleAuthRefresh<Map<String, dynamic>>(
      method: 'POST',
      path: path,
      sender: (String token) => _sendMultipart(
        uri: _resolvePath(path),
        token: token,
        idempotencyKey: idempotencyKey,
        fields: fields,
        photo: photo,
      ),
    );
  }

  Future<T> _executeWithSingleAuthRefresh<T>({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    required Future<T> Function(String token) sender,
  }) async {
    final AuthSession current = await _authGateway.loadSavedSession();
    if (!current.isAuthenticated) {
      throw const PersonalApiException(
        code: 'AUTH_REQUIRED',
        messageVi:
            'Cần đăng nhập để đồng bộ hoặc chấm online. Báo thức trên máy vẫn hoạt động bình thường.',
        httpStatus: 401,
      );
    }

    try {
      return await sender(current.idToken!);
    } on PersonalApiException catch (e) {
      if (e.httpStatus != 401) rethrow;
    }

    // 401 lần đầu: thử làm mới token đúng 1 lần theo docs/18 §2
    final AuthSession refreshed = await _authGateway.refreshIdToken();
    if (!refreshed.isAuthenticated) {
      throw PersonalApiException(
        code: 'AUTH_EXPIRED',
        messageVi: refreshed.statusMessageVi ??
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại (chuông báo thức trên máy vẫn giữ nguyên).',
        httpStatus: 401,
      );
    }

    try {
      return await sender(refreshed.idToken!);
    } on PersonalApiException catch (e) {
      if (e.httpStatus == 401) {
        await _authGateway.markSessionExpired(
          messageVi:
              'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại (chuông báo thức trên máy vẫn hoạt động).',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _sendJson({
    required String method,
    required Uri uri,
    required String token,
    String? idempotencyKey,
    Map<String, dynamic>? body,
  }) async {
    final HttpClient client = _httpClientFactory();
    client.connectionTimeout = requestTimeout;
    try {
      final HttpClientRequest request =
          await client.openUrl(method, uri).timeout(requestTimeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        request.headers.set('Idempotency-Key', idempotencyKey);
      }
      if (body != null) {
        final List<int> encoded = utf8.encode(jsonEncode(body));
        request.headers.set(
          HttpHeaders.contentTypeHeader,
          'application/json; charset=utf-8',
        );
        request.contentLength = encoded.length;
        request.add(encoded);
      }

      final HttpClientResponse response =
          await request.close().timeout(requestTimeout);
      final String rawBody = await utf8.decodeStream(response).timeout(
            requestTimeout,
          );
      return _decodeResponse(response.statusCode, rawBody);
    } on TimeoutException {
      throw const PersonalApiException(
        code: 'CLIENT_TIMEOUT',
        messageVi:
            'Quá thời gian chờ phản hồi từ máy chủ (15 giây). Chuông và Dừng khẩn cấp vẫn hoạt động bình thường.',
        httpStatus: 504,
        retryable: true,
        isTimeout: true,
      );
    } on SocketException {
      throw const PersonalApiException(
        code: 'NETWORK_UNAVAILABLE',
        messageVi:
            'Không có kết nối mạng tới máy chủ. Bạn có thể hoàn thành không chấm hoặc lưu nháp chữ.',
        retryable: true,
        isNetworkError: true,
      );
    } on HttpException {
      throw const PersonalApiException(
        code: 'NETWORK_PROTOCOL_ERROR',
        messageVi: 'Kết nối máy chủ bị gián đoạn. Bạn có thể thử lại với cùng mã gửi.',
        retryable: true,
        isNetworkError: true,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _sendMultipart({
    required Uri uri,
    required String token,
    required String idempotencyKey,
    required Map<String, String> fields,
    required PhotoAttemptUpload photo,
  }) async {
    final HttpClient client = _httpClientFactory();
    client.connectionTimeout = requestTimeout;
    final String boundary =
        '----MindClockBoundary${DateTime.now().microsecondsSinceEpoch}';
    try {
      final HttpClientRequest request =
          await client.openUrl('POST', uri).timeout(requestTimeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set('Idempotency-Key', idempotencyKey);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      final List<int> payload = <int>[];
      fields.forEach((String key, String value) {
        payload.addAll(utf8.encode(
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="$key"\r\n\r\n'
          '$value\r\n',
        ));
      });

      final String safeFileName =
          photo.fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      payload.addAll(utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="image"; filename="$safeFileName"\r\n'
        'Content-Type: ${photo.mimeType}\r\n\r\n',
      ));
      payload.addAll(photo.bytes);
      payload.addAll(utf8.encode('\r\n--$boundary--\r\n'));

      request.contentLength = payload.length;
      request.add(payload);

      final HttpClientResponse response =
          await request.close().timeout(requestTimeout);
      final String rawBody = await utf8.decodeStream(response).timeout(
            requestTimeout,
          );
      return _decodeResponse(response.statusCode, rawBody);
    } on TimeoutException {
      throw const PersonalApiException(
        code: 'CLIENT_TIMEOUT',
        messageVi:
            'Quá thời gian chờ chấm ảnh (15 giây). Chưa thể chấm, bạn có thể thử lại hoặc nhập chữ.',
        httpStatus: 504,
        retryable: true,
        isTimeout: true,
      );
    } on SocketException {
      throw const PersonalApiException(
        code: 'NETWORK_UNAVAILABLE',
        messageVi:
            'Mất kết nối khi gửi ảnh. Ảnh không tự xếp hàng tải ngầm; bạn có thể nhập bài chữ.',
        retryable: true,
        isNetworkError: true,
      );
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic> _decodeResponse(int statusCode, String rawBody) {
    Map<String, dynamic> parsed = const <String, dynamic>{};
    if (rawBody.trim().isNotEmpty) {
      final Object? decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        parsed = decoded;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return parsed;
    }

    final Map<String, dynamic>? err =
        parsed['error'] as Map<String, dynamic>?;
    final String code = err?['code'] as String? ?? 'HTTP_$statusCode';
    final bool retryable = err?['retryable'] as bool? ??
        (statusCode >= 500 || statusCode == 429);
    final String serverMessage =
        (err?['message'] as String?)?.trim() ?? '';

    throw PersonalApiException(
      code: code,
      httpStatus: statusCode,
      retryable: retryable,
      isTimeout: statusCode == 504,
      messageVi: serverMessage.isNotEmpty
          ? serverMessage
          : _defaultVietnameseMessage(statusCode, code),
    );
  }

  static String _defaultVietnameseMessage(int statusCode, String code) {
    switch (statusCode) {
      case 401:
        return 'Phiên đăng nhập đã hết hạn hoặc chưa hợp lệ.';
      case 403:
        return 'Bạn không có quyền truy cập tài nguyên này.';
      case 409:
        return code == 'IDEMPOTENCY_CONFLICT'
            ? 'Yêu cầu trước đó dùng cùng mã gửi nhưng nội dung đã thay đổi. Vui lòng gửi lại phiên mới.'
            : 'Dữ liệu đã thay đổi trên máy chủ, đang cần tải lại trạng thái mới.';
      case 413:
        return 'Ảnh vượt quá dung lượng cho phép (tối đa 5 MB).';
      case 415:
        return 'Định dạng tệp ảnh không được hỗ trợ.';
      case 429:
        return 'Bạn gửi hơi nhanh, vui lòng đợi một lát hoặc chuyển sang nhập chữ / hoàn thành không chấm.';
      case 502:
      case 503:
      case 504:
        return 'Chưa thể chấm lúc này do dịch vụ AI tạm gián đoạn. Bạn có thể kết thúc báo thức.';
      default:
        return 'Máy chủ trả lỗi ($statusCode). Bạn vẫn dùng báo thức local bình thường.';
    }
  }
}
