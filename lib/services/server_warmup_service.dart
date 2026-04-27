// lib/services/server_warmup_service.dart
//
// 앱 시작 시 Render 서버를 미리 웜업하는 서비스.
// - 싱글톤: ServerWarmupService.instance
// - warmup() 은 fire-and-forget 으로 호출 (결과 무시 가능)
// - isReady / statusNotifier 로 현재 상태 조회
// - readyFuture 를 await 하면 준비 완료 or 실패 후 반환

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart'; // baseUrl 재사용

enum ServerStatus { warming, ready, failed }

class ServerWarmupService {
  ServerWarmupService._();
  static final ServerWarmupService instance = ServerWarmupService._();

  bool isReady = false;
  final ValueNotifier<ServerStatus> statusNotifier =
      ValueNotifier(ServerStatus.warming);
  final Completer<void> _completer = Completer();

  /// 서버 준비가 끝날 때(성공 or 실패) resolve 되는 Future.
  Future<void> get readyFuture => _completer.future;

  /// 백그라운드 웜업 시작. 중복 호출 방지.
  Future<void> warmup() async {
    if (_completer.isCompleted) return;

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/health');
      debugPrint('[ServerWarmup] GET $uri …');

      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 60));

      if (res.statusCode == 200) {
        isReady = true;
        statusNotifier.value = ServerStatus.ready;
        debugPrint('[ServerWarmup] 서버 준비 완료 (${res.statusCode})');
      } else {
        statusNotifier.value = ServerStatus.failed;
        debugPrint('[ServerWarmup] 서버 비정상 응답 (${res.statusCode})');
      }
    } catch (e) {
      statusNotifier.value = ServerStatus.failed;
      debugPrint('[ServerWarmup] 웜업 실패(무시): $e');
    } finally {
      if (!_completer.isCompleted) _completer.complete();
    }
  }
}
