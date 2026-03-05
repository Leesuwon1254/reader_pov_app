class ReaderIntent {
  final int intensity;      // -2 ~ +2
  final int detail;         // -2 ~ +2
  final bool expandCast;    // 주변인물 추가
  final bool requestTwist;  // 반전 요청
  final bool allowDeath;    // (정책범위 내) 사망 허용
  final bool allowRomance;  // 로맨스 허용

  const ReaderIntent({
    this.intensity = 0,
    this.detail = 0,
    this.expandCast = false,
    this.requestTwist = false,
    this.allowDeath = false,
    this.allowRomance = true,
  });

  /// 파일럿: 독자 입력 텍스트(자연어) -> 규칙 기반 파싱(간단 매핑)
  factory ReaderIntent.fromUserText(String text) {
    final t = text.trim();

    int intensity = 0;
    int detail = 0;
    bool expandCast = false;
    bool requestTwist = false;
    bool allowDeath = false;
    bool allowRomance = true;

    if (t.contains('자극') || t.contains('극단') || t.contains('세게')) intensity += 2;
    if (t.contains('디테일') || t.contains('구체') || t.contains('묘사')) detail += 2;
    if (t.contains('인물') && (t.contains('추가') || t.contains('더'))) expandCast = true;
    if (t.contains('반전') || t.contains('배신') || t.contains('충격')) requestTwist = true;
    if (t.contains('죽') || t.contains('사망')) allowDeath = true;
    if (t.contains('로맨스') && (t.contains('빼') || t.contains('없') || t.contains('금지'))) allowRomance = false;

    // clamp
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
