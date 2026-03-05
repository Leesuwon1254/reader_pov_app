enum CardType { character, place, thread, trace }

abstract class CardBase {
  final CardType type;
  final String id;
  final List<String> tags;
  final int lastTouchedEpisode; // 마지막으로 프롬프트에 포함된 화
  final double priority; // 0~1

  const CardBase({
    required this.type,
    required this.id,
    required this.tags,
    required this.lastTouchedEpisode,
    required this.priority,
  });
}

class CharacterCard extends CardBase {
  final String name;
  final List<String> traits; // 말투/성격 키워드
  final bool alive;

  const CharacterCard({
    required super.id,
    required super.tags,
    required super.lastTouchedEpisode,
    required super.priority,
    required this.name,
    required this.traits,
    this.alive = true,
  }) : super(type: CardType.character);
}

class PlaceCard extends CardBase {
  final String title;
  final List<String> features;

  const PlaceCard({
    required super.id,
    required super.tags,
    required super.lastTouchedEpisode,
    required super.priority,
    required this.title,
    required this.features,
  }) : super(type: CardType.place);
}

class ThreadCard extends CardBase {
  final String surface;   // 독자에게 보이는 형태(“엘리베이터의 남자”)
  final String status;    // "unresolved", "resolved", "dormant" 등

  const ThreadCard({
    required super.id,
    required super.tags,
    required super.lastTouchedEpisode,
    required super.priority,
    required this.surface,
    this.status = "unresolved",
  }) : super(type: CardType.thread);
}

class TraceCard extends CardBase {
  final String sensoryHint; // 감각 흔적(“낮은 목소리”, “금속 냄새” 등)

  const TraceCard({
    required super.id,
    required super.tags,
    required super.lastTouchedEpisode,
    required super.priority,
    required this.sensoryHint,
  }) : super(type: CardType.trace);
}
