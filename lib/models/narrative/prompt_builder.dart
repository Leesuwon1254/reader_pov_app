import '../../models/narrative/cards.dart';
import '../../models/narrative/state.dart';
import '../../models/narrative/reader_intent.dart';

class PromptBuilder {
  static String build({
    required String bible,             // 고정 규칙(짧게)
    required NarrativeState state,
    required ReaderIntent intent,
    required List<CardBase> recallPack,
    int targetChars = 5000,
  }) {
    final buf = StringBuffer();

    buf.writeln(bible.trim());
    buf.writeln();
    buf.writeln('[현재 상태]');
    buf.writeln('- 회차: ${state.episodeNo + 1}화');
    buf.writeln('- 시간: ${state.timeHint}');
    buf.writeln('- 장소: ${state.placeId} (이미 익숙한 장소로 전제, 설명 금지)');
    buf.writeln('- 관계 온도: ${state.relationshipTemp}');
    buf.writeln('- 미해결: ${state.unresolved.join(", ")}');
    buf.writeln('- 감각 단서: ${state.sensory.join(", ")}');
    buf.writeln('- 이번 화 목표: ${state.goal}');
    buf.writeln();

    buf.writeln('[독자 커스텀(의도)]');
    buf.writeln('- 자극 강도: ${intent.intensity}');
    buf.writeln('- 디테일: ${intent.detail}');
    buf.writeln('- 주변 인물 확장: ${intent.expandCast}');
    buf.writeln('- 반전 요청: ${intent.requestTwist}');
    buf.writeln('- 로맨스 허용: ${intent.allowRomance}');
    buf.writeln();

    buf.writeln('[Recall Pack: 이번 화에 필요한 카드만]');
    for (final c in recallPack) {
      if (c is CharacterCard) {
        buf.writeln('- (인물) ${c.name}: ${c.traits.join(", ")} / 이미 알고 있는 인물처럼 등장(소개 금지)');
      } else if (c is PlaceCard) {
        buf.writeln('- (장소) ${c.title}: ${c.features.join(", ")} / 설명 금지, 분위기만');
      } else if (c is ThreadCard) {
        buf.writeln('- (떡밥) ${c.surface}: 상태=${c.status} / 직접 회상 금지, 장면으로만 암시');
      } else if (c is TraceCard) {
        buf.writeln('- (흔적) ${c.sensoryHint}: 직접 설명 금지, 감각으로만 드러내기');
      }
    }
    buf.writeln();

    buf.writeln('[출력 규칙]');
    buf.writeln('- 2인칭 독자시점 유지(“너는” 반복 과다 금지).');
    buf.writeln('- 설명/요약/회상 금지. 장면(행동·대화·감각) 중심.');
    buf.writeln('- 기존 설정/인물/사건을 부정하지 말 것.');
    buf.writeln('- 분량: 약 ${targetChars}자 내외.');
    buf.writeln('- 과도한 폭력/노골적 성행위/혐오 표현 금지.');
    buf.writeln();
    buf.writeln('이제 다음 화(바로 이어지는 장면)만 작성해라.');

    return buf.toString();
  }
}
