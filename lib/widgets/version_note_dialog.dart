// lib/widgets/version_note_dialog.dart
//
// 버전 업데이트 시 1회 표시되는 변경사항 팝업.
// project_list_screen.dart의 _boot()에서 호출됩니다.
//
// 새 버전 출시 시 lib/utils/version_notes.dart에 항목만 추가하면
// 자동으로 팝업에 반영됩니다.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/version_notes.dart';

const String _prefKey = 'last_seen_version';

/// 앱 시작 시 호출. 현재 버전이 last_seen_version과 다를 때만 팝업 표시.
Future<void> showVersionNoteIfNeeded(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  final currentVersion = info.version; // e.g. "2.8.1"

  final prefs = await SharedPreferences.getInstance();
  final lastSeen = prefs.getString(_prefKey) ?? '';

  if (lastSeen == currentVersion) return;
  if (!context.mounted) return;

  final notes = versionNotes[currentVersion];

  // 노트가 없어도 버전 기록은 갱신
  if (notes == null || notes.isEmpty) {
    await prefs.setString(_prefKey, currentVersion);
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _VersionNoteDialog(version: currentVersion, notes: notes),
  );

  await prefs.setString(_prefKey, currentVersion);
}

class _VersionNoteDialog extends StatelessWidget {
  final String version;
  final List<String> notes;

  const _VersionNoteDialog({required this.version, required this.notes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.new_releases_rounded, color: cs.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'v$version 업데이트',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 업데이트에서 변경된 내용이에요.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(note, style: const TextStyle(height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
