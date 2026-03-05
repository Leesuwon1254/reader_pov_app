import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class GenerateEpisodeScreen extends StatefulWidget {
  final StoryProject project;
  const GenerateEpisodeScreen({super.key, required this.project});

  @override
  State<GenerateEpisodeScreen> createState() => _GenerateEpisodeScreenState();
}

class _GenerateEpisodeScreenState extends State<GenerateEpisodeScreen> {
  final _requestCtrl = TextEditingController();
  final _scenarioCtrl = TextEditingController();

  Tone _tone = Tone.normal;
  bool _isGenerating = false;

  @override
  void dispose() {
    _requestCtrl.dispose();
    _scenarioCtrl.dispose();
    super.dispose();
  }

  int get _nextNumber => widget.project.episodes.isEmpty
      ? 1
      : (widget.project.episodes
              .map((e) => e.number)
              .reduce((a, b) => a > b ? a : b) +
          1);

  Future<void> _generate() async {
    setState(() => _isGenerating = true);

    final userRequest =
        _requestCtrl.text.trim().isEmpty ? '기본 생성' : _requestCtrl.text.trim();
    final scenarioInput = _scenarioCtrl.text.trim().isEmpty
        ? '기본 뼈대 기반으로 진행'
        : _scenarioCtrl.text.trim();

    try {
      final episode = await ApiService.generateEpisode(
        project: widget.project,
        number: _nextNumber,
        tone: _tone,
        userRequest: userRequest,
        scenarioInput: scenarioInput,
        lengthHint: 5000,
      );

      if (!mounted) return;
      setState(() => _isGenerating = false);
      Navigator.pop(context, episode);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('생성 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_nextNumber}화 만들기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '요청(독자/작성자 요구사항)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _requestCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '예) 지금까지 내용을 더 구체적으로, 더 자극적으로, 주변 인물 추가 등',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '톤 선택',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _TonePicker(
            selected: _tone,
            onChanged: (t) => setState(() => _tone = t),
          ),
          const SizedBox(height: 14),
          const Text(
            '이번 화의 시나리오/가이드(선택)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _scenarioCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '예)\n장소: ___\n인물: A(성격), B(성격)\n떡밥: ___\n(없어도 됨)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isGenerating ? null : _generate,
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isGenerating ? '생성 중...' : '생성하기'),
          ),
        ],
      ),
    );
  }
}

class _TonePicker extends StatelessWidget {
  final Tone selected;
  final ValueChanged<Tone> onChanged;

  const _TonePicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: Tone.values.map((t) {
        final isSelected = t == selected;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Icon(t.icon),
            title: Text(
              t.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(t.hint),
            trailing: isSelected
                ? const Icon(Icons.check_circle)
                : const Icon(Icons.circle_outlined),
            onTap: () => onChanged(t),
          ),
        );
      }).toList(),
    );
  }
}






