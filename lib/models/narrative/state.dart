class NarrativeState {
  final int episodeNo;
  final String timeHint;        // "같은 날 밤", "사흘 뒤 새벽" 등
  final String placeId;         // 장소 ID
  final List<String> castIds;   // 현재 주요 등장 인물 ID들
  final String relationshipTemp; // "경계", "냉각", "긴장", "친밀" 등
  final List<String> unresolved; // "열지 않음", "확인하지 않음" 등 1~3개
  final List<String> sensory;    // "차가운 문고리", "귀에 남는 낮은 목소리" 등 1~2개
  final String goal;             // 이번 화 목표(작게)

  const NarrativeState({
    required this.episodeNo,
    required this.timeHint,
    required this.placeId,
    required this.castIds,
    required this.relationshipTemp,
    required this.unresolved,
    required this.sensory,
    required this.goal,
  });

  NarrativeState nextWith({
    int? episodeNo,
    String? timeHint,
    String? placeId,
    List<String>? castIds,
    String? relationshipTemp,
    List<String>? unresolved,
    List<String>? sensory,
    String? goal,
  }) {
    return NarrativeState(
      episodeNo: episodeNo ?? this.episodeNo,
      timeHint: timeHint ?? this.timeHint,
      placeId: placeId ?? this.placeId,
      castIds: castIds ?? this.castIds,
      relationshipTemp: relationshipTemp ?? this.relationshipTemp,
      unresolved: unresolved ?? this.unresolved,
      sensory: sensory ?? this.sensory,
      goal: goal ?? this.goal,
    );
  }
}
