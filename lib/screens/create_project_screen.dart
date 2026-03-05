import 'package:flutter/material.dart';
import '../models/models.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _titleCtrl = TextEditingController();
  final _loglineCtrl = TextEditingController();
  final _scenarioCtrl = TextEditingController();

  // ✅ NEW: 주인공 이름(필수)
  final _protagonistCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _loglineCtrl.dispose();
    _scenarioCtrl.dispose();
    _protagonistCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final logline = _loglineCtrl.text.trim();
    final scenario = _scenarioCtrl.text.trim();
    final protagonistName = _protagonistCtrl.text.trim();

    // ✅ 제목 + 시나리오 + 주인공 이름 필수
    if (title.isEmpty || scenario.isEmpty || protagonistName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목 / 주인공 이름 / 시나리오(뼈대)는 필수야!')),
      );
      return;
    }

    final project = StoryProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      logline: logline.isEmpty ? '한 줄 소개 없음' : logline,
      baseScenario: scenario,

      // ✅ NEW
      protagonistName: protagonistName,

      episodes: [],
    );

    Navigator.pop(context, project);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 프로젝트 만들기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: '프로젝트 제목',
              hintText: '예) 승자와 패자',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // ✅ NEW: 주인공 이름 입력 (필수)
          TextField(
            controller: _protagonistCtrl,
            decoration: const InputDecoration(
              labelText: '주인공 이름(필수)',
              hintText: '예) 김태윤',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _loglineCtrl,
            decoration: const InputDecoration(
              labelText: '한 줄 소개(선택)',
              hintText: '예) 금수저 vs 노력파',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scenarioCtrl,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '시나리오 뼈대(필수)',
              hintText: '주요 인물, 배경, 갈등 구조, 원하는 분위기 등을 적어줘',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check),
            label: const Text('생성'),
          ),
        ],
      ),
    );
  }
}
