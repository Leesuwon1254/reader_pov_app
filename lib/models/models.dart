import 'package:flutter/material.dart';

enum StoryGenre {
  drama,
  romance,
  thriller,
  fantasy,
  sliceOfLife,
}

extension StoryGenreX on StoryGenre {
  String get label {
    switch (this) {
      case StoryGenre.drama:
        return '드라마';
      case StoryGenre.romance:
        return '로맨스';
      case StoryGenre.thriller:
        return '스릴러';
      case StoryGenre.fantasy:
        return '판타지';
      case StoryGenre.sliceOfLife:
        return '일상';
    }
  }

  String get hint {
    switch (this) {
      case StoryGenre.drama:
        return '현실 갈등, 관계, 권력, 성장';
      case StoryGenre.romance:
        return '설렘/관계 변화 중심';
      case StoryGenre.thriller:
        return '미스터리/긴장/추적';
      case StoryGenre.fantasy:
        return '세계관/능력/규칙';
      case StoryGenre.sliceOfLife:
        return '잔잔한 일상과 감정';
    }
  }

  IconData get icon {
    switch (this) {
      case StoryGenre.drama:
        return Icons.theater_comedy;
      case StoryGenre.romance:
        return Icons.favorite;
      case StoryGenre.thriller:
        return Icons.visibility;
      case StoryGenre.fantasy:
        return Icons.auto_fix_high;
      case StoryGenre.sliceOfLife:
        return Icons.coffee;
    }
  }

  String get apiKey {
    switch (this) {
      case StoryGenre.drama:
        return 'drama';
      case StoryGenre.romance:
        return 'romance';
      case StoryGenre.thriller:
        return 'thriller';
      case StoryGenre.fantasy:
        return 'fantasy';
      case StoryGenre.sliceOfLife:
        return 'slice';
    }
  }

  static StoryGenre fromApiKey(String key) {
    switch (key) {
      case 'drama':
        return StoryGenre.drama;
      case 'romance':
        return StoryGenre.romance;
      case 'thriller':
        return StoryGenre.thriller;
      case 'fantasy':
        return StoryGenre.fantasy;
      case 'slice':
        return StoryGenre.sliceOfLife;
      default:
        return StoryGenre.drama;
    }
  }
}

enum Tone { normal, detailed, spicy, expand }

extension ToneX on Tone {
  String get label {
    switch (this) {
      case Tone.normal:
        return '기본(자동 생성)';
      case Tone.detailed:
        return '더 구체적으로';
      case Tone.spicy:
        return '더 자극적으로';
      case Tone.expand:
        return '주변 인물 추가/확장';
    }
  }

  String get hint {
    switch (this) {
      case Tone.normal:
        return 'AI가 기본 흐름으로 자연스럽게 다음화를 생성';
      case Tone.detailed:
        return '상황/묘사/대화/감정을 더 촘촘하게';
      case Tone.spicy:
        return '갈등/위기/긴장감을 더 강하게';
      case Tone.expand:
        return '조연/주변 인물을 추가하고 사건을 확장';
    }
  }

  IconData get icon {
    switch (this) {
      case Tone.normal:
        return Icons.auto_awesome;
      case Tone.detailed:
        return Icons.search;
      case Tone.spicy:
        return Icons.local_fire_department;
      case Tone.expand:
        return Icons.group_add;
    }
  }

  String get apiKey {
    switch (this) {
      case Tone.normal:
        return 'normal';
      case Tone.detailed:
        return 'detail';
      case Tone.spicy:
        return 'spicy';
      case Tone.expand:
        return 'expand';
    }
  }

  static Tone fromApiKey(String key) {
    switch (key) {
      case 'normal':
        return Tone.normal;
      case 'detail':
        return Tone.detailed;
      case 'spicy':
        return Tone.spicy;
      case 'expand':
        return Tone.expand;
      default:
        return Tone.normal;
    }
  }
}

class StoryTemplate {
  final String id;
  final StoryGenre genre;
  final String title;
  final String logline;
  final String skeleton;

  const StoryTemplate({
    required this.id,
    required this.genre,
    required this.title,
    required this.logline,
    required this.skeleton,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'genre': genre.apiKey,
        'title': title,
        'logline': logline,
        'skeleton': skeleton,
      };

  factory StoryTemplate.fromJson(Map<String, dynamic> json) {
    return StoryTemplate(
      id: (json['id'] ?? '').toString(),
      genre: StoryGenreX.fromApiKey((json['genre'] ?? 'drama').toString()),
      title: (json['title'] ?? '').toString(),
      logline: (json['logline'] ?? '').toString(),
      skeleton: (json['skeleton'] ?? '').toString(),
    );
  }
}

class Episode {
  final int number;
  final String title;
  final String content;

  /// 프롬프트(있으면 저장)
  final String? prompt;

  final DateTime createdAt;
  final String userRequest;
  final String scenarioInput;
  final Tone tone;

  Episode({
    required this.number,
    required this.title,
    required this.content,
    this.prompt,
    required this.createdAt,
    required this.userRequest,
    required this.scenarioInput,
    required this.tone,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'number': number,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'userRequest': userRequest,
      'scenarioInput': scenarioInput,
      'tone': tone.apiKey,
    };

    if (prompt != null && prompt!.trim().isNotEmpty) {
      m['prompt'] = prompt;
    }
    return m;
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    final number = (json['number'] ?? 1) is int
        ? json['number']
        : int.tryParse('${json['number']}') ?? 1;

    final title = (json['title'] ?? '').toString();
    final content = (json['content'] ?? '').toString();
    final prompt = (json['prompt'] ?? '').toString();

    // 하위호환: 예전 데이터가 content에 프롬프트만 저장했을 수 있음
    final looksLikePrompt = content.contains('[HARD RULES]') ||
        content.contains('[OUTPUT]') ||
        content.contains('[PROTAGONIST') ||
        content.contains('Reader POV') ||
        content.contains('무인칭 몰입 POV');

    final finalPrompt = prompt.trim().isNotEmpty
        ? prompt
        : (looksLikePrompt ? content : '');

    return Episode(
      number: number,
      title: title,
      content: content,
      prompt: finalPrompt.isEmpty ? null : finalPrompt,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      userRequest: (json['userRequest'] ?? '기본 생성').toString(),
      scenarioInput: (json['scenarioInput'] ?? '기본 뼈대 기반으로 진행').toString(),
      tone: ToneX.fromApiKey((json['tone'] ?? 'normal').toString()),
    );
  }
}

class StoryProject {
  final String id;
  String title;
  String logline;
  String baseScenario;

  /// 주인공 이름(필수)
  String protagonistName;

  final List<Episode> episodes;

  StoryProject({
    required this.id,
    required this.title,
    required this.logline,
    required this.baseScenario,
    required this.protagonistName,
    required this.episodes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'logline': logline,
        'baseScenario': baseScenario,
        'protagonistName': protagonistName,
        'episodes': episodes.map((e) => e.toJson()).toList(),
      };

  static String _extractProtagonistNameFromText(String text) {
    final t = text.trim();
    if (t.isEmpty) return '';

    // 1) PromptBuilder 최신 블록
    final r1 = RegExp(r'주인공 이름\(필수 고정\)\s*:\s*([^\n\r]+)');
    final m1 = r1.firstMatch(t);
    if (m1 != null) {
      final name = (m1.group(1) ?? '').trim();
      if (name.isNotEmpty) return name;
    }

    // 2) 프로젝트 시드에 들어가는 경우
    final r2 = RegExp(r'주인공 이름\(필수\)\s*:\s*([^\n\r]+)');
    final m2 = r2.firstMatch(t);
    if (m2 != null) {
      final name = (m2.group(1) ?? '').trim();
      if (name.isNotEmpty) return name;
    }

    return '';
  }

  factory StoryProject.fromJson(Map<String, dynamic> json) {
    final epsRaw = json['episodes'];
    final List<Episode> eps = [];

    if (epsRaw is List) {
      for (final item in epsRaw) {
        if (item is Map<String, dynamic>) {
          eps.add(Episode.fromJson(item));
        } else if (item is Map) {
          eps.add(Episode.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // number 기준 중복 제거 후 정렬 (저장 데이터에 중복이 있어도 안전하게 로드)
    final dedupedEps = <int, Episode>{};
    for (final e in eps) {
      dedupedEps[e.number] = e;
    }
    eps
      ..clear()
      ..addAll(dedupedEps.values.toList()..sort((a, b) => a.number.compareTo(b.number)));

    String protagonist = (json['protagonistName'] ?? '').toString().trim();

    // ✅ 하위호환 강화: protagonistName이 비어있으면,
    // 에피소드(prompt/content)에서 자동 추출해서 채움
    if (protagonist.isEmpty && eps.isNotEmpty) {
      for (final e in eps) {
        final fromPrompt = _extractProtagonistNameFromText(e.prompt ?? '');
        if (fromPrompt.isNotEmpty) {
          protagonist = fromPrompt;
          break;
        }
        final fromContent = _extractProtagonistNameFromText(e.content);
        if (fromContent.isNotEmpty) {
          protagonist = fromContent;
          break;
        }
      }
    }

    return StoryProject(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      logline: (json['logline'] ?? '').toString(),
      baseScenario: (json['baseScenario'] ?? '').toString(),
      protagonistName: protagonist,
      episodes: eps,
    );
  }
}






