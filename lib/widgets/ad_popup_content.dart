// lib/widgets/ad_popup_content.dart
//
// 광고 콘텐츠 위젯.
// 실제 AdMob/광고 SDK로 교체할 때는 이 파일 내부만 수정하면 됩니다.
// 인터페이스(위젯 이름 · 생성자)를 유지하면 다른 파일은 건드릴 필요 없습니다.

import 'dart:math';
import 'package:flutter/material.dart';

class AdPopupContent extends StatefulWidget {
  const AdPopupContent({super.key});

  @override
  State<AdPopupContent> createState() => _AdPopupContentState();
}

class _AdPopupContentState extends State<AdPopupContent> {
  // ──────────────────────────────────────────────
  // 더미 광고 데이터 (추후 AdMob 광고 위젯으로 교체)
  // ──────────────────────────────────────────────
  static const _ads = [
    (
      title: '📖 오늘의 이야기',
      body: '매일 새로운 에피소드로 나만의 소설을 완성해보세요.',
    ),
    (
      title: '✨ Reader POV',
      body: '독자가 주인공이 되는 몰입형 연재소설 앱.',
    ),
    (
      title: '🎯 다음화가 기다려진다면?',
      body: '즐겨찾기로 저장하고 친구에게 공유해보세요.',
    ),
    (
      title: '⭐ 리뷰를 남겨주세요',
      body: '여러분의 피드백이 앱을 더 좋게 만듭니다.',
    ),
  ];

  late final ({String title, String body}) _ad;

  @override
  void initState() {
    super.initState();
    _ad = _ads[Random().nextInt(_ads.length)];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 광고 라벨
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '광고',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── 광고 이미지 영역 (AdMob 배너로 교체할 자리) ──
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 36,
                color: cs.primary.withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 광고 텍스트
          Text(
            _ad.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            _ad.body,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '광고 배너 (추후 AdMob 연결 예정)',
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
