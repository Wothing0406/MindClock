import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Máy chủ HTTP `/v1` & Firebase Auth REST giả lập trên loopback cho contract & E2E test.
///
/// Phục vụ:
/// - Đăng nhập User A (`uid_a`) & User B (`uid_b`), refresh token một lần, kịch bản hết hạn hẳn.
/// - Kiểm tra cô lập chủ sở hữu A/B (`403`), thiếu/hết hạn token (`401`).
/// - Kiểm tra `Idempotency-Key` (cùng key + cùng payload -> trả lại kết quả cũ không nhân XP;
///   cùng key + payload khác -> `409 IDEMPOTENCY_CONFLICT`).
/// - Kiểm tra timeout AI (`delayNextGrade`) và upload multipart `/attempts`.
class LoopbackV1ContractServer {
  LoopbackV1ContractServer._(this._server);

  final HttpServer _server;

  Uri get baseUri => Uri.parse('http://127.0.0.1:${_server.port}');
  Uri get identityBaseUri =>
      Uri.parse('http://127.0.0.1:${_server.port}/firebase-identity/v1');
  Uri get secureTokenBaseUri =>
      Uri.parse('http://127.0.0.1:${_server.port}/firebase-securetoken/v1');

  int tokenVersion = 1;
  bool forcePermanentAuthFailure = false;
  Duration artificialGradeDelay = Duration.zero;
  int answerPostCount = 0;
  int attemptMultipartCount = 0;
  final List<String> seenIdempotencyKeys = <String>[];

  final Map<String, String> _sessionOwners = <String, String>{};
  final Map<String, Map<String, dynamic>> _idempotencyResponses =
      <String, Map<String, dynamic>>{};
  final Map<String, String> _idempotencyPayloadHashes = <String, String>{};
  final Map<String, int> _xpByUid = <String, int>{
    'uid_a': 0,
    'uid_b': 0,
  };
  final Map<String, int> _completedByUid = <String, int>{
    'uid_a': 0,
    'uid_b': 0,
  };
  final Map<String, int> _wrongAttemptsBySession = <String, int>{};

  static Future<LoopbackV1ContractServer> start() async {
    final HttpServer server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final LoopbackV1ContractServer instance = LoopbackV1ContractServer._(server);
    server.listen(instance._handleRequest);
    return instance;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  String _activeTokenFor(String uid) => 'token_${uid}_v$tokenVersion';

  String? _resolveUidFromAuth(HttpHeaders headers) {
    if (forcePermanentAuthFailure) return null;
    final String? auth = headers.value(HttpHeaders.authorizationHeader);
    if (auth == null || !auth.startsWith('Bearer ')) return null;
    final String token = auth.substring('Bearer '.length).trim();
    if (token == _activeTokenFor('uid_a')) return 'uid_a';
    if (token == _activeTokenFor('uid_b')) return 'uid_b';
    return null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final String path = request.uri.path;

    // 1. Mock Firebase Auth Identity Toolkit REST endpoints
    if (path.startsWith('/firebase-identity/v1/')) {
      final String body = await utf8.decodeStream(request);
      final Map<String, dynamic> map = jsonDecode(body) as Map<String, dynamic>;
      final String email = (map['email'] as String? ?? '').toLowerCase();
      final String uid = email.contains('userb') ? 'uid_b' : 'uid_a';
      await _writeJson(request.response, 200, <String, dynamic>{
        'localId': uid,
        'email': email,
        'idToken': _activeTokenFor(uid),
        'refreshToken': 'refresh_$uid',
        'emailVerified': true,
      });
      return;
    }

    if (path.startsWith('/firebase-securetoken/v1/')) {
      final String body = await utf8.decodeStream(request);
      final Map<String, dynamic> map = jsonDecode(body) as Map<String, dynamic>;
      if (forcePermanentAuthFailure) {
        await _writeJson(request.response, 400, <String, dynamic>{
          'error': <String, dynamic>{'message': 'TOKEN_EXPIRED'},
        });
        return;
      }
      final String refreshToken = map['refresh_token'] as String? ?? '';
      final String uid = refreshToken.contains('uid_b') ? 'uid_b' : 'uid_a';
      await _writeJson(request.response, 200, <String, dynamic>{
        'id_token': _activeTokenFor(uid),
        'refresh_token': refreshToken,
        'user_id': uid,
      });
      return;
    }

    if (path == '/v1/health') {
      await _writeJson(request.response, 200, <String, dynamic>{
        'status': 'ok',
        'version': 'v1',
      });
      return;
    }

    // Mọi endpoint khác bắt buộc token hợp lệ
    final String? uid = _resolveUidFromAuth(request.headers);
    if (uid == null) {
      await _writeJson(request.response, 401, <String, dynamic>{
        'error': <String, dynamic>{
          'code': 'AUTH_EXPIRED',
          'message': 'Token hết hạn hoặc không hợp lệ.',
          'requestId': 'req_401',
          'retryable': false,
        },
      });
      return;
    }

    if (path == '/v1/challenges/next' && request.method == 'GET') {
      await _writeJson(request.response, 200, <String, dynamic>{
        'questionId': 'math9-linear-001',
        'questionRevision': 3,
        'validForDate':
            request.uri.queryParameters['date'] ?? '2026-11-14',
        'subject': request.uri.queryParameters['subject'] ?? 'TOAN',
        'topicId': 'linear_equation_1var',
        'difficulty': 1,
        'prompt': 'Giải phương trình 2(x − 3) = 10.',
        'reasoningPromptVi': 'Viết một hoặc hai bước bạn đã làm.',
        'offlinePolicy': 'ungraded_only',
        'estimatedSeconds': 75,
        'fallback': false,
      });
      return;
    }

    if (path == '/v1/progress/summary' && request.method == 'GET') {
      await _writeJson(request.response, 200, <String, dynamic>{
        'xp': _xpByUid[uid] ?? 0,
        'streak': (_completedByUid[uid] ?? 0) > 0 ? 1 : 0,
        'completedSessions': _completedByUid[uid] ?? 0,
        'topicsToReview': <String>['Phương trình bậc nhất'],
      });
      return;
    }

    if (path == '/v1/sessions' && request.method == 'GET') {
      final List<Map<String, dynamic>> items = _sessionOwners.entries
          .where((MapEntry<String, String> e) => e.value == uid)
          .map((MapEntry<String, String> e) => <String, dynamic>{
                'sessionId': e.key,
                'localDate': '2026-11-14',
                'subject': 'TOAN',
                'state': 'completed',
              })
          .toList(growable: false);
      await _writeJson(request.response, 200, <String, dynamic>{
        'items': items,
      });
      return;
    }

    if (path == '/v1/sessions' && request.method == 'POST') {
      final String body = await utf8.decodeStream(request);
      final Map<String, dynamic> map = jsonDecode(body) as Map<String, dynamic>;
      final String localId = map['localSessionId'] as String? ?? 's1';
      final String sessionId = 'srv_$localId';
      _sessionOwners[sessionId] = uid;
      await _writeJson(request.response, 200, <String, dynamic>{
        'sessionId': sessionId,
        'state': 'active',
        'version': 1,
      });
      return;
    }

    // Routes theo sessionId: /v1/sessions/{id}/...
    final RegExp sessionSubRoute =
        RegExp(r'^/v1/sessions/([^/]+)/(events|answers|attempts|feedback)$');
    final Match? match = sessionSubRoute.firstMatch(path);
    if (match != null && request.method == 'POST') {
      final String sessionId = match.group(1)!;
      final String action = match.group(2)!;
      final String? owner = _sessionOwners[sessionId];
      if (owner == null) {
        await _writeJson(request.response, 404, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'SESSION_NOT_FOUND',
            'message': 'Không tìm thấy phiên học.',
            'requestId': 'req_404',
            'retryable': false,
          },
        });
        return;
      }
      if (owner != uid) {
        await _writeJson(request.response, 403, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'FORBIDDEN_OWNER',
            'message': 'Không có quyền truy cập phiên của tài khoản khác.',
            'requestId': 'req_403',
            'retryable': false,
          },
        });
        return;
      }

      if (artificialGradeDelay > Duration.zero &&
          (action == 'answers' || action == 'attempts')) {
        await Future<void>.delayed(artificialGradeDelay);
      }

      final String idempKey = request.headers.value('Idempotency-Key') ?? '';
      if (idempKey.isNotEmpty) {
        seenIdempotencyKeys.add(idempKey);
      }

      if (action == 'attempts') {
        attemptMultipartCount += 1;
        await request.drain<void>();
        final String namespacedKey = '$uid:$action:$idempKey';
        if (_idempotencyResponses.containsKey(namespacedKey)) {
          await _writeJson(
            request.response,
            200,
            _idempotencyResponses[namespacedKey]!,
          );
          return;
        }
        _xpByUid[uid] = (_xpByUid[uid] ?? 0) + 10;
        _completedByUid[uid] = (_completedByUid[uid] ?? 0) + 1;
        final Map<String, dynamic> resp = <String, dynamic>{
          'attemptId': 'att_photo_$attemptMultipartCount',
          'result': 'correct',
          'observedSteps': <String>['2x - 6 = 10', 'x = 8'],
          'firstIssue': null,
          'feedback': 'Bài viết tay chính xác!',
          'hint': null,
          'nextActions': <String>['finish'],
          'xpAwarded': 10,
          'modelVersion': 'gemini-test-double',
          'rubricRevision': 3,
        };
        _idempotencyResponses[namespacedKey] = resp;
        await _writeJson(request.response, 200, resp);
        return;
      }

      final String body = await utf8.decodeStream(request);
      final String namespacedKey = '$uid:$action:$idempKey';
      if (_idempotencyResponses.containsKey(namespacedKey)) {
        if (_idempotencyPayloadHashes[namespacedKey] != body) {
          await _writeJson(request.response, 409, <String, dynamic>{
            'error': <String, dynamic>{
              'code': 'IDEMPOTENCY_CONFLICT',
              'message': 'Trùng Idempotency-Key nhưng payload khác.',
              'requestId': 'req_409',
              'retryable': false,
            },
          });
          return;
        }
        await _writeJson(
          request.response,
          200,
          _idempotencyResponses[namespacedKey]!,
        );
        return;
      }

      final Map<String, dynamic> map = jsonDecode(body) as Map<String, dynamic>;
      late final Map<String, dynamic> resp;
      if (action == 'events') {
        resp = <String, dynamic>{
          'sessionId': sessionId,
          'state': map['eventType'] == 'complete_ungraded'
              ? 'completed_ungraded'
              : 'active',
          'version': ((map['version'] as num?)?.toInt() ?? 1) + 1,
        };
      } else if (action == 'feedback') {
        resp = <String, dynamic>{
          'feedbackId': 'fb_${DateTime.now().microsecondsSinceEpoch}',
          'status': 'queued_for_review',
        };
      } else {
        answerPostCount += 1;
        final String answer =
            (map['answerValue'] as String? ?? '').trim().toLowerCase();
        final String reasoning =
            (map['reasoningText'] as String? ?? '').trim().toLowerCase();

        if (reasoning.contains('uncertain')) {
          resp = <String, dynamic>{
            'attemptId': 'att_txt_$answerPostCount',
            'result': 'uncertain',
            'observedSteps': <String>[],
            'firstIssue': null,
            'feedback': 'Chưa đủ rõ bước lập luận.',
            'hint': null,
            'nextActions': <String>['retry', 'finish_ungraded', 'emergency_stop'],
            'xpAwarded': 0,
            'modelVersion': 'gemini-test-double',
            'rubricRevision': 3,
          };
        } else if (answer == '8' || answer == 'x=8') {
          _xpByUid[uid] = (_xpByUid[uid] ?? 0) + 10;
          _completedByUid[uid] = (_completedByUid[uid] ?? 0) + 1;
          resp = <String, dynamic>{
            'attemptId': 'att_txt_$answerPostCount',
            'result': 'correct',
            'observedSteps': <String>[reasoning],
            'firstIssue': null,
            'feedback': 'Chính xác! Server cộng +10 XP.',
            'hint': null,
            'nextActions': <String>['finish'],
            'xpAwarded': 10,
            'modelVersion': 'gemini-test-double',
            'rubricRevision': 3,
          };
        } else {
          final int wrongs = (_wrongAttemptsBySession[sessionId] ?? 0) + 1;
          _wrongAttemptsBySession[sessionId] = wrongs;
          resp = <String, dynamic>{
            'attemptId': 'att_txt_$answerPostCount',
            'result': 'incorrect',
            'observedSteps': wrongs >= 3 ? <String>[reasoning] : <String>[],
            'firstIssue': wrongs >= 3 ? 'Kiểm tra phép phân phối 2(x - 3).' : null,
            'feedback': 'Bài này chưa đúng. Bạn có thể thử lại.',
            'hint': wrongs >= 3
                ? 'Nhân 2 vào cả hai số hạng trong ngoặc trước khi chuyển vế.'
                : null,
            'nextActions': <String>['retry', 'finish_ungraded', 'emergency_stop'],
            'xpAwarded': 0,
            'modelVersion': 'gemini-test-double',
            'rubricRevision': 3,
          };
        }
      }

      if (idempKey.isNotEmpty) {
        _idempotencyPayloadHashes[namespacedKey] = body;
        _idempotencyResponses[namespacedKey] = resp;
      }
      await _writeJson(request.response, 200, resp);
      return;
    }

    await _writeJson(request.response, 404, <String, dynamic>{
      'error': <String, dynamic>{
        'code': 'NOT_FOUND',
        'message': 'Endpoint không tồn tại.',
        'requestId': 'req_404',
        'retryable': false,
      },
    });
  }

  Future<void> _writeJson(
    HttpResponse response,
    int statusCode,
    Map<String, dynamic> body,
  ) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }
}
