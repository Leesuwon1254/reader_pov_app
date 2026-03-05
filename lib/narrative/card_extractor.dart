import 'cards.dart';

class CardExtractor {
  static List<CardBase> extract({
    required String scenarioInput,
    required int nextEpisodeNo,
  }) {
    final s = scenarioInput.trim();
    if (s.isEmpty) return [];

    final cards = <CardBase>[];

    // ✅ 핵심: 한 줄에 "장소: ... / 인물: ... / 떡밥: ..." 형태도 안전하게 파싱
    // - 각 필드 값은 "다음 필드 키워드"가 나오기 전까지만 먹는다.
    // - 줄바꿈(\n) 또는 슬래시(/)로 섹션이 나뉘어도 처리한다.
    final place = _extractFieldValue(s, fieldNames: const ['장소']);
    final chars = _extractFieldValue(s, fieldNames: const ['인물']);
    final thread = _extractFieldValue(s, fieldNames: const ['떡밥', '단서']);

    // 1) 장소 카드
    if (place != null && place.isNotEmpty) {
      final cleanPlace = _cleanupValue(place);
      if (cleanPlace.isNotEmpty) {
        cards.add(
          PlaceCard(
            id: 'place_${cleanPlace.hashCode}',
            title: cleanPlace,
            features: const ['분위기 중심', '감각 디테일을 자연스럽게'],
            tags: const ['place', 'detail'],
            priority: 0.55,
            lastTouchedEpisode: nextEpisodeNo,
          ),
        );
      }
    }

    // 2) 인물 카드 (최대 4명)
    if (chars != null && chars.isNotEmpty) {
      final cleanChars = _cleanupValue(chars);

      // ✅ 구분자: 콤마(,) / 슬래시(/) / 줄바꿈
      // 단, "떡밥:" "장소:" 같은 키워드가 섞이면 필터링해서 제거
      final parts = cleanChars
          .split(RegExp(r'[,/\n]\s*'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .where((e) => !_containsAnyFieldKeyword(e)); // ✅ 키워드 오염 방지

      for (final p in parts.take(4)) {
        final name = p.split('(').first.trim();
        if (name.isEmpty) continue;

        final trait = (p.contains('(') && p.contains(')'))
            ? p.substring(p.indexOf('(') + 1, p.indexOf(')')).trim()
            : '미상';

        cards.add(
          CharacterCard(
            id: 'char_${name.hashCode}',
            name: name,
            traits: trait == '미상' ? const ['일관된 말투'] : [trait],
            relations: const ['너와의 관계는 설명 없이 장면으로만 드러낸다'],
            tags: const ['cast'],
            priority: 0.6,
            lastTouchedEpisode: nextEpisodeNo,
          ),
        );
      }
    }

    // 3) 떡밥/단서 카드
    if (thread != null && thread.isNotEmpty) {
      final cleanThread = _cleanupValue(thread);
      if (cleanThread.isNotEmpty && !_containsAnyFieldKeyword(cleanThread)) {
        cards.add(
          ThreadCard(
            id: 'thread_${cleanThread.hashCode}',
            surface: cleanThread,
            status: 'unresolved',
            tags: const ['twist'],
            priority: 0.65,
            lastTouchedEpisode: nextEpisodeNo,
          ),
        );
      }
    }

    return cards;
  }

  // ----------------------------------------------------------------------
  // ✅ 새 파서: "필드명:" 이후 값을 "다음 필드명:" 전까지만 가져온다.
  // 지원 예:
  // - "장소: 지하주차장"
  // - "장소: 지하주차장 / 인물: 민준, 서연 / 떡밥: 열쇠 꾸러미"
  // - 여러 줄 섞여도 OK
  // ----------------------------------------------------------------------
  static String? _extractFieldValue(
    String text, {
    required List<String> fieldNames,
  }) {
    // 후보 키: "장소:" "장소 :" 등
    final keys = <String>[];
    for (final f in fieldNames) {
      keys.add('$f:');
      keys.add('$f :');
    }

    int startIdx = -1;
    int keyLen = 0;

    for (final k in keys) {
      final idx = text.indexOf(k);
      if (idx >= 0) {
        // 가장 앞에 나온 키를 채택
        if (startIdx == -1 || idx < startIdx) {
          startIdx = idx;
          keyLen = k.length;
        }
      }
    }

    if (startIdx < 0) return null;

    // 값 시작
    final after = text.substring(startIdx + keyLen);

    // 값 끝: 다음 필드 키워드가 나타나는 지점(또는 줄 끝)
    final endIdxInAfter = _findNextFieldKeywordIndex(after);
    final chunk = (endIdxInAfter >= 0) ? after.substring(0, endIdxInAfter) : after;

    // 1차: 첫 줄
    final firstLine = chunk.split('\n').first.trim();

    // 2차: 슬래시로 이어졌으면 앞부분만
    // (예: "지하주차장 / 인물: ..." -> "지하주차장")
    final beforeSlash = firstLine.split('/').first.trim();

    return beforeSlash;
  }

  // 다음 필드 키워드가 시작되는 가장 빠른 위치를 찾는다
  static int _findNextFieldKeywordIndex(String s) {
    // 다음 키워드 후보들
    const nextKeys = [
      '장소:',
      '장소 :',
      '인물:',
      '인물 :',
      '떡밥:',
      '떡밥 :',
      '단서:',
      '단서 :',
    ];

    int found = -1;
    for (final k in nextKeys) {
      final idx = s.indexOf(k);
      if (idx >= 0) {
        if (found == -1 || idx < found) found = idx;
      }
    }
    return found;
  }

  static String _cleanupValue(String v) {
    var x = v.trim();

    // 끝에 붙은 불필요한 구두점/기호 정리
    x = x.replaceAll(RegExp(r'^[\-\•\*]+\s*'), '').trim();
    x = x.replaceAll(RegExp(r'\s+'), ' ').trim();

    // "인물:" 같은 접두어가 값에 섞여 들어오면 제거(방어)
    x = x
        .replaceAll('장소:', '')
        .replaceAll('장소 :', '')
        .replaceAll('인물:', '')
        .replaceAll('인물 :', '')
        .replaceAll('떡밥:', '')
        .replaceAll('떡밥 :', '')
        .replaceAll('단서:', '')
        .replaceAll('단서 :', '')
        .trim();

    return x;
  }

  static bool _containsAnyFieldKeyword(String s) {
    // ✅ "떡밥:" 같은 키워드가 인물/장소로 섞여 들어가는 오염 방지
    return s.contains('장소:') ||
        s.contains('장소 :') ||
        s.contains('인물:') ||
        s.contains('인물 :') ||
        s.contains('떡밥:') ||
        s.contains('떡밥 :') ||
        s.contains('단서:') ||
        s.contains('단서 :');
  }
}

