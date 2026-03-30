// lib/widgets/generating_dialog.dart
//
// 소설 생성 중 로딩 다이얼로그.
// 타이머 기반으로 단계별 상태 메시지를 보여주고, 광고 팝업을 포함한다.
// start_episode_screen(1화)과 generate_episode_screen(2화+) 양쪽에서 공통으로 사용.

import 'dart:async';
import 'package:flutter/material.dart';
import 'ad_popup_content.dart';

class GeneratingDialog extends StatefulWidget {
  final bool allowSkip;
  const GeneratingDialog({super.key, this.allowSkip = false});

  @override
  State<GeneratingDialog> createState() => _GeneratingDialogState();
}

class _GeneratingDialogState extends State<GeneratingDialog> {
  static const _steps = [
    '✦ 이야기를 구성하는 중...',
    '✦ 장면을 이어 쓰는 중...',
    '✦ 마무리하는 중...',
  ];

  int _stepIndex = 0;
  int _elapsedSeconds = 0;
  Timer? _stepTimer;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    // 30초마다 다음 단계로 전환 (마지막 단계에서 멈춤)
    _stepTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      if (_stepIndex < _steps.length - 1) {
        setState(() => _stepIndex++);
      }
    });
    // 1초마다 경과 시간 카운트업
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  String get _elapsedLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return m > 0 ? '$m분 $s초' : '$s초';
  }

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
            // 헤더: 단계 메시지 + 스피너
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
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
                  Expanded(
                    child: Text(
                      _steps[_stepIndex],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (widget.allowSkip)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: '스킵',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '잠시만 기다려 주세요',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '경과 시간: $_elapsedLabel',
                  style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Text(
                  '예상 소요: 1~2분',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 광고 콘텐츠
            const AdPopupContent(),
          ],
        ),
      ),
    );
  }
}
