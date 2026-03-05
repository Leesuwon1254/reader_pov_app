import 'cards.dart';
import 'reader_intent.dart';

class RecallSelector {
  static List<CardBase> select({
    required int nextEpisodeNo,
    required ReaderIntent intent,
    required List<CardBase> allCards,
    int maxCards = 8,
  }) {
    final filtered = allCards.where((c) {
      if (!intent.allowRomance && c.tags.contains('romance')) return false;
      if (!intent.allowDeath && c.tags.contains('death')) return false;
      return true;
    }).toList();

    double score(CardBase c) {
      double s = 0;

      if (intent.requestTwist && c.tags.contains('twist')) s += 1.0;
      if (intent.expandCast && c.tags.contains('cast')) s += 0.7;
      if (intent.intensity >= 2 && c.tags.contains('intense')) s += 0.6;
      if (intent.detail >= 2 && c.tags.contains('detail')) s += 0.4;

      if (c is ThreadCard && c.status == 'unresolved') s += 0.8;

      final gap = (nextEpisodeNo - c.lastTouchedEpisode).clamp(0, 999);
      if (gap >= 10) s += 0.6;
      else if (gap >= 4) s += 0.3;
      else s -= 0.2;

      s += c.priority;

      return s;
    }

    filtered.sort((a, b) => score(b).compareTo(score(a)));

    final result = <CardBase>[];

    void pick(CardType type, int n) {
      for (final c in filtered.where((x) => x.type == type)) {
        if (result.length >= maxCards) break;
        if (n <= 0) break;
        if (result.contains(c)) continue;
        result.add(c);
        n--;
      }
    }

    pick(CardType.character, intent.expandCast ? 3 : 2);
    pick(CardType.thread, intent.requestTwist ? 3 : 2);
    pick(CardType.place, 1);

    for (final c in filtered) {
      if (result.length >= maxCards) break;
      if (!result.contains(c)) result.add(c);
    }

    return result.take(maxCards).toList();
  }
}
