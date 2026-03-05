import '../../models/narrative/cards.dart';
import '../../models/narrative/state.dart';
import '../../models/narrative/reader_intent.dart';

class RecallSelector {
  /// 카드 5~10장만 선택
  static List<CardBase> select({
    required NarrativeState state,
    required ReaderIntent intent,
    required List<CardBase> allCards,
    int maxCards = 8,
  }) {
    // 1) 필터: 금지 태그 제외(예: romance)
    final filtered = allCards.where((c) {
      if (!intent.allowRomance && c.tags.contains('romance')) return false;
      if (!intent.allowDeath && c.tags.contains('death')) return false; // 필요 시
      return true;
    }).toList();

    // 2) 후보 우선순위: 현재 등장인물/현재 장소 관련은 가산
    double score(CardBase c) {
      double s = 0;

      // 관련성: 태그
      if (intent.requestTwist && c.tags.contains('twist')) s += 1.0;
      if (intent.expandCast && c.tags.contains('cast')) s += 0.6;
      if (intent.intensity >= 2 && c.tags.contains('intense')) s += 0.6;
      if (intent.detail >= 2 && c.tags.contains('detail')) s += 0.4;

      // 현재 맥락 관련성: 인물/장소
      if (c.type == CardType.character && state.castIds.contains(c.id)) s += 1.2;
      if (c.type == CardType.place && state.placeId == c.id) s += 1.0;

      // 미해결 떡밥 우대
      if (c is ThreadCard && c.status == "unresolved") s += 0.8;

      // 최근성: 너무 최근에 넣었던 건 약간 패널티(중복 방지)
      final gap = (state.episodeNo - c.lastTouchedEpisode).clamp(0, 999);
      s += (gap >= 8) ? 0.6 : (gap >= 3 ? 0.3 : -0.2);

      // 고유 중요도
      s += c.priority;

      return s;
    }

    filtered.sort((a, b) => score(b).compareTo(score(a)));

    // 3) 타입별로 균형 있게 뽑기
    final result = <CardBase>[];
    void pick(CardType type, int n) {
      for (final c in filtered.where((x) => x.type == type)) {
        if (result.length >= maxCards) break;
        if (result.contains(c)) continue;
        if (n <= 0) break;
        result.add(c);
        n--;
      }
    }

    pick(CardType.character, 3);
    pick(CardType.thread, intent.requestTwist ? 3 : 2);
    pick(CardType.place, 1);
    pick(CardType.trace, 2);

    // 부족하면 점수 순으로 채움
    for (final c in filtered) {
      if (result.length >= maxCards) break;
      if (!result.contains(c)) result.add(c);
    }

    return result.take(maxCards).toList();
  }
}
