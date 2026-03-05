import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../utils/date_utils.dart';

class EpisodeViewerScreen extends StatefulWidget {
  final String projectTitle;
  final Episode episode;

  const EpisodeViewerScreen({
    super.key,
    required this.projectTitle,
    required this.episode,
  });

  @override
  State<EpisodeViewerScreen> createState() => _EpisodeViewerScreenState();
}

class _EpisodeViewerScreenState extends State<EpisodeViewerScreen> {
  bool _showPromptHint = true;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.episode.content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('복사 완료!')),
      );
    }
  }

  bool _looksLikePlaceholder(String t) {
    final s = t.trim();
    if (s.isEmpty) return true;
    if (s.startsWith('(생성 대기)')) return true;
    if (s.contains('이 에피소드는 곧 생성됩니다')) return true;
    return false;
  }

  bool _looksLikePrompt(String t) {
    final s = t;
    return s.contains('[HARD RULES]') ||
        s.contains('[POV / STYLE]') ||
        s.contains('[SCENE CONSTRAINTS]') ||
        s.contains('[RECALL PACK') ||
        s.contains('[PROJECT SEED]') ||
        s.contains('[OUTPUT]') ||
        s.contains('2인칭 독자시점');
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.episode.content;

    final isPlaceholder = _looksLikePlaceholder(content);
    final isLikelyPrompt = _looksLikePrompt(content);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectTitle} · ${widget.episode.number}화'),
        actions: [
          IconButton(
            tooltip: '복사',
            icon: const Icon(Icons.copy),
            onPressed: isPlaceholder ? null : () => _copy(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.episode.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _MetaRow(label: '톤', value: widget.episode.tone.label),
          _MetaRow(label: '요청', value: widget.episode.userRequest),
          _MetaRow(label: '가이드', value: widget.episode.scenarioInput),
          _MetaRow(label: '생성일', value: formatDate(widget.episode.createdAt)),
          const Divider(height: 28),

          if (isPlaceholder)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: const Text(
                '※ 아직 생성된 내용이 없어요.\n다시 생성 후 확인해주세요.',
                style: TextStyle(height: 1.4),
              ),
            )
          else if (isLikelyPrompt && _showPromptHint)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '※ 지금 표시된 내용이 “소설 본문”이 아니라 “프롬프트”로 보입니다.\n(백엔드 연동이 정상이라면 소설 본문이 출력되어야 해요.)',
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _showPromptHint = false),
                      child: const Text('이 안내 숨기기'),
                    ),
                  )
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: SelectableText(
              content,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: isPlaceholder ? null : () => _copy(context),
            icon: const Icon(Icons.copy),
            label: const Text('복사하기'),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
