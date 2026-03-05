import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/templates_repo.dart';
import 'start_episode_screen.dart';

class TemplateSelectScreen extends StatelessWidget {
  final StoryGenre genre;
  const TemplateSelectScreen({super.key, required this.genre});

  List<StoryTemplate> get templates => TemplatesRepo.byGenre(genre);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = templates;

    return Scaffold(
      appBar: AppBar(title: Text('${genre.label} 템플릿')),
      body: list.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '아직 ${genre.label} 템플릿이 없어요.\n(템플릿 데이터를 추가하면 여기서 바로 보여요)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.3),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: list.map((t) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(t.logline,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(t.skeleton, style: const TextStyle(height: 1.25)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('이 템플릿으로 시작'),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StartEpisodeScreen(template: t),
                              ),
                            );

                            if (result is StoryProject) {
                              Navigator.pop(context, result);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}





