// lib/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../narrative/narrative_state.dart';

class StorageService {
  static const _kProjectsKey = 'reader_pov_projects_v1';

  static late SharedPreferences _prefs;
  static final List<StoryProject> projects = [];

  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    _prefs = await SharedPreferences.getInstance();
    await _load();
    _inited = true;
  }

  static SharedPreferences get prefs => _prefs;

  static Future<void> _load() async {
    projects.clear();

    final raw = _prefs.getString(_kProjectsKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          projects.add(StoryProject.fromJson(item));
        } else if (item is Map) {
          projects.add(StoryProject.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } catch (_) {}
  }

  static Future<void> save() async {
    final list = projects.map((p) => p.toJson()).toList();
    final raw = jsonEncode(list);
    await _prefs.setString(_kProjectsKey, raw);
  }

  static Future<void> upsertProject(StoryProject p) async {
    final idx = projects.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      projects[idx] = p;
    } else {
      projects.insert(0, p);
    }
    await save();
  }

  static Future<void> deleteProjectById(String id) async {
    projects.removeWhere((p) => p.id == id);
    await save();
  }

  static StoryProject? findById(String id) {
    final idx = projects.indexWhere((p) => p.id == id);
    if (idx < 0) return null;
    return projects[idx];
  }

  // =========================================================
  // ✅ 프로젝트별 “상태(state)” 저장/로드
  // =========================================================
  static String _kStateKey(String projectId) => 'rpov_state_$projectId';

  static Future<NarrativeState> loadState(
    String projectId, {
    int defaultEpisodeNo = 0,
  }) async {
    final raw = _prefs.getString(_kStateKey(projectId));

    if (raw == null || raw.trim().isEmpty) {
      return NarrativeState(
        episodeNo: defaultEpisodeNo,
        timeHint: "같은 날 밤",
        relationshipTemp: "긴장",
        unresolved: const ["확인하지 않음"],
        sensory: const ["차가운 공기", "어딘가에서 들리는 미세한 소음"],
        goal: "다음 행동 직전까지",
      );
    }

    try {
      final m = jsonDecode(raw);
      return NarrativeState.fromJson(Map<String, dynamic>.from(m as Map));
    } catch (_) {
      return NarrativeState(
        episodeNo: defaultEpisodeNo,
        timeHint: "같은 날 밤",
        relationshipTemp: "긴장",
        unresolved: const ["확인하지 않음"],
        sensory: const ["차가운 공기"],
        goal: "다음 행동 직전까지",
      );
    }
  }

  static Future<void> saveState(String projectId, NarrativeState state) async {
    final raw = jsonEncode(state.toJson());
    await _prefs.setString(_kStateKey(projectId), raw);
  }

  // =========================================================
  // ✅ (NEW) 프로젝트별 “누적 메모리(Story Memory)” 저장/로드
  // - key: rpov_memory_<projectId>
  // - 저장 형태: lines를 \n으로 이어붙인 단일 문자열
  // =========================================================
  static String _kMemoryKey(String projectId) => 'rpov_memory_$projectId';

  static Future<List<String>> loadStoryMemoryLines(
    String projectId, {
    int maxLines = 30,
  }) async {
    final raw = _prefs.getString(_kMemoryKey(projectId)) ?? '';
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.length <= maxLines) return lines;
    return lines.sublist(lines.length - maxLines);
  }

  static Future<void> saveStoryMemoryLines(
    String projectId,
    List<String> lines,
  ) async {
    final cleaned = lines.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    await _prefs.setString(_kMemoryKey(projectId), cleaned.join('\n'));
  }

  /// ✅ 새 메모리 텍스트(모델 출력)를 append하고, perEpisodeTargetLines=10 / maxLines=30 유지
  static Future<void> appendStoryMemory({
    required String projectId,
    required String newMemoryText,
    int perEpisodeTargetLines = 10,
    int maxLines = 30,
  }) async {
    final current = await loadStoryMemoryLines(projectId, maxLines: 9999);

    // newMemoryText를 라인으로 분해
    final incoming = newMemoryText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // ✅ 안전: “10줄”이 아닐 수도 있으니 강제로 자르거나 채움(최소한 10줄만 취함)
    final normalizedIncoming = (incoming.length <= perEpisodeTargetLines)
        ? incoming
        : incoming.sublist(0, perEpisodeTargetLines);

    final merged = [...current, ...normalizedIncoming]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // ✅ maxLines 유지(최근 것만)
    final finalLines = (merged.length <= maxLines)
        ? merged
        : merged.sublist(merged.length - maxLines);

    await saveStoryMemoryLines(projectId, finalLines);
  }
}



