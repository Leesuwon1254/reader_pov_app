import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/ad_popup_content.dart';

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

  // ── 광고 스킵 버튼 노출 여부 ──────────────────────────────
  // true: 오른쪽 상단에 X 버튼 표시 (생성 취소 불가, UI만 존재)
  // false: 닫기 불가 (기본값)
  static const bool _allowAdSkip = false;

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

  // ── 광고 오버레이 표시 ────────────────────────────────────
  // Navigator를 미리 캡처하여 async gap 이후에도 안전하게 dismiss 가능.
  // showDialog 자체는 await하지 않아 다음 줄이 즉시 실행됨.
  void _showAdDialog(NavigatorState nav) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => PopScope(
        canPop: false, // 뒤로가기/제스처로 닫기 방지
        child: _AdLoadingDialog(allowSkip: _allowAdSkip),
      ),
    );
  }

  Future<void> _generate() async {
    // 연타/중복 호출 방지 guard
    if (_isGenerating) {
      debugPrint('[GenerateEpisodeScreen] onPressed 중복 진입 차단 (isGenerating=true)');
      return;
    }

    final ts = DateTime.now().toIso8601String();
    debugPrint('[GenerateEpisodeScreen] onPressed 진입 '
        'projectId=${widget.project.id} number=$_nextNumber ts=$ts');

    setState(() => _isGenerating = true);

    // Navigator를 async gap 이전에 캡처
    final nav = Navigator.of(context);
    bool dialogOpen = false;

    final userRequest =
        _requestCtrl.text.trim().isEmpty ? '기본 생성' : _requestCtrl.text.trim();
    final scenarioInput = _scenarioCtrl.text.trim().isEmpty
        ? '기본 뼈대 기반으로 진행'
        : _scenarioCtrl.text.trim();

    // 광고 오버레이 표시
    _showAdDialog(nav);
    dialogOpen = true;

    try {
      final episode = await ApiService.generateEpisode(
        project: widget.project,
        number: _nextNumber,
        tone: _tone,
        userRequest: userRequest,
        scenarioInput: scenarioInput,
        lengthHint: 5000,
      );

      // 성공: 광고 닫기 → 결과 화면으로 이동
      if (dialogOpen) {
        nav.pop(); // 광고 다이얼로그 닫기
        dialogOpen = false;
      }
      if (mounted) nav.pop(episode); // GenerateEpisodeScreen 닫고 에피소드 전달
    } catch (e) {
      // 실패: 광고 닫기 → 에러 토스트
      if (dialogOpen) {
        nav.pop();
        dialogOpen = false;
      }
      debugPrint('[GenerateEpisodeScreen] 생성 실패: $e');
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('생성 실패: $e'),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(label: '닫기', onPressed: () {}),
          ),
        );
      }
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

// ── 광고 로딩 다이얼로그 ─────────────────────────────────────
class _AdLoadingDialog extends StatelessWidget {
  final bool allowSkip;

  const _AdLoadingDialog({this.allowSkip = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더: 로딩 표시
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '소설 생성 중...',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: cs.onSurface,
                    ),
                  ),
                  // 스킵 버튼 (allowSkip == true일 때만 표시)
                  if (allowSkip) ...[
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: '스킵',
                      onPressed: () {
                        // 스킵은 UI만 닫힘 — 생성은 계속 진행됨
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '잠시만 기다려 주세요',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // 광고 콘텐츠 (AdPopupContent 교체로 AdMob 연결 가능)
            const AdPopupContent(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
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






