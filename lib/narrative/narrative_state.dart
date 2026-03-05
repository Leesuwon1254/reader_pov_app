class NarrativeState {
  final int episodeNo;
  final String timeHint;
  final String relationshipTemp;
  final List<String> unresolved;
  final List<String> sensory;
  final String goal;

  const NarrativeState({
    required this.episodeNo,
    required this.timeHint,
    required this.relationshipTemp,
    required this.unresolved,
    required this.sensory,
    required this.goal,
  });

  Map<String, dynamic> toJson() => {
        "episodeNo": episodeNo,
        "timeHint": timeHint,
        "relationshipTemp": relationshipTemp,
        "unresolved": unresolved,
        "sensory": sensory,
        "goal": goal,
      };

  factory NarrativeState.fromJson(Map<String, dynamic> j) => NarrativeState(
        episodeNo: (j["episodeNo"] ?? 0) as int,
        timeHint: (j["timeHint"] ?? "같은 날 밤") as String,
        relationshipTemp: (j["relationshipTemp"] ?? "긴장") as String,
        unresolved: (j["unresolved"] as List? ?? const []).cast<String>(),
        sensory: (j["sensory"] as List? ?? const []).cast<String>(),
        goal: (j["goal"] ?? "다음 행동 직전까지") as String,
      );
}
