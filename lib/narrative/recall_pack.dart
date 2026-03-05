// lib/narrative/recall_pack.dart

/// RecallPack = "다음 화에서도 이어지게 만드는 기억 조각" 컨테이너
///
/// 목표:
/// - 새 채팅(새 API 호출)에서도 연속성이 살아있게, "짧고 재사용 가능한 조각"만 남긴다.
/// - 메타 오염(#SUMMARY/#NEXT_HOOK/OUTPUT FORMAT/작성하라 등)은 강제 제거한다.
/// - 태그(인물/장소/떡밥/미완/감각/대사/조각)를 통일한다.
/// - 중복 제거, 길이 제한, 우선순위 정렬을 제공한다.
/// - 저장/로드(toJson/fromJson) 지원(SharedPreferences/파일 저장용).
class RecallPack {
  /// 프롬프트에 붙일 "짧은 조각들"
  final List<String> items;

  const RecallPack(this.items);

  /// 빈 팩
  factory RecallPack.empty() => const RecallPack([]);

  /// JSON 저장용
  Map<String, dynamic> toJson() => {'items': items};

  /// JSON 로드용
  factory RecallPack.fromJson(Map<String, dynamic>? json) {
    if (json == null) return RecallPack.empty();
    final raw = json['items'];
    if (raw is List) {
      return RecallPack(raw.map((e) => e.toString()).toList());
    }
    return RecallPack.empty();
  }

  /// 현재 items를 "정리된 상태"로 반환
  /// - 메타 제거
  /// - 태그 보정
  /// - 길이 제한
  /// - 중복 제거
  RecallPack sanitized({
    int maxItemLen = 220,
    bool forceExplainBanSuffix = true,
  }) {
    final cleaned = sanitizeItems(
      items,
      maxItemLen: maxItemLen,
      forceExplainBanSuffix: forceExplainBanSuffix,
    );
    return RecallPack(cleaned);
  }

  /// 기존 팩 + 새 조각을 합쳐서 반환(정리 포함)
  RecallPack merge(
    RecallPack other, {
    int maxItems = 14,
    int maxItemLen = 220,
  }) {
    final merged = [...items, ...other.items];
    final cleaned = sanitizeItems(merged, maxItemLen: maxItemLen);
    final pruned = pickForNextEpisode(cleaned, maxItems: maxItems);
    return RecallPack(pruned);
  }

  /// 외부에서 조각 추가(문장/카드) → 합친 뒤 정리해서 반환
  RecallPack addItems(
    Iterable<String> newItems, {
    int maxItems = 14,
    int maxItemLen = 220,
  }) {
    final merged = [...items, ...newItems];
    final cleaned = sanitizeItems(merged, maxItemLen: maxItemLen);
    final pruned = pickForNextEpisode(cleaned, maxItems: maxItems);
    return RecallPack(pruned);
  }

  // ---------------------------------------------------------------------------
  // Static utilities (핵심 로직)
  // ---------------------------------------------------------------------------

  /// 메타/지시문 오염 제거 + 태그 보정 + 길이 제한 + 중복 제거
  static List<String> sanitizeItems(
    List<String> input, {
    int maxItemLen = 220,
    bool forceExplainBanSuffix = true,
  }) {
    final out = <String>[];

    for (final raw in input) {
      var s = raw.trim();
      if (s.isEmpty) continue;

      // 1) 메타/포맷/지시문 제거
      if (_isMetaOrDirective(s)) continue;

      // 2) 길이 제한
      if (s.length > maxItemLen) {
        s = s.substring(0, maxItemLen).trim();
      }

      // 3) 태그 보정: (인물)/(장소)/(떡밥)/(미완)/(감각)/(대사)/(조각)
      s = normalizeTag(s);

      // 4) (설명 금지) 접미 통일
      if (forceExplainBanSuffix) {
        if (!s.contains('설명 금지')) {
          s = '$s (설명 금지)';
        }
      }

      out.add(s);
    }

    // 5) 중복 제거(보이는 문자열 기준)
    final uniq = <String>{};
    final result = <String>[];
    for (final s in out) {
      if (uniq.add(s)) result.add(s);
    }

    return result;
  }

  /// 다음 화에 붙일 조각을 선별(우선순위 정렬 + maxItems 제한)
  ///
  /// 우선순위 기본:
  /// - (미완)/(떡밥) > (인물)/(장소) > (감각)/(대사) > (조각)
  static List<String> pickForNextEpisode(
    List<String> cleaned, {
    int maxItems = 14,
  }) {
    final sorted = [...cleaned]..sort((a, b) {
        final pa = _priority(a);
        final pb = _priority(b);
        if (pa != pb) return pa.compareTo(pb);
        // 같은 우선순위면 짧은 게 먼저(프롬프트 효율)
        return a.length.compareTo(b.length);
      });

    if (sorted.length <= maxItems) return sorted;
    return sorted.take(maxItems).toList();
  }

  /// 태그가 없으면 (조각) 붙이고, 태그 형식을 통일한다.
  static String normalizeTag(String s) {
    final t = s.trim();

    // 이미 정상 태그면 그대로
    if (_hasKnownTag(t)) return t;

    // 흔한 패턴을 태그로 승격 (너의 UI 입력: "장소:", "인물:", "떡밥:" 등)
    final lowered = t.toLowerCase();

    // 한국어/영어 키워드 기반 간단 판별
    if (t.startsWith('장소:') || t.startsWith('장소 -') || lowered.startsWith('place:')) {
      return '(장소) ${_stripPrefix(t)}';
    }
    if (t.startsWith('인물:') || t.startsWith('인물 -') || lowered.startsWith('character:')) {
      return '(인물) ${_stripPrefix(t)}';
    }
    if (t.startsWith('떡밥:') || t.startsWith('떡밥 -') || lowered.startsWith('hook:')) {
      return '(떡밥) ${_stripPrefix(t)}';
    }
    if (t.startsWith('감각:') || t.startsWith('감각 -') || lowered.startsWith('sensory:')) {
      return '(감각) ${_stripPrefix(t)}';
    }
    if (t.startsWith('대사:') || t.startsWith('대사 -') || lowered.startsWith('line:')) {
      return '(대사) ${_stripPrefix(t)}';
    }
    if (t.startsWith('미완:') || t.startsWith('미완 -') || lowered.startsWith('unresolved:')) {
      return '(미완) ${_stripPrefix(t)}';
    }

    // 기본 fallback
    return '(조각) $t';
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static bool _hasKnownTag(String s) {
    return s.startsWith('(인물)') ||
        s.startsWith('(장소)') ||
        s.startsWith('(떡밥)') ||
        s.startsWith('(미완)') ||
        s.startsWith('(감각)') ||
        s.startsWith('(대사)') ||
        s.startsWith('(조각)');
  }

  static String _stripPrefix(String s) {
    // "장소: xxx" / "인물 - xxx" 같은 것을 xxx로
    final idx1 = s.indexOf(':');
    final idx2 = s.indexOf('-');

    int cut = -1;
    if (idx1 >= 0) cut = idx1;
    if (idx2 >= 0) cut = (cut < 0) ? idx2 : (idx2 < cut ? idx2 : cut);

    if (cut >= 0 && cut + 1 < s.length) {
      return s.substring(cut + 1).trim();
    }
    return s.trim();
  }

  static bool _isMetaOrDirective(String s) {
    final u = s.toUpperCase();

    // ✅ 강제 차단: 포맷/메타/지시문/요약/훅
    const banned = <String>[
      'OUTPUT FORMAT',
      'STORY SO FAR',
      'PROJECT INFO',
      'CHARACTER BIBLE',
      '#TITLE',
      '#SUMMARY',
      '#CHARACTERS',
      '#EPISODE',
      '#NEXT_HOOK',
      'NEXT_HOOK',
      'SUMMARY',
      '요약',
      '훅',
      '다음 화를 보고 싶게',
      '반드시 준수',
      '작성하라',
      '이제',
      '분량',
      'HARD RULES',
      'POV / STYLE',
      'SCENE CONSTRAINTS',
      'READER CUSTOM',
      'PROJECT SEED',
    ];

    for (final b in banned) {
      if (u.contains(b.toUpperCase()) || s.contains(b)) return true;
    }

    // "규칙입니다/금지합니다/해야 한다" 같은 강한 지시문은 recall에 부적합
    final directiveHints = [
      '금지',
      '해야',
      '하라',
      '말 것',
      '직접',
      '반드시',
      '준수',
      '형식',
      '포맷',
    ];
    // 단, "(미완) 확인하지 않음" 같은 건 허용해야 하니까
    // 태그가 붙은 건 통과시키고, 태그 없는 지시문만 컷
    if (!_hasKnownTag(s)) {
      for (final h in directiveHints) {
        if (s.contains(h)) return true;
      }
    }

    return false;
  }

  static int _priority(String s) {
    // 숫자가 작을수록 우선
    if (s.startsWith('(미완)')) return 0;
    if (s.startsWith('(떡밥)')) return 1;
    if (s.startsWith('(인물)')) return 2;
    if (s.startsWith('(장소)')) return 3;
    if (s.startsWith('(감각)')) return 4;
    if (s.startsWith('(대사)')) return 5;
    return 6; // (조각) 기타
  }
}
