class ReaderIntent {
  final int intensity; // -2 ~ +2
  final int detail; // -2 ~ +2
  final bool expandCast;
  final bool requestTwist;
  final bool allowDeath;
  final bool allowRomance;

  const ReaderIntent({
    this.intensity = 0,
    this.detail = 0,
    this.expandCast = false,
    this.requestTwist = false,
    this.allowDeath = false,
    this.allowRomance = true,
  });

  factory ReaderIntent.fromUserText(String text) {
    final t = text.trim();

    int intensity = 0;
    int detail = 0;
    bool expandCast = false;
    bool requestTwist = false;
    bool allowDeath = false;
    bool allowRomance = true;

    // 강도(자극/극단) 감지
    if (t.contains('자극') || t.contains('극단') || t.contains('세게')) intensity += 2;
    if (t.contains('긴장') || t.contains('위기') || t.contains('압박')) intensity += 1;
    if (t.contains('부드럽') || t.contains('잔잔') || t.contains('편안')) intensity -= 1;

    // 디테일 감지
    if (t.contains('구체') || t.contains('디테일') || t.contains('묘사')) detail += 2;
    if (t.contains('자세') || t.contains('세밀')) detail += 1;
    if (t.contains('간단') || t.contains('짧게') || t.contains('요약')) detail -= 1;

    // 인물 확장
    if (t.contains('인물') && (t.contains('추가') || t.contains('더') || t.contains('늘'))) {
      expandCast = true;
    }
    if (t.contains('조연') && (t.contains('추가') || t.contains('더') || t.contains('늘'))) {
      expandCast = true;
    }

    // 반전/트위스트
    if (t.contains('반전') || t.contains('배신') || t.contains('충격') || t.contains('트위스트')) {
      requestTwist = true;
    }

    // 사망/죽음 허용
    if (t.contains('죽') || t.contains('사망') || t.contains('처형')) {
      allowDeath = true;
    }

    // 로맨스 금지/제거
    if (t.contains('로맨스') && (t.contains('빼') || t.contains('없') || t.contains('금지'))) {
      allowRomance = false;
    }

    // 범위 제한
    intensity = intensity.clamp(-2, 2);
    detail = detail.clamp(-2, 2);

    return ReaderIntent(
      intensity: intensity,
      detail: detail,
      expandCast: expandCast,
      requestTwist: requestTwist,
      allowDeath: allowDeath,
      allowRomance: allowRomance,
    );
  }
}



