// lib/services/api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/api_config.dart';

import '../narrative/prompt_builder.dart';
import '../narrative/narrative_state.dart';
import '../narrative/reader_intent.dart';
import '../narrative/auto_recall_builder.dart';
import '../narrative/recall_pack.dart';
import '../narrative/card_extractor.dart';
import '../narrative/narrative_db.dart';
import '../narrative/cards.dart';

enum ApiMode { promptOnly, openAI }

class ApiService {
  static const ApiMode mode = ApiMode.promptOnly;

  static const String _localBaseUrl = 'http://127.0.0.1:8001';
  static const String _lanBaseUrl = 'http://192.168.219.94:8000';
  static const bool useLan = false;

  static String get baseUrl => useLan ? _lanBaseUrl : _localBaseUrl;

  static Future<String> _resolvedBaseUrl() async {
    final saved = await ApiConfig.getBaseUrl();
    if (saved != null && saved.isNotEmpty) return saved;
    return baseUrl;
  }

  static const List<String> _forbiddenNarrationTokens = [
    '너',
    '네',
    '너의',
    '너에게',
    '너는',
    '당신',
    '당신의',
    '당신에게',
  ];

  static bool _isKoreanParticleChar(String s, int idx) {
    return idx >= 0 && idx < s.length;
  }

  static String _stripQuotedDialogue(String text) {
    final sb = StringBuffer();
    bool inQuote = false;

    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == '"') {
        inQuote = !inQuote;
        continue;
      }
      if (!inQuote) sb.write(ch);
    }
    return sb.toString();
  }

  static bool _hasForbiddenInNarration(String content) {
    final narrationOnly = _stripQuotedDialogue(content);

    for (final token in _forbiddenNarrationTokens) {
      final idx = narrationOnly.indexOf(token);
      if (idx >= 0 && _isKoreanParticleChar(narrationOnly, idx)) {
        return true;
      }
    }
    return false;
  }

  static int _charCount(String s) => s.replaceAll('\r\n', '\n').length;

  // OpenAI 거절 메시지 감지 (짧고 "처리할 수 없" 류 문구 포함)
  static bool _isRefusalContent(String content) {
    final t = content.trim();
    if (t.length > 300) return false; // 충분히 긴 본문은 거절 아님
    return t.contains('처리할 수 없') ||
        t.contains('죄송합니다') ||
        t.contains('요청을 처리') ||
        t.contains('I\'m sorry') ||
        t.contains('I cannot') ||
        t.contains('unable to');
  }

  static bool _isTooShort(String content, int targetChars) {
    final n = _charCount(content.trim());
    return n < (targetChars * 0.9).floor();
  }

  static String _postFixInstruction({
    required int targetChars,
    required bool needNoPronounFix,
    required bool needLengthFix,
  }) {
    final fixes = <String>[];
    if (needNoPronounFix) {
      fixes.add(
        '- 서술문에서 금지어(너/네/너의/너에게/너는/당신/당신의/당신에게)를 0회로 만들고, 반드시 무인칭으로만 다시 쓴다.',
      );
    }
    if (needLengthFix) {
      fixes.add(
        '- 분량을 약 ${targetChars}자 내외로 확장하되(최소 ${(targetChars * 0.9).floor()}자 이상), 설명이 아니라 장면(행동·대사·감각)으로 늘린다.',
      );
    }

    return [
      '[POST CHECK: 재작성 지시]',
      '- 방금 생성 결과는 규칙 위반이다. 아래 항목을 반영해 “전체를 다시” 작성하라.',
      ...fixes,
      '- 대사 속 "너"는 허용하되, 서술문에서는 위 금지어가 1회라도 나오면 즉시 다시 쓴 뒤 제출한다.',
      '- 제목/요약/캐릭터/에피소드 포맷이 있으면 유지하되, 본문 서술 규칙이 최우선이다.',
    ].join('\n');
  }

  // ============================================================
  // ✅ (NEW) 메모리(10줄) 요약 생성
  // - 같은 /generate에 prompt-only로 한 번 더 호출
  // - 결과는 "줄바꿈 10줄" 텍스트로 받음
  // ============================================================
  static Future<String> _generateMemorySummary10Lines({
    required String projectTitle,
    required String protagonistName,
    required String storyText,
  }) async {
    final uri = Uri.parse('${await _resolvedBaseUrl()}/generate');

    final prompt = [
      '너는 장편 연재소설의 “누적 메모리(Story Memory)”를 만드는 편집자다.',
      '',
      '[요약 규칙]',
      '- 아래 본문을 바탕으로 “딱 10줄”로 요약하라.',
      '- 각 줄은 1문장(또는 1개의 사실)로 끝내고 줄바꿈으로 10줄을 만든다.',
      '- 문체는 “명사형/사실형”으로 간결하게(불필요한 수식 금지).',
      '- 2인칭(너/당신) 금지. 1인칭(나/저/우리) 금지. 3인칭 대명사(그/그녀/그는/그녀는)도 금지.',
      '- 대신 고유명사(인물명/장소/조직/아이템/사건명)를 그대로 사용한다.',
      '- 반드시 포함: 핵심 사건 3개, 관계/긴장 2개, 미해결/압력 2개, 현재 목표/갈림길 1개, 분위기/금기 2개',
      '',
      '[작품 정보]',
      '- 제목: $projectTitle',
      '- 주인공: $protagonistName',
      '',
      '[본문]',
      storyText,
      '',
      '[출력]',
      '- 오직 “10줄 요약”만 출력하라(제목/라벨/머리말 금지).',
    ].join('\n');

    final payload = {
      'prompt': prompt,
      'synopsis': '',
      'genre': 'drama',
      'tone': 'normal',
      'length_hint': 3000,
      'request': '',
      'guide': '',
      'option': 'memory',
      'mode': 'memory',
    };

    final res = await http
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw '메모리 요약 생성 실패 HTTP ${res.statusCode}: ${res.body}';
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final text = (data['content'] ?? '').toString().trim();
    if (text.isEmpty) throw '메모리 요약 content가 비어있음';

    // ✅ 안전: 10줄이 아니어도, StorageService에서 라인 정리/클램프 처리
    return text;
  }

  static Future<Episode> generateEpisode({
    required StoryProject project,
    required int number,
    required Tone tone,
    required String userRequest,
    required String scenarioInput,
    int lengthHint = 5000,
    String genre = 'drama',
  }) async {
    await StorageService.init();

    if (project.protagonistName.trim().isEmpty) {
      throw '주인공 이름이 프로젝트에 저장되어 있지 않습니다.\n'
          '1화에서 입력한 이름이 저장되었는지 확인 후 다시 시도하세요.';
    }

    // ✅ 최신 project를 다시 가져와 episodes 누락 방지
    final latest = StorageService.findById(project.id);
    if (latest != null) {
      project = latest;
    }

    final NarrativeState state = await StorageService.loadState(
      project.id,
      defaultEpisodeNo: number - 1,
    );

    final ReaderIntent intent = _buildIntentFromInputs(
      tone: tone,
      userRequest: userRequest,
      scenarioInput: scenarioInput,
    );

    final List<CardBase> newCards = CardExtractor.extract(
      scenarioInput: scenarioInput,
      nextEpisodeNo: number,
    );

    final RecallPack recall = await AutoRecallBuilder.build(
      projectId: project.id,
      project: project,
      nextNumber: number,
      intent: intent,
      maxCards: 8,
      maxFragments: 2,
      extraCards: newCards,
    );

    // ✅ (NEW) 누적 메모리 30줄 로드 → PromptBuilder로 전달
    final storyMemoryLines = await StorageService.loadStoryMemoryLines(
      project.id,
      maxLines: 30,
    );

    final String basePrompt = PromptBuilder.build(
      project: project,
      nextNumber: number,
      tone: tone,
      userRequest: userRequest,
      scenarioInput: scenarioInput,
      state: state,
      intent: intent,
      recall: recall,
      targetChars: lengthHint,
      storyMemoryLines: storyMemoryLines, // ✅ 추가
    );

    final synopsis = '''
[프로젝트 뼈대]
${project.baseScenario}

[이번 화 가이드]
$scenarioInput

[요청]
$userRequest

요청을 반영해 다음 화를 소설 본문으로 작성해줘.
''';

    final resolvedUrl = await _resolvedBaseUrl();
    final uri = Uri.parse('$resolvedUrl/generate');

    debugPrint('[ApiService] generateEpisode 시작');
    debugPrint('[ApiService]  number=$number tone=${tone.apiKey} lengthHint=$lengthHint');
    debugPrint('[ApiService]  userRequest="${userRequest.length > 80 ? userRequest.substring(0, 80) : userRequest}"');
    debugPrint('[ApiService]  scenarioInput="${scenarioInput.length > 80 ? scenarioInput.substring(0, 80) : scenarioInput}"');
    debugPrint('[ApiService]  endpoint=$uri');

    const int maxAttempts = 3;
    String lastTitle = '${number}화';
    String lastContent = '';
    String usedPromptForThisEpisode = basePrompt;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      String prompt = basePrompt;

      if (attempt > 1 && lastContent.isNotEmpty) {
        final needNoPronounFix = _hasForbiddenInNarration(lastContent);
        final needLengthFix = _isTooShort(lastContent, lengthHint);

        if (!needNoPronounFix && !needLengthFix) break;

        debugPrint('[ApiService]  attempt=$attempt needPronounFix=$needNoPronounFix needLengthFix=$needLengthFix → 재시도');

        prompt = [
          basePrompt,
          '',
          _postFixInstruction(
            targetChars: lengthHint,
            needNoPronounFix: needNoPronounFix,
            needLengthFix: needLengthFix,
          ),
        ].join('\n');
      }

      usedPromptForThisEpisode = prompt;

      final payload = {
        'prompt': prompt,
        'synopsis': synopsis,
        'genre': genre,
        'tone': tone.apiKey,
        'length_hint': lengthHint,
        'request': userRequest,
        'guide': scenarioInput,
        'option': tone.label.toString(),
        'mode': tone.apiKey,
      };

      debugPrint('[ApiService]  HTTP POST 시도 attempt=$attempt ...');

      late http.Response res;
      try {
        res = await http
            .post(
              uri,
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 90));
      } catch (e) {
        debugPrint('[ApiService]  HTTP 요청 실패: $e');
        rethrow;
      }

      debugPrint('[ApiService]  응답 statusCode=${res.statusCode}');
      debugPrint('[ApiService]  응답 body(앞 300자)=${res.body.length > 300 ? res.body.substring(0, 300) : res.body}');

      if (res.statusCode != 200) {
        throw 'HTTP ${res.statusCode}: ${res.body}';
      }

      late Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('[ApiService]  JSON decode 실패: $e');
        throw 'JSON 파싱 오류: $e\nbody=${res.body.length > 200 ? res.body.substring(0, 200) : res.body}';
      }

      debugPrint('[ApiService]  응답 필드=${data.keys.toList()}');

      // 백엔드는 title 필드를 반환하지 않음 → number화로 고정
      lastContent = (data['content'] ?? '').toString();

      debugPrint('[ApiService]  content 길이=${lastContent.length} (목표=${(lengthHint * 0.9).floor()}자 이상)');

      if (lastContent.trim().isEmpty) {
        throw '서버 응답 content가 비어있음 (백엔드 로그 확인 필요)';
      }

      // OpenAI 거절 메시지 감지
      if (_isRefusalContent(lastContent)) {
        debugPrint('[ApiService]  OpenAI 거절 메시지 감지: "${lastContent.substring(0, lastContent.length.clamp(0, 80))}"');
        throw 'OpenAI가 이 요청을 거절했습니다. 프롬프트 내용을 확인해주세요.\n원문: $lastContent';
      }

      final hasForbidden = _hasForbiddenInNarration(lastContent);
      final tooShort = _isTooShort(lastContent, lengthHint);

      debugPrint('[ApiService]  hasForbidden=$hasForbidden tooShort=$tooShort');

      if (!hasForbidden && !tooShort) {
        debugPrint('[ApiService]  품질 검증 통과 (attempt=$attempt)');
        break;
      }
    }

    final nextState = NarrativeState(
      episodeNo: number,
      timeHint: state.timeHint,
      relationshipTemp: state.relationshipTemp,
      unresolved: state.unresolved,
      sensory: state.sensory,
      goal: state.goal,
    );
    await StorageService.saveState(project.id, nextState);

    final episode = Episode(
      number: number,
      title: lastTitle,
      content: lastContent,
      prompt: usedPromptForThisEpisode,
      createdAt: DateTime.now(),
      userRequest: userRequest,
      scenarioInput: scenarioInput,
      tone: tone,
    );

    // ✅ episodes 누적 저장
    final idx = project.episodes.indexWhere((e) => e.number == number);
    if (idx >= 0) {
      project.episodes[idx] = episode;
    } else {
      project.episodes.add(episode);
      project.episodes.sort((a, b) => a.number.compareTo(b.number));
    }

    // ✅ 프로젝트 먼저 저장
    await StorageService.upsertProject(project);

    // ✅ 시나리오에서 추출한 카드 DB 반영
    for (final card in newCards) {
      await NarrativeDB.upsertCard(project.id, card);
    }

    // ============================================================
    // ✅ (NEW) 누적 메모리 10줄 생성 → 30줄로 누적 저장
    // - 실패해도 본문 저장은 이미 끝났으니, 메모리만 스킵(앱 죽이지 않기)
    // ============================================================
    try {
      final mem10 = await _generateMemorySummary10Lines(
        projectTitle: project.title,
        protagonistName: project.protagonistName,
        storyText: lastContent,
      );
      await StorageService.appendStoryMemory(
        projectId: project.id,
        newMemoryText: mem10,
        perEpisodeTargetLines: 10,
        maxLines: 30,
      );
    } catch (_) {
      // 메모리 갱신 실패는 치명적이지 않으므로 무시(원하면 로그로 남겨도 됨)
    }

    return episode;
  }

  static ReaderIntent _buildIntentFromInputs({
    required Tone tone,
    required String userRequest,
    required String scenarioInput,
  }) {
    final merged = '${userRequest.trim()}\n${scenarioInput.trim()}'.trim();
    final base = ReaderIntent.fromUserText(merged);

    int intensity = base.intensity;
    int detail = base.detail;
    bool expandCast = base.expandCast;
    bool requestTwist = base.requestTwist;
    bool allowDeath = base.allowDeath;
    bool allowRomance = base.allowRomance;

    switch (tone) {
      case Tone.detailed:
        detail = 2;
        break;
      case Tone.spicy:
        intensity = 2;
        break;
      case Tone.expand:
        expandCast = true;
        break;
      case Tone.normal:
      default:
        break;
    }

    intensity = intensity.clamp(-2, 2);
    detail = detail.clamp(-2, 2);

    return ReaderIntent(
      intensity: intensity,
      detail: detail,
      expandCast: expandCast,
      requestTwist: requestTwist,
      allowDeath: allowDeath,
      allowRomance: allowRomance,
    );
  }
}






