// lib/narrative/auto_recall_builder.dart

import '../models/models.dart';
import 'reader_intent.dart';
import 'recall_pack.dart';

import 'narrative_db.dart';
import 'cards.dart';
import 'recall_selector.dart';

class AutoRecallBuilder {
  /// maxCards: 카드 조각 최대 개수(인물/장소/떡밥)
  /// maxFragments: 최근 에피소드에서 뽑는 “미완/여운/대사 조각” 개수
  ///
  /// extraCards:
  /// - "이번 생성 입력(가이드)"에서 뽑은 카드들
  /// - DB에 저장되기 전이라도, 이번 프롬프트에는 즉시 반영하기 위한 용도
  static Future<RecallPack> build({
    required String projectId,
    required StoryProject project,
    required int nextNumber,
    required ReaderIntent intent,
    int maxCards = 8,
    int maxFragments = 2,
    List<CardBase> extraCards = const [],
  }) async {
    // 1) 카드 로드 + (이번 입력 카드) 합치기
    final dbCards = await NarrativeDB.loadCards(projectId);
    final allCards = <CardBase>[...dbCards, ...extraCards];

    final selectedCards = RecallSelector.select(
      nextEpisodeNo: nextNumber,
      intent: intent,
      allCards: allCards,
      maxCards: maxCards,
    );

    final items = <String>[];

    // 2) 카드 → “짧은 카드 조각”으로 변환 (지시문 최소화)
    for (final c in selectedCards) {
      items.add(_cardToFragment(c));
    }

    // 3) 최근 에피소드 본문에서 “미완/여운/대사 조각” 추출
    final recent = project.episodes.toList()
      ..sort((a, b) => b.number.compareTo(a.number));

    final take = recent.take(2).toList(); // 최근 2화만
    final extracted = <String>[];

    for (final e in take) {
      final body = e.content.trim();
      extracted.addAll(_extractPressureFragmentsFromText(body));
      if (extracted.length >= maxFragments) break;
    }

    // 4) extracted 중복 제거 + 제한
    final uniq = <String>{};
    for (final x in extracted) {
      final t = _normalizeFragment(x);
      if (t.isEmpty) continue;
      uniq.add(t);
      if (uniq.length >= maxFragments) break;
    }

    items.addAll(uniq);

    // 5) 아무것도 없으면 최소 Fallback
    if (items.isEmpty) {
      items.add('(미완) 확인하지 않은 것이 남아 있다');
      items.add('(감각) 차가운 공기, 미세한 소음');
    }

    // 6) 최종: RecallPack 규칙으로 정리 + 개수 컷
    final cleaned = RecallPack.sanitizeItems(
      items,
      maxItemLen: 220,
      forceExplainBanSuffix: true,
    );

    final maxItems = (maxCards + maxFragments).clamp(4, 18);
    final pruned = RecallPack.pickForNextEpisode(cleaned, maxItems: maxItems);

    return RecallPack(pruned);
  }

  /// 카드 → 조각(짧은 카드형)으로 변환
  static String _cardToFragment(CardBase c) {
    if (c is CharacterCard) {
      final traits = c.traits.isEmpty ? '' : c.traits.take(2).join(', ');
      return traits.isEmpty ? '(인물) ${c.name}' : '(인물) ${c.name} — $traits';
    }

    if (c is PlaceCard) {
      final feat = c.features.isEmpty ? '' : c.features.take(2).join(', ');
      return feat.isEmpty ? '(장소) ${c.title}' : '(장소) ${c.title} — $feat';
    }

    if (c is ThreadCard) {
      final status = c.status.trim().isEmpty ? '미해결' : c.status.trim();
      return '(떡밥) ${c.surface} — $status';
    }

    return '(조각) ${c.id}';
  }

  /// 최근 텍스트에서 “압력/미완/여운/대사” 후보를 뽑는다.
  static List<String> _extractPressureFragmentsFromText(String text) {
    final t = text.trim();
    if (t.isEmpty) return [];

    final out = <String>[];

    // 마지막 900자만
    final slice = t.length <= 900 ? t : t.substring(t.length - 900);

    final lines = slice
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final line in lines.reversed) {
      if (out.length >= 3) break;
      if (_looksLikeMeta(line)) continue;

      final endsWithSuspense = line.endsWith('…') ||
          line.endsWith('...') ||
          line.endsWith('—') ||
          line.endsWith('?') ||
          line.endsWith('!');

      if (endsWithSuspense && line.length <= 140) {
        out.add('(미완) ${_trimQuotes(line)}');
        continue;
      }

      if (_looksLikeDialogue(line) && line.length <= 90) {
        out.add('(대사) ${_trimQuotes(line)}');
        continue;
      }
    }

    if (out.isEmpty && lines.isNotEmpty) {
      final last = lines.last;
      if (!_looksLikeMeta(last) && last.length <= 120) {
        out.add('(여운) ${_trimQuotes(last)}');
      }
    }

    return out;
  }

  static bool _looksLikeDialogue(String s) {
    final t = s.trim();
    return t.startsWith('“') ||
        t.startsWith('"') ||
        t.contains('“') ||
        t.contains('”') ||
        t.contains('"');
  }

  static bool _looksLikeMeta(String s) {
    // ✅ 프롬프트/규칙 문장이 “조각”으로 섞여 들어오는 것 차단
    if (s.contains('[OUTPUT]') ||
        s.contains('[HARD RULES]') ||
        s.contains('[POV') ||
        s.contains('[SCENE') ||
        s.contains('작성하라') ||
        s.contains('OUTPUT FORMAT') ||
        s.contains('#SUMMARY') ||
        s.contains('#NEXT_HOOK') ||
        s.contains('요약') ||
        s.contains('회상') ||
        // ✅ 우선순위 1: 규칙 키워드 차단 추가
        s.contains('2인칭') ||
        s.contains('유지하되') ||
        s.contains('반복 과다') ||
        s.contains('목표 분량') ||
        s.contains('장면은 결정 직전에서 끊어라') ||
        s.contains('직접 말하지 말 것')) {
      return true;
    }
    return false;
  }

  static String _trimQuotes(String s) {
    var x = s.trim();
    x = x.replaceAll('“', '').replaceAll('”', '');
    x = x.replaceAll('"', '');
    return x.trim();
  }

  static String _normalizeFragment(String s) {
    var x = s.trim();
    if (x.isEmpty) return '';

    if (x.length > 220) x = x.substring(0, 220).trim();

    final hasTag = x.startsWith('(인물)') ||
        x.startsWith('(장소)') ||
        x.startsWith('(떡밥)') ||
        x.startsWith('(미완)') ||
        x.startsWith('(대사)') ||
        x.startsWith('(여운)') ||
        x.startsWith('(감각)') ||
        x.startsWith('(조각)');

    if (!hasTag) x = '(조각) $x';

    return x;
  }
}








