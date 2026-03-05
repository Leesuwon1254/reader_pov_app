import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';
import 'episode_viewer_screen.dart';
import 'generate_episode_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final StoryProject project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  StoryProject get project => widget.project;

  void _openEpisode(Episode ep) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EpisodeViewerScreen(
          // ✅ nullable-safe: title이 null이어도 화면이 죽지 않도록 기본값 제공
          projectTitle: project.title ?? 'Reader POV',
          episode: ep,
        ),
      ),
    );
  }

  void _createNextEpisode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenerateEpisodeScreen(project: project),
      ),
    ).then((created) async {
      if (created is Episode) {
        setState(() {
          // upsert: ApiService가 이미 리스트에 추가했을 수 있으므로
          // 같은 number가 있으면 교체, 없으면 추가
          final idx = project.episodes.indexWhere((e) => e.number == created.number);
          if (idx >= 0) {
            project.episodes[idx] = created;
          } else {
            project.episodes.add(created);
            project.episodes.sort((a, b) => a.number.compareTo(b.number));
          }
        });

        await StorageService.save();
        _openEpisode(created);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final episodes = project.episodes;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.title ?? 'Reader POV'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNextEpisode,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('다음화 만들기'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProjectInfoCard(project: project),
          const SizedBox(height: 16),
          Text(
            '에피소드 (${episodes.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (episodes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Text('아직 에피소드가 없어요.\n“다음화 만들기”로 1화를 만들어보자!'),
              ),
            )
          else
            ...episodes.reversed.map((ep) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  title: Text('${ep.number}화. ${ep.title}'),
                  subtitle: Text('${ep.tone.label} · ${formatDate(ep.createdAt)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openEpisode(ep),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProjectInfoCard extends StatelessWidget {
  final StoryProject project;
  const _ProjectInfoCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.logline ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          const Text(
            '기본 시나리오(뼈대)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(project.baseScenario ?? '', style: const TextStyle(height: 1.3)),
        ],
      ),
    );
  }
}



