import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/api_config.dart';

import '../narrative/reader_intent.dart';
import '../narrative/narrative_state.dart';
import '../narrative/prompt_builder.dart';

// ✅ 카드 자동 Recall 생성기
import '../narrative/auto_recall_builder.dart';

// ✅ 카드 자동 축적(시나리오에서 장소/인물/떡밥)
import '../narrative/narrative_db.dart';
import '../narrative/card_extractor.dart';
import '../narrative/cards.dart';

class GenerateEpisodeScreen extends StatefulWidget {
  final StoryProject project;
  const GenerateEpisodeScreen({super.key, required this.project});

  @override
  State<GenerateEpisodeScreen> createState() => _GenerateEpisodeScreenState();
}

class _GenerateEpisodeScreenState extends State<GenerateEpisodeScreen> {
  final _requestCtrl = TextEditingController();
  final _scenarioCtrl = TextEditingController();

  Tone _tone = Tone.normal;
  bool _isGenerating = false;

  @override
  void dispose() {
    _requestCtrl.dispose();
    _scenarioCtrl.dispose();
    super.dispose();
  }

  int get _nextNumber => widget.project.episodes.isEmpty
      ? 1
      : (widget.project.episodes
              .map((e) => e.number)
              .reduce((a, b) => a > b ? a : b) +
          1);

  // ✅ App Tester(배포 설치)에서도 동작하도록:
  // 1) SharedPreferences 저장값(ApiConfig) 우선
  // 2) 없으면 기본값(네 PC IPv4 기준)
  Future<String> _apiBaseUrl() async {
    final saved = await ApiConfig.getBaseUrl();
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();

    // 기본값: 같은 와이파이 PC에서 켜둔 FastAPI
    return 'http://192.168.219.55:8001';
  }

  // Tone을 백엔드에 보내기 위한 안전한 문자열 키
  // (Tone이 enum이 아니어도 최대한 안전하게 처리)
  String _toneKey(Tone t) {
    final s = t.toString(); // e.g. Tone.normal
    if (s.contains('.')) return s.split('.').last;
    return s;
  }

  Future<Map<String, dynamic>> _callGenerateApi({
    required String baseUrl,
    required String userRequest,
    required String scenarioInput,
    required Tone tone,
    required int lengthHint,
  }) async {
    final uri = Uri.parse('$baseUrl/generate');

    // ✅ 백엔드 /generate 스키마에 맞춰 전송
    final body = <String, dynamic>{
      "synopsis": "",
      "genre": "drama",
      "tone": _toneKey(tone),
      "length_hint": lengthHint,
      "request": userRequest,
      "guide": scenarioInput,
      "mode": "default",
      "option": {},
    };

    final res = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API 오류(${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('API 응답 형식 오류: ${res.body}');
    }
    return decoded;
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);

    final userRequest =
        _requestCtrl.text.trim().isEmpty ? '기본 생성' : _requestCtrl.text.trim();

    final scenarioInput = _scenarioCtrl.text.trim().isEmpty
        ? '기본 뼈대 기반으로 진행'
        : _scenarioCtrl.text.trim();

    try {
      // 1) 독자 의도(규칙 기반 파싱)
      final intent = ReaderIntent.fromUserText(userRequest);

      // 2) 프로젝트별 상태 로드
      final state = await StorageService.loadState(
        widget.project.id,
        defaultEpisodeNo: _nextNumber - 1,
      );

      // ✅ 이번 입력(가이드)에서 카드 먼저 "추출만" 해둔다 (저장 X)
      final newCards = CardExtractor.extract(
        scenarioInput: scenarioInput,
        nextEpisodeNo: _nextNumber,
      );

      // 3) ✅ 자동 Recall Pack 생성
      final recall = await AutoRecallBuilder.build(
        projectId: widget.project.id,
        project: widget.project,
        nextNumber: _nextNumber,
        intent: intent,
        maxCards: 8,
        maxFragments: 2,
        extraCards: newCards,
      );

      // 4) 프롬프트 생성(참고/백업용)
      final prompt = PromptBuilder.build(
        project: widget.project,
        nextNumber: _nextNumber,
        tone: _tone,
        userRequest: userRequest,
        scenarioInput: scenarioInput,
        state: state,
        intent: intent,
        recall: recall,
        targetChars: 5000,
      );

      // 5) ✅ 백엔드 호출해서 소설 본문(content) 받기
      final baseUrl = await _apiBaseUrl();

      final apiResult = await _callGenerateApi(
        baseUrl: baseUrl,
        userRequest: userRequest,
        scenarioInput: scenarioInput,
        tone: _tone,
        lengthHint: 5000,
      );

      final content = (apiResult['content'] ?? '').toString().trim();
      final promptFromApi = (apiResult['prompt_text'] ?? '').toString().trim();

      if (content.isEmpty) {
        throw Exception('API가 content를 반환하지 않았습니다.');
      }

      // ✅ 6) 여기서부터 저장: 성공한 경우에만 상태/카드/에피소드 저장

      // 상태 업데이트(episodeNo만 증가)
      final updated = NarrativeState.fromJson({
        ...state.toJson(),
        "episodeNo": _nextNumber,
      });
      await StorageService.saveState(widget.project.id, updated);

      // 카드 DB 반영
      for (final CardBase nc in newCards) {
        await NarrativeDB.upsertCard(widget.project.id, nc);
      }

      // Episode 저장: content(본문) + prompt(참고용)
      final episode = Episode(
        number: _nextNumber,
        title: '${_nextNumber}화',
        content: content,
        prompt: promptFromApi.isNotEmpty ? promptFromApi : prompt,
        createdAt: DateTime.now(),
        userRequest: userRequest,
        scenarioInput: scenarioInput,
        tone: _tone,
      );

      if (!mounted) return;
      setState(() => _isGenerating = false);

      Navigator.pop(context, episode);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('생성 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_nextNumber}화 만들기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '요청(독자/작성자 요구사항)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _requestCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '예) 지금까지 내용을 더 구체적으로, 더 자극적으로, 주변 인물 추가 등',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '톤 선택',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _TonePicker(
            selected: _tone,
            onChanged: (t) => setState(() => _tone = t),
          ),
          const SizedBox(height: 14),
          const Text(
            '이번 화의 시나리오/가이드(선택)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _scenarioCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '예)\n장소: ___\n인물: A(성격), B(성격)\n떡밥: ___\n(없어도 됨)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isGenerating ? null : _generate,
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isGenerating ? '생성 중...' : '생성하기'),
          ),
        ],
      ),
    );
  }
}

class _TonePicker extends StatelessWidget {
  final Tone selected;
  final ValueChanged<Tone> onChanged;

  const _TonePicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: Tone.values.map((t) {
        final isSelected = t == selected;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Icon(t.icon),
            title: Text(
              t.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(t.hint),
            trailing: isSelected
                ? const Icon(Icons.check_circle)
                : const Icon(Icons.circle_outlined),
            onTap: () => onChanged(t),
          ),
        );
      }).toList(),
    );
  }
}






