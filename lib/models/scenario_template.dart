import 'genre.dart';

class ScenarioTemplate {
  final String id;
  final Genre genre;
  final String title;
  final String logline;
  final String skeleton;

  const ScenarioTemplate({
    required this.id,
    required this.genre,
    required this.title,
    required this.logline,
    required this.skeleton,
  });
}
