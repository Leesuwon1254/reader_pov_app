import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/generating_dialog.dart';

class StartEpisodeScreen extends StatefulWidget {
  final StoryTemplate template;
  const StartEpisodeScreen({super.key, required this.template});

  @override
  State<StartEpisodeScreen> createState() => _StartEpisodeScreenState();
}

class _StartEpisodeScreenState extends State<StartEpisodeScreen> {
  bool _showTemplateDetail = false;
  Tone _tone = Tone.normal;

  int _lengthHint = 5000;

  // ✅ NEW: 주인공 이름(필수)
  final _nameCtrl = TextEditingController();

  final _requestCtrl = TextEditingController();
  final _guideCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _requestCtrl.dispose();
    _guideCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateFirstEpisode() async {
    if (_loading) return;

    final protagonistName = _nameCtrl.text.trim();
    if (protagonistName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주인공 이름은 필수야! (예: 김태윤)')),
      );
      return;
    }

    setState(() => _loading = true);

    final userRequestRaw = _requestCtrl.text.trim();
    final guideRaw = _guideCtrl.text.trim();

    final userRequest = userRequestRaw.isEmpty ? '기본 생성' : userRequestRaw;
    final scenarioInput = guideRaw.isEmpty ? '기본 뼈대 기반으로 진행' : guideRaw;

    // ✅ 새 프로젝트 생성 (1화 생성 시점에 프로젝트가 확정됨)
    final newProject = StoryProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: widget.template.title,
      logline: widget.template.logline,
      baseScenario: widget.template.skeleton,
      episodes: [],

      // ✅ NEW: 주인공 이름 필수 주입
      protagonistName: protagonistName,
    );

    // Navigator를 async gap 이전에 캡처
    final nav = Navigator.of(context);
    bool dialogOpen = false;

    // 광고 + 단계 메시지 다이얼로그 표시
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const PopScope(
        canPop: false,
        child: GeneratingDialog(),
      ),
    );
    dialogOpen = true;

    try {
      // 백엔드로 1화 소설 생성 (prompt 빌드 · 상태 저장 · 카드 추출 · 프로젝트 저장 모두 ApiService 내부에서 처리)
      await ApiService.generateEpisode(
        project: newProject,
        number: 1,
        tone: _tone,
        userRequest: userRequest,
        scenarioInput: scenarioInput,
        lengthHint: _lengthHint,
      );

      if (dialogOpen) {
        nav.pop();
        dialogOpen = false;
      }
      if (!mounted) return;
      setState(() => _loading = false);

      // ✅ “새 프로젝트 생성 완료” 결과를 메인으로 반환
      nav.pop(newProject);
    } catch (e) {
      if (dialogOpen) {
        nav.pop();
        dialogOpen = false;
      }
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('생성 실패: $e'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(label: '닫기', onPressed: () {}),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('에피소드 시작 (1화 만들기)')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.template.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.template.logline,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    if (_showTemplateDetail)
                      Text(
                        widget.template.skeleton,
                        style: const TextStyle(height: 1.25),
                      )
                    else
                      Text(
                        widget.template.skeleton,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(height: 1.25),
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _showTemplateDetail = !_showTemplateDetail),
                        child: Text(_showTemplateDetail ? '접기' : '자세히 보기'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '※ 1화가 생성되면 자동으로 새 프로젝트가 만들어져요.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ✅ NEW: 주인공 이름(필수)
              const Text('주인공 이름(필수)', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '예) 김태윤',
                  helperText: '무인칭 서술을 안정적으로 유지하려면 주인공 이름을 반드시 고정해야 해요.',
                ),
              ),

              const SizedBox(height: 18),

              const Text('1화 분위기(톤)', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              ...Tone.values.map((t) {
                final selected = t == _tone;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? cs.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(t.icon),
                    title: Text(t.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(t.hint),
                    trailing: selected ? const Icon(Icons.check_circle) : const Icon(Icons.circle_outlined),
                    onTap: () => setState(() => _tone = t),
                  ),
                );
              }),

              const SizedBox(height: 8),

              const Text('분량', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _LengthChip(
                    label: '짧게 (3000자)',
                    selected: _lengthHint == 3000,
                    onTap: () => setState(() => _lengthHint = 3000),
                  ),
                  _LengthChip(
                    label: '기본 (5000자)',
                    selected: _lengthHint == 5000,
                    onTap: () => setState(() => _lengthHint = 5000),
                  ),
                  _LengthChip(
                    label: '길게 (7000자)',
                    selected: _lengthHint == 7000,
                    onTap: () => setState(() => _lengthHint = 7000),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text('추가 요청(선택)', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              TextField(
                controller: _requestCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '예) 대사를 늘려줘 / 주인공을 더 냉정하게 / 긴장감 있게',
                ),
              ),

              const SizedBox(height: 16),

              const Text('이번 화 가이드(선택)', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              TextField(
                controller: _guideCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '예) 장소/사건/목표/반전 포인트를 구체적으로 적어줘',
                ),
              ),
            ],
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: FilledButton.icon(
              onPressed: _loading ? null : _generateFirstEpisode,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? '생성 중...' : '1화 생성하기'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LengthChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LengthChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}


