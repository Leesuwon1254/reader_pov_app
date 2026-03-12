import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class LocalStore {
  static const _kProjects = 'projects_v1';

  /// 전체 프로젝트 불러오기
  static Future<List<StoryProject>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProjects);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => m.toStoryProject())
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 전체 프로젝트 저장
  static Future<void> saveProjects(List<StoryProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final list = projects.map((p) => p.toMap()).toList();
    await prefs.setString(_kProjects, jsonEncode(list));
  }

  /// ✅ 프로젝트 1개 업서트(없으면 추가, 있으면 갱신)
  static Future<List<StoryProject>> upsertProject(StoryProject project) async {
    final projects = await loadProjects();
    final idx = projects.indexWhere((p) => p.id == project.id);

    if (idx >= 0) {
      projects[idx] = project;
    } else {
      projects.insert(0, project);
    }

    await saveProjects(projects);
    return projects;
  }

  /// ✅ 프로젝트 1개 삭제
  static Future<List<StoryProject>> deleteProject(String projectId) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p.id == projectId);
    await saveProjects(projects);
    return projects;
  }

  /// 전체 초기화(디버그용)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProjects);
  }
}

/* ====== JSON 변환 (models.dart 수정 없이 extension으로 처리) ====== */

extension StoryProjectJson on StoryProject {
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'logline': logline,
        'baseScenario': baseScenario,
        'episodes': episodes.map((e) => e.toMap()).toList(),
      };
}

extension EpisodeJson on Episode {
  Map<String, dynamic> toMap() => {
        'number': number,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'userRequest': userRequest,
        'scenarioInput': scenarioInput,
        'tone': tone.name,
      };
}

extension StoryProjectFromMap on Map<String, dynamic> {
  StoryProject toStoryProject() {
    final eps = <Episode>[];
    final rawEpisodes = this['episodes'];

    if (rawEpisodes is List) {
      for (final e in rawEpisodes) {
        if (e is Map<String, dynamic>) {
          eps.add(e.toEpisode());
        }
      }
    }

    return StoryProject(
      id: (this['id'] ?? '').toString(),
      title: (this['title'] ?? '').toString(),
      logline: (this['logline'] ?? '').toString(),
      baseScenario: (this['baseScenario'] ?? '').toString(),
      protagonistName: (this['protagonistName'] ?? '').toString(),
      episodes: eps,
    );
  }

  Episode toEpisode() {
    final toneStr = (this['tone'] ?? 'normal').toString();
    final tone = Tone.values.firstWhere(
      (t) => t.name == toneStr,
      orElse: () => Tone.normal,
    );

    return Episode(
      number: this['number'] is int
          ? this['number']
          : int.tryParse('${this['number']}') ?? 1,
      title: (this['title'] ?? '').toString(),
      content: (this['content'] ?? '').toString(),
      createdAt: DateTime.tryParse(
            (this['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      userRequest: (this['userRequest'] ?? '').toString(),
      scenarioInput: (this['scenarioInput'] ?? '').toString(),
      tone: tone,
    );
  }
}

