enum CardType { character, place, thread }

class CardBase {
  final CardType type;
  final String id;
  final List<String> tags;
  final double priority;
  final int lastTouchedEpisode;

  const CardBase({
    required this.type,
    required this.id,
    required this.tags,
    required this.priority,
    required this.lastTouchedEpisode,
  });

  Map<String, dynamic> toJson() => {
        "type": type.name,
        "id": id,
        "tags": tags,
        "priority": priority,
        "lastTouchedEpisode": lastTouchedEpisode,
      };

  static CardType _typeFrom(String s) {
    switch (s) {
      case 'character':
        return CardType.character;
      case 'place':
        return CardType.place;
      case 'thread':
        return CardType.thread;
      default:
        return CardType.thread;
    }
  }

  static CardBase fromJson(Map<String, dynamic> j) {
    final type = _typeFrom((j["type"] ?? "thread").toString());
    switch (type) {
      case CardType.character:
        return CharacterCard.fromJson(j);
      case CardType.place:
        return PlaceCard.fromJson(j);
      case CardType.thread:
        return ThreadCard.fromJson(j);
    }
  }
}

class CharacterCard extends CardBase {
  final String name;
  final List<String> traits;
  final List<String> relations;

  CharacterCard({
    required super.id,
    required super.tags,
    required super.priority,
    required super.lastTouchedEpisode,
    required this.name,
    required this.traits,
    required this.relations,
  }) : super(type: CardType.character);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        "name": name,
        "traits": traits,
        "relations": relations,
      };

  factory CharacterCard.fromJson(Map<String, dynamic> j) => CharacterCard(
        id: (j["id"] ?? "").toString(),
        tags: (j["tags"] as List? ?? const []).cast<String>(),
        priority: (j["priority"] ?? 0.5).toDouble(),
        lastTouchedEpisode: (j["lastTouchedEpisode"] ?? 0) as int,
        name: (j["name"] ?? "").toString(),
        traits: (j["traits"] as List? ?? const []).cast<String>(),
        relations: (j["relations"] as List? ?? const []).cast<String>(),
      );
}

class PlaceCard extends CardBase {
  final String title;
  final List<String> features;

  PlaceCard({
    required super.id,
    required super.tags,
    required super.priority,
    required super.lastTouchedEpisode,
    required this.title,
    required this.features,
  }) : super(type: CardType.place);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        "title": title,
        "features": features,
      };

  factory PlaceCard.fromJson(Map<String, dynamic> j) => PlaceCard(
        id: (j["id"] ?? "").toString(),
        tags: (j["tags"] as List? ?? const []).cast<String>(),
        priority: (j["priority"] ?? 0.5).toDouble(),
        lastTouchedEpisode: (j["lastTouchedEpisode"] ?? 0) as int,
        title: (j["title"] ?? "").toString(),
        features: (j["features"] as List? ?? const []).cast<String>(),
      );
}

class ThreadCard extends CardBase {
  final String surface;
  final String status;

  ThreadCard({
    required super.id,
    required super.tags,
    required super.priority,
    required super.lastTouchedEpisode,
    required this.surface,
    required this.status,
  }) : super(type: CardType.thread);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        "surface": surface,
        "status": status,
      };

  factory ThreadCard.fromJson(Map<String, dynamic> j) => ThreadCard(
        id: (j["id"] ?? "").toString(),
        tags: (j["tags"] as List? ?? const []).cast<String>(),
        priority: (j["priority"] ?? 0.6).toDouble(),
        lastTouchedEpisode: (j["lastTouchedEpisode"] ?? 0) as int,
        surface: (j["surface"] ?? "").toString(),
        status: (j["status"] ?? "unresolved").toString(),
      );
}

