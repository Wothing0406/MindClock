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
  Duration artificialStudyHelpDelay = Duration.zero;
  bool failNextAlarmSync = false;
  bool failNextStudyHelp = false;
  bool rateLimitNextStudyHelp = false;
  bool failNextStudyFinish = false;

  int answerPostCount = 0;
  int attemptMultipartCount = 0;
  int alarmCreateCount = 0;
  int alarmPatchCount = 0;
  int uniqueStudyFinishCount = 0;
  final List<String> seenIdempotencyKeys = <String>[];
  final List<String> recordedEmergencyDismissEvents = <String>[];
  final List<Map<String, dynamic>> studyCreateRequests = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> studyHelpRequests = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> studyFinishRequests = <Map<String, dynamic>>[];

  final Map<String, String> _sessionOwners = <String, String>{};
  final Map<String, String> _alarmOwners = <String, String>{};
  final Map<String, Map<String, dynamic>> _alarmsById =
      <String, Map<String, dynamic>>{};
  final Map<String, String> _studySessionOwners = <String, String>{};
  final Map<String, String> _studyRemoteByClient = <String, String>{};
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
        if (map['eventType'] == 'dismiss') {
          recordedEmergencyDismissEvents.add(sessionId);
        }
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

    // 2. Routes báo thức `/v1/alarms` & `/v1/alarms/{id}`
    if (path == '/v1/alarms' && request.method == 'GET') {
      final List<Map<String, dynamic>> items = _alarmsById.entries
          .where((MapEntry<String, Map<String, dynamic>> e) =>
              _alarmOwners[e.key] == uid)
          .map((MapEntry<String, Map<String, dynamic>> e) => e.value)
          .toList(growable: false);
      await _writeJson(request.response, 200, <String, dynamic>{'items': items});
      return;
    }

    if (path == '/v1/alarms' && request.method == 'POST') {
      if (failNextAlarmSync) {
        failNextAlarmSync = false;
        await _writeJson(request.response, 503, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'SERVICE_UNAVAILABLE',
            'message': 'Server báo thức tạm bận.',
            'retryable': true,
          },
        });
        return;
      }
      final String idempKey = request.headers.value('Idempotency-Key') ?? '';
      if (idempKey.isNotEmpty) {
        seenIdempotencyKeys.add(idempKey);
      }
      final String body = await utf8.decodeStream(request);
      final String namespacedKey = '$uid:alarm_post:$idempKey';
      if (idempKey.isNotEmpty && _idempotencyResponses.containsKey(namespacedKey)) {
        await _writeJson(
          request.response,
          200,
          _idempotencyResponses[namespacedKey]!,
        );
        return;
      }
      final Map<String, dynamic> map = jsonDecode(body) as Map<String, dynamic>;
      alarmCreateCount += 1;
      final String alarmId = 'srv_alarm_$alarmCreateCount';
      final Map<String, dynamic> record = <String, dynamic>{
        'id': alarmId,
        'localTime': map['localTime'] ?? '06:00',
        'timeZone': map['timeZone'] ?? 'Asia/Ho_Chi_Minh',
        'weekdays': map['weekdays'] ?? <int>[],
        'enabled': map['enabled'] ?? true,
        'challengeMode': map['challengeMode'] ?? 'short_review',
        'snoozeMinutes': map['snoozeMinutes'],
        'revision': 1,
      };
      _alarmOwners[alarmId] = uid;
      _alarmsById[alarmId] = record;
      if (idempKey.isNotEmpty) {
        _idempotencyResponses[namespacedKey] = record;
      }
      await _writeJson(request.response, 200, record);
      return;
    }

    final RegExp alarmItemRoute = RegExp(r'^/v1/alarms/([^/]+)$');
    final Match? alarmMatch = alarmItemRoute.firstMatch(path);
    if (alarmMatch != null) {
      final String alarmId = alarmMatch.group(1)!;
      final String? owner = _alarmOwners[alarmId];
      if (owner == null) {
        await _writeJson(request.response, 404, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'ALARM_NOT_FOUND',
            'message': 'Không tìm thấy báo thức.',
            'retryable': false,
          },
        });
        return;
      }
      if (owner != uid) {
        await _writeJson(request.response, 403, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'FORBIDDEN_OWNER',
            'message': 'Không có quyền sửa/xóa báo thức của tài khoản khác.',
            'retryable': false,
          },
        });
        return;
      }
      if (request.method == 'PATCH') {
        if (failNextAlarmSync) {
          failNextAlarmSync = false;
          await _writeJson(request.response, 503, <String, dynamic>{
            'error': <String, dynamic>{
              'code': 'SERVICE_UNAVAILABLE',
              'message': 'Server báo thức tạm bận.',
              'retryable': true,
            },
          });
          return;
        }
        final String body = await utf8.decodeStream(request);
        final Map<String, dynamic> map =
            jsonDecode(body) as Map<String, dynamic>;
        alarmPatchCount += 1;
        final Map<String, dynamic> existing = _alarmsById[alarmId]!;
        final int nextRev = ((existing['revision'] as num?)?.toInt() ?? 1) + 1;
        final Map<String, dynamic> updated = <String, dynamic>{
          ...existing,
          ...map,
          'id': alarmId,
          'revision': nextRev,
        };
        _alarmsById[alarmId] = updated;
        await _writeJson(request.response, 200, updated);
        return;
      }
      if (request.method == 'DELETE') {
        _alarmsById.remove(alarmId);
        _alarmOwners.remove(alarmId);
        request.response.statusCode = 204;
        await request.response.close();
        return;
      }
    }

    // 3. Routes Không gian học & AI `/v1/study/*`
    if (path == '/v1/study/sessions' && request.method == 'POST') {
      final String idempKey = request.headers.value('Idempotency-Key') ?? '';
      if (idempKey.isNotEmpty) {
        seenIdempotencyKeys.add(idempKey);
      }
      final String body = await utf8.decodeStream(request);
      final Map<String, dynamic> map = jsonDecode(body) as Map<String, dynamic>;
      studyCreateRequests.add(map);

      final String namespacedKey = '$uid:study_create:$idempKey';
      if (idempKey.isNotEmpty && _idempotencyResponses.containsKey(namespacedKey)) {
        await _writeJson(
          request.response,
          200,
          _idempotencyResponses[namespacedKey]!,
        );
        return;
      }

      final String clientSessionId =
          (map['clientSessionId'] as String? ?? 'study_1').trim();
      final String remoteId = _studyRemoteByClient['$uid:$clientSessionId'] ??
          'srv_study_$clientSessionId';
      _studyRemoteByClient['$uid:$clientSessionId'] = remoteId;
      _studySessionOwners[remoteId] = uid;
      _studySessionOwners[clientSessionId] = uid;

      final Map<String, dynamic> resp = <String, dynamic>{
        'sessionId': remoteId,
        'clientSessionId': clientSessionId,
        'state': 'active',
      };
      if (idempKey.isNotEmpty) {
        _idempotencyResponses[namespacedKey] = resp;
      }
      await _writeJson(request.response, 200, resp);
      return;
    }

    final RegExp studyFinishRoute =
        RegExp(r'^/v1/study/sessions/([^/]+)/finish$');
    final Match? studyFinishMatch = studyFinishRoute.firstMatch(path);
    if (studyFinishMatch != null && request.method == 'POST') {
      if (failNextStudyFinish) {
        failNextStudyFinish = false;
        await _writeJson(request.response, 503, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'SERVICE_UNAVAILABLE',
            'message': 'Máy chủ lưu phiên học tạm thời gián đoạn.',
            'retryable': true,
          },
        });
        return;
      }
      final String sessionId = studyFinishMatch.group(1)!;
      final String? owner = _studySessionOwners[sessionId];
      if (owner != null && owner != uid) {
        await _writeJson(request.response, 403, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'FORBIDDEN_OWNER',
            'message': 'Không có quyền kết thúc phiên học của người khác.',
            'retryable': false,
          },
        });
        return;
      }

      final String idempKey = request.headers.value('Idempotency-Key') ?? '';
      if (idempKey.isNotEmpty) {
        seenIdempotencyKeys.add(idempKey);
      }
      final String body = await utf8.decodeStream(request);
      final Map<String, dynamic> map = jsonDecode(body) as Map<String, dynamic>;
      studyFinishRequests.add(map);

      final String namespacedKey = '$uid:study_finish:$idempKey';
      if (idempKey.isNotEmpty && _idempotencyResponses.containsKey(namespacedKey)) {
        await _writeJson(
          request.response,
          200,
          _idempotencyResponses[namespacedKey]!,
        );
        return;
      }

      uniqueStudyFinishCount += 1;
      final Map<String, dynamic> resp = <String, dynamic>{
        'sessionId': sessionId,
        'clientSessionId': map['clientSessionId'] ?? sessionId,
        'state': 'finished',
        'xpAwarded': 0,
      };
      if (idempKey.isNotEmpty) {
        _idempotencyResponses[namespacedKey] = resp;
      }
      await _writeJson(request.response, 200, resp);
      return;
    }

    if (path == '/v1/study/help' && request.method == 'POST') {
      if (artificialStudyHelpDelay > Duration.zero) {
        await Future<void>.delayed(artificialStudyHelpDelay);
      }
      if (rateLimitNextStudyHelp) {
        rateLimitNextStudyHelp = false;
        await _writeJson(request.response, 429, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'RATE_LIMITED',
            'message': 'Bạn hỏi hơi nhanh, thử lại sau ít giây.',
            'retryable': true,
          },
        });
        return;
      }
      if (failNextStudyHelp) {
        failNextStudyHelp = false;
        await _writeJson(request.response, 503, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'AI_UPSTREAM_UNAVAILABLE',
            'message': 'Dịch vụ gợi ý tạm thời gián đoạn.',
            'retryable': true,
          },
        });
        return;
      }
      final String idempKey = request.headers.value('Idempotency-Key') ?? '';
      if (idempKey.isNotEmpty) {
        seenIdempotencyKeys.add(idempKey);
      }
      final String body = await utf8.decodeStream(request);
      final Map<String, dynamic> map = jsonDecode(body) as Map<String, dynamic>;
      studyHelpRequests.add(map);

      final String targetSessionId =
          (map['clientSessionId'] as String? ?? '').trim();
      final String? owner = _studySessionOwners[targetSessionId];
      if (owner != null && owner != uid) {
        await _writeJson(request.response, 403, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'FORBIDDEN_OWNER',
            'message': 'Không có quyền hỏi trong phiên của người khác.',
            'retryable': false,
          },
        });
        return;
      }

      final Map<String, dynamic> resp = <String, dynamic>{
        'message_vi':
            'Thử xác định ẩn x trước, rồi viết một phương trình ngắn cho dữ kiện đầu tiên.',
        'next_question_vi': 'Nếu gọi ẩn là x, vế trái sẽ biểu diễn thế nào?',
        'help_level': 'socratic',
        'safety_status': 'safe',
      };
      await _writeJson(request.response, 200, resp);
      return;
    }

    if (path == '/v1/questions/personalized' && request.method == 'POST') {
      final String body = await utf8.decodeStream(request);
      final Map<String, dynamic> map = jsonDecode(body) as Map<String, dynamic>;
      final String subject =
          (map['subjectCode'] as String? ?? 'TOAN').toUpperCase();
      final String grade = (map['gradeLevel'] as String? ?? 'Lớp 9').trim();
      final String topic =
          (map['topicHint'] as String? ?? 'Kiến thức trọng tâm').trim();
      await _writeJson(request.response, 200, <String, dynamic>{
        'questionId': 'ai_q_${subject.toLowerCase()}_01',
        'subjectCode': subject,
        'gradeBand': grade,
        'topicId': '${subject.toLowerCase()}_custom',
        'difficulty': map['difficulty'] ?? 1,
        'prompt': '[$subject · $grade] Ôn $topic: Hãy nêu bước đầu tiên để giải bài.',
        'reasoningPromptVi': 'Viết ngắn gọn 1–2 bước lý giải trước khi chốt đáp án.',
        'steps': <String>['Xác định dữ kiện đề', 'Áp dụng công thức trọng tâm'],
        'hintVi': 'Thử liệt kê các đại lượng đã biết.',
        'status': 'draft',
        'sourceType': 'ai_personalized_draft',
        'modelVersion': 'gemini-3.8-flash',
        'xpAwarded': 0,
        'fallbackUsed': false,
      });
      return;
    }

    if (path == '/v1/study/live-token' && request.method == 'POST') {
      final String body = await utf8.decodeStream(request);
      final Map<String, dynamic> map = jsonDecode(body) as Map<String, dynamic>;
      if (map['consentGranted'] != true) {
        await _writeJson(request.response, 403, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'CONSENT_REQUIRED',
            'message': 'Cần đồng ý rõ ràng trước khi mở Gemini Live.',
            'retryable': false,
          },
        });
        return;
      }
      final String subject = (map['subjectCode'] as String? ?? 'TOAN').trim();
      final String grade = (map['gradeLevel'] as String? ?? 'Lớp 9').trim();
      await _writeJson(request.response, 200, <String, dynamic>{
        'tokenName': 'auth_tokens/loopback_live_01',
        'wsUrl':
            'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained?access_token=auth_tokens/loopback_live_01',
        'model': 'gemini-3.8-live',
        'expiresAt': '2026-11-14T12:00:00Z',
        'expiresInSeconds': 600,
        'responseModalities': <String>[
          (map['responseModality'] as String? ?? 'AUDIO'),
        ],
        'contextSummary': '$subject · $grade',
        'isMock': true,
      });
      return;
    }

    if (path == '/v1/me' && request.method == 'PATCH') {
      final String body = await utf8.decodeStream(request);
      final Map<String, dynamic> map = jsonDecode(body) as Map<String, dynamic>;
      await _writeJson(request.response, 200, <String, dynamic>{
        'id': uid,
        'authSubject': uid,
        'alias': map['alias'] ?? 'Học sinh',
        'gradeLevel': map['gradeLevel'] ?? 'Lớp 9',
        'selectedSubjects': map['selectedSubjects'] ?? <String>['TOAN'],
      });
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
