// lib/narrative/prompt_builder.dart

import '../models/models.dart';
import 'narrative_state.dart';
import 'reader_intent.dart';
import 'recall_pack.dart';

class PromptBuilder {
  static const int _tailMaxChars = 1500;
  static const int _tailMaxLines = 20;

  static String build({
    required StoryProject project,
    required int nextNumber,
    required Tone tone,
    required String userRequest,
    required String scenarioInput,
    required NarrativeState state,
    required ReaderIntent intent,
    required RecallPack recall,
    int targetChars = 5000,

    // ✅ (NEW) 누적 메모리 30줄
    List<String> storyMemoryLines = const [],
  }) {
    return [
      '무인칭 몰입 POV 연재소설을 작성한다. 독자는 장면을 직접 겪는 위치에 놓이며, 한국어 소설 문체로 자연스럽게 전개한다.',
      _characterLockBlock(project: project),
      _rulesBlock(),
      _povStyleBlock(targetChars: targetChars),
      _protagonistBlock(project: project, targetChars: targetChars),

      // ✅ (NEW) 전체 연속성: 누적 요약 메모리
      _storyMemoryBlock(storyMemoryLines),

      // ✅ 직전 장면: Prev Tail
      _prevEpisodeTailBlock(project: project, nextNumber: nextNumber),

      _sceneConstraintsBlock(
        nextNumber: nextNumber,
        tone: tone,
        state: state,
        intent: intent,
      ),
      _userDirectivesBlock(
        userRequest: userRequest,
        scenarioInput: scenarioInput,
        tone: tone,
      ),
      _recallBlock(recall),
      _projectSeedBlock(project),
      _outputBlock(nextNumber: nextNumber, targetChars: targetChars),
    ].where((s) => s.trim().isNotEmpty).join('\n\n');
  }

  // ------------------------------------------------------------
  // CHARACTER LOCK (매 화 고정 지시문)
  // ------------------------------------------------------------
  static String _characterLockBlock({required StoryProject project}) {
    final protagonist = project.protagonistName.trim();
    final partner = project.partnerName.trim();
    final relation = project.partnerRelation.trim();
    final theme = project.coreTheme.trim();
    final genre = project.genreLock.trim();

    if (protagonist.isEmpty && partner.isEmpty && theme.isEmpty && genre.isEmpty) {
      return '';
    }

    final partnerDesc = partner.isNotEmpty
        ? (relation.isNotEmpty ? '$partner($relation)' : partner)
        : '(미지정)';
    final themeDesc = theme.isNotEmpty ? theme : '(미지정)';
    final genreDesc = genre.isNotEmpty ? genre : '(미지정)';

    return [
      '[CHARACTER & THEME LOCK — 절대 변경 금지]',
      '- 주인공: ${protagonist.isNotEmpty ? protagonist : "(미지정)"}',
      '- 상대: $partnerDesc',
      '- 테마: $themeDesc',
      '- 장르: $genreDesc',
      '- 위 설정(이름/관계/테마/장르)을 매 화 내내 절대 바꾸지 말 것.',
      '- 이름이 없으면 소년/소녀 또는 인물A/인물B로 고정하고, 화마다 일관되게 유지하라.',
    ].join('\n');
  }

  // ------------------------------------------------------------
  // ✅ (NEW) STORY MEMORY (최근 30줄)
  // ------------------------------------------------------------
  static String _storyMemoryBlock(List<String> lines) {
    if (lines.isEmpty) {
      return [
        '[STORY MEMORY: 최근 요약]',
        '- (아직 누적 메모리가 없다. 이번 화부터 매 회 10줄씩 누적된다.)',
      ].join('\n');
    }
    final cleaned = lines.where((e) => e.trim().isNotEmpty).toList();
    return [
      '[STORY MEMORY: 최근 30줄]',
      '- 아래 요약은 지금까지의 핵심 사건/관계/미해결/목표를 압축한 것이다.',
      '- 설명/요약을 다시 쓰지 말고, 이 메모리를 “사실”로 간주하여 다음 화에 반영하라.',
      ...cleaned.map((e) => '- $e'),
    ].join('\n');
  }

  // ------------------------------------------------------------
  // PREV EPISODE TAIL
  // ------------------------------------------------------------
  static String _prevEpisodeTailBlock({
    required StoryProject project,
    required int nextNumber,
  }) {
    if (nextNumber <= 1) return '';

    final prevNo = nextNumber - 1;
    final prev = project.episodes.where((e) => e.number == prevNo).toList();
    if (prev.isEmpty) {
      return [
        '[PREV EPISODE TAIL]',
        '- (직전 화 본문을 찾지 못했다. 그래도 연속성을 유지하되, 앞선 장면이 “바로 이어지는 느낌”으로 시작하라.)',
      ].join('\n');
    }

    final prevContent = prev.first.content.trim();
    if (prevContent.isEmpty) {
      return [
        '[PREV EPISODE TAIL]',
        '- (직전 화 본문이 비어 있다. 그래도 연속성을 유지하되, 앞선 장면이 “바로 이어지는 느낌”으로 시작하라.)',
      ].join('\n');
    }

    final lines = prevContent.split('\n');
    final tailLines = (lines.length <= _tailMaxLines)
        ? lines
        : lines.sublist(lines.length - _tailMaxLines);

    String tail = tailLines.join('\n').trim();
    if (tail.length > _tailMaxChars) {
      tail = tail.substring(tail.length - _tailMaxChars).trim();
    }

    return [
      '[PREV EPISODE TAIL]',
      '- 아래는 직전 화의 마지막 장면 일부이다. 설명/요약하지 말고, 이 지점에서 “바로 이어서” 다음 화를 시작하라.',
      '---',
      tail,
      '---',
    ].join('\n');
  }

  // ------------------------------------------------------------
  // HARD RULES
  // ------------------------------------------------------------
  static String _rulesBlock() {
    return [
      '- 서술은 독자 체험 중심(보고/듣고/느끼고/선택한 정보만).',
      '- 설명/요약/회상으로 때우지 말고 장면(행동·대화·감각)으로 전개.',
      '- 기존 설정/인물/사건과 모순 금지.',
      '- 과격한 묘사·성인 수위·혐오 표현은 배제하고 긴장감 중심으로 연출.',
      '- “지난 화 요약/회상”을 직접 문장으로 말하지 말 것.',
      '- “이야기의 시작/도입/설정 소개”라고 직접 말하지 말 것.',
      '- “느껴진다/느낌이다/기분이다/감정이 든다/생각이 든다”를 서술에 사용하지 말 것.',
      '  감정은 반드시 행동·신체반응·대화·장면으로만 표현할 것.',
      '  (금지 예시: “불안감이 느껴진다” → 허용 예시: “손이 멈췄다” / “숨을 참았다”)',
      '- “느낌이 든다/생각이 든다/의식 속에서/마음속에서 ~하다” 패턴도 금지.',
      '  주어 없이 감각/행동으로만 표현할 것.',
      '  (금지: “마음속에서 불안이 커진다” → 허용: “손가락이 멈췄다”)',
      '- 감정·심리 상태를 추상 동사로 표현하는 우회 패턴도 금지:',
      '  파고든다 / 다가온다 / 일렁인다 / 조인다 / 고조된다 / 압박한다 / 물결처럼 / 깊어진다 / 커져간다 / 선명해진다',
      '  반드시 구체적 신체 반응이나 행동으로만 표현할 것.',
      '  (금지: “불안이 파고든다” → 허용: “손톱이 손바닥을 눌렀다”)',
      '  (금지: “긴장감이 고조된다” → 허용: “말이 나오지 않았다”)',
      '- 직전 화와 동일하거나 유사한 문장으로 시작하지 말 것.',
      '  특히 날씨/공기/온도 묘사로 시작하는 패턴(예: “차가운 공기가”, “바람이 불어온다”)을 반복 금지.',
      '  매 화 첫 문장은 반드시 행동 또는 대화로 시작할 것.',
    ].join('\n');
  }

  static String _povStyleBlock({required int targetChars}) {
    return [
      '[POV / STYLE]',
      '- 독자가 장면 안에 직접 들어와 있는 것처럼 느껴지게 쓴다.',
      '- 서술문에서는 “너/너의/네/너에게/당신”을 사용하지 않는다.',
      '- 주어는 생략하거나, 상황·행동·감각 중심으로 자연스럽게 이어 간다.',
      '- 대사에서는 인물이 상대를 부르는 표현으로 “너” 사용을 상황에 맞게 허용하되, “당신”은 사용하지 않는다.',
      '- 주인공의 이름이 등장하는 문장에서는 독자를 호명하지 말고, 이름 또는 주어 생략만 사용한다.',
      '- 번역투를 피하고 한국어 소설 문체로 매끄럽게 쓴다.',
      '- 장면은 현재진행처럼 이어지고, 문장 종결은 단조롭게 반복하지 말 것.',
      '- 서술에 인칭이 어색해질 경우, 항상 무인칭을 우선 선택한다.',
      '- 예시(서술/무인칭): 문을 밀고 들어선다. 공기와 소음이 한꺼번에 밀려와 숨이 잠깐 걸린다.',
      '- 예시(대사/허용): "너, 여기 처음이야?" 같은 "너"는 대사에서만 자연스럽게 사용한다.',
      '- 주인공 이름 사용 가이드:',
      '  · 3000자 기준: 1~2회',
      '  · 5000자 기준: 2~3회',
      '  · 7000자 기준: 3~4회',
      '- 이름은 초반(정체성 고정), 중반(감정/관계 전환), 후반(선택 직전)에 분산 배치하고, 그 외에는 무인칭 서술을 유지한다.',
      '- 이름 빈도 카운트는 “서술문에서의 이름 등장”만 기준이며, 대사 속 호명은 제외한다.',
      '- 주인공 이름이 입력되지 않았더라도(공란/미지정), 서술은 반드시 무인칭으로 유지하며 “너/당신”으로 대체하지 않는다.',
      '- 금지어(서술 0회 강제): 너, 네, 너의, 너에게, 너는, 당신, 당신의, 당신에게.',
      '- 최종 출력에서 금지어가 1회라도 발견되면, 전체 서술을 즉시 다시 써서 금지어 0회로 만든 뒤 제출한다.',
      '- 템플릿/요약/가이드/초안/조각에 금지어가 포함되어 있어도, 의미만 반영하여 서술을 무인칭으로 재작성한다. (원문 문장/인칭 복제 금지)',
      '- 대사에 “너”가 등장한 직후에도, 다음 서술 문장은 반드시 무인칭으로 시작한다. (대사→서술 리셋 강제)',
      '- 목표 분량: 약 ${targetChars}자 내외.',
    ].join('\n');
  }

  static String _protagonistBlock({
    required StoryProject project,
    required int targetChars,
  }) {
    final name = project.protagonistName.trim();

    String freq;
    if (targetChars <= 3000) {
      freq = '1~2회';
    } else if (targetChars <= 5000) {
      freq = '2~3회';
    } else {
      freq = '3~4회';
    }

    if (name.isEmpty) {
      return [
        '[PROTAGONIST: 안내]',
        '- 주인공 이름이 아직 저장되지 않았다(공란).',
        '- 그럼에도 서술은 반드시 무인칭을 유지하고 “너/당신”으로 대체하지 않는다.',
        '- 주인공을 지칭할 때는 이름 대신 주어 생략/행동/감각 중심으로만 이어 간다.',
      ].join('\n');
    }

    return [
      '[PROTAGONIST: 필수]',
      '- 주인공 이름(필수 고정): $name',
      '- 본문 서술에서 주인공을 가리킬 때는 2인칭 금지어로 대체하지 말고, 무인칭 서술을 유지하되 필요 지점에서 이름을 사용한다.',
      '- 이름 사용 빈도(서술 기준): $freq (targetChars=$targetChars)',
      '- 이름 배치 원칙: 초반 1회(정체성 고정) + 중반 0~1회(관계/감정 전환) + 후반 0~1회(선택 직전).',
      '- 이름 빈도 카운트는 “서술문에서의 이름 등장”만 기준이며, 대사 속 호명은 제외한다.',
    ].join('\n');
  }

  static String _sceneConstraintsBlock({
    required int nextNumber,
    required Tone tone,
    required NarrativeState state,
    required ReaderIntent intent,
  }) {
    return [
      '[SCENE CONSTRAINTS]',
      '- 시간은 끊기지 않고 이어진다. (설명하지 말고 장면으로만)',
      _relationshipConstraint(state.relationshipTemp),
      _sensoryConstraint(state.sensory),
      _unresolvedConstraint(state.unresolved),
      _progressionConstraint(nextNumber),
      _toneConstraint(tone, intent),
      _endOnCliff(state.goal),
      '- 이번 화 안에서 반드시 아래 중 하나가 일어나야 한다:',
      '  a) 새로운 정보/단서 발견',
      '  b) 인물 관계의 균열 또는 변화',
      '  c) 주인공의 선택 또는 행동 전환',
      '  → 아무것도 일어나지 않는 화는 실패로 간주한다.',
      '- 화 전체의 감정 흐름은 반드시 단순 상승이 아닌 곡선을 가져야 한다.',
      '  구조 예시: 긴장 → 작은 숨통(유머/온기/발견) → 더 큰 긴장 또는 반전',
      '  → 처음부터 끝까지 불안/긴장만 반복되는 구조는 금지.',
      '- 이번 화는 반드시 이전 화보다 이야기가 앞으로 나아가야 한다.',
      '  이전 화에서 이미 내려진 결정을 다시 고민하거나 반복하지 말 것.',
      '  이전 화 마지막 장면에서 시간상 최소 15분 이상 지난 시점부터 시작할 것.',
    ].where((s) => s.trim().isNotEmpty).join('\n');
  }

  static String _relationshipConstraint(String v) {
    if (v.contains('긴장')) {
      return '- 관계는 아직 풀리지 않는다. 말끝/거리/시선에서 불편함이 새어 나온다.';
    }
    return '';
  }

  static String _sensoryConstraint(List<String> sensory) {
    if (sensory.isEmpty) return '';
    return '- 감각 레이어: ${sensory.take(2).join(", ")} (설명 금지).';
  }

  static String _unresolvedConstraint(List<String> unresolved) {
    if (unresolved.isEmpty) return '';
    return '- 미해결은 “답”이 아니라 “압력”이다: ${unresolved.take(2).join(", ")}.';
  }

  static String _progressionConstraint(int n) {
    if (n <= 3) return '- 장면은 조심스럽게 전진한다.';
    if (n <= 6) return '- 장면은 압축된다. 망설임이 대가를 만든다.';
    return '- 장면은 피할 수 없는 지점으로 밀린다.';
  }

  static String _toneConstraint(Tone tone, ReaderIntent intent) {
    if (tone == Tone.detailed) return '- 디테일을 촘촘히 사용하라.';
    if (intent.intensity >= 2) return '- 긴장 밀도를 한 단계 올려라.';
    return '- 흐름은 자연스럽게 유지하라.';
  }

  static String _endOnCliff(String goal) {
    return '- 장면은 다음 행동 직전에서 멈춘다.';
  }

  static String _userDirectivesBlock({
    required String userRequest,
    required String scenarioInput,
    required Tone tone,
  }) {
    return [
      '[READER CUSTOM]',
      '- 톤: ${tone.label}',
      '- 요청: ${userRequest.isEmpty ? "기본 생성" : userRequest}',
      '- 가이드:\n${scenarioInput.isEmpty ? "기본 뼈대 기반으로 진행" : scenarioInput}',
      '- 대화는 실제 한국 10대~20대가 쓰는 구어체로 작성할 것.',
      '  설명용 대화("그래서 지금 상황이 어떻게 된 거야?") 금지.',
      '  대화 속에 감정과 정보가 자연스럽게 녹아들게 할 것.',
    ].join('\n');
  }

  static String _recallBlock(RecallPack recall) {
    final items = recall.items.where((e) => e.trim().isNotEmpty).toList();
    return [
      '[RECALL PACK: 조각만]',
      if (items.isEmpty)
        '- 조각이 없어도 세계는 이미 움직이고 있다.'
      else
        ...items.map((e) => '- (조각) $e'),
      '- 위 조각을 설명하지 말고, 행동·대사·소품으로만 드러내라.',
    ].join('\n');
  }

  static String _projectSeedBlock(StoryProject project) {
    return [
      '[PROJECT SEED]',
      '- 제목: ${project.title}',
      '- 로그라인: ${project.logline}',
      '- 주인공 이름(필수): ${project.protagonistName}',
      '- 기본 뼈대:\n${project.baseScenario}',
      '- 배경 설명으로 쓰지 말고 장면에서만 드러내라.',
    ].join('\n');
  }

  static String _outputBlock({required int nextNumber, required int targetChars}) {
    return [
      '[OUTPUT]',
      '- 이제 ${nextNumber}화(바로 이어지는 장면)를 작성하라.',
      '- 분량: 반드시 ${targetChars}자 이상 작성할 것.',
      '  분량이 부족하면 장면을 더 추가하여 채워라.',
      '  절대 중간에 끊지 말 것.',
      '- 장면은 결정 직전에서 끊어라.',
    ].join('\n');
  }
}









