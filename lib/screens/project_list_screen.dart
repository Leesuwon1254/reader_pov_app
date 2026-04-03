import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/storage_service.dart';

import 'create_project_screen.dart';
import 'project_detail_screen.dart';
import 'genre_select_screen.dart';

// ✅ API 설정 화면
import 'api_settings_screen.dart';
import '../services/api_config.dart';
import '../widgets/version_note_dialog.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  bool _loading = true;
  List<StoryProject> get _projects => StorageService.projects;

  String? _apiBaseUrl; // ✅ 현재 저장된 API 주소 표시용

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await StorageService.init();
    await _loadApiBaseUrl();
    if (!mounted) return;
    setState(() => _loading = false);
    // 버전 노트 팝업: 빌드 프레임 완료 후 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showVersionNoteIfNeeded(context);
    });
  }

  Future<void> _loadApiBaseUrl() async {
    _apiBaseUrl = await ApiConfig.getBaseUrl();
  }

  Future<void> _openProject(StoryProject project) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
    );

    // 상세에서 에피소드가 추가되었을 수 있으니 저장
    await StorageService.save();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _createProject() async {
    final newProject = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
    );

    if (newProject is StoryProject) {
      StorageService.projects.insert(0, newProject);
      await StorageService.save();
      if (!mounted) return;
      setState(() {});
      await _openProject(newProject);
    }
  }

  // ✅ A안: 소설 만들기 흐름 시작 → 결과(새 프로젝트)를 메인에서 받는다
  Future<void> _startNewStoryFlow() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GenreSelectScreen()),
    );

    if (result is StoryProject) {
      StorageService.projects.insert(0, result);
      await StorageService.save();
      if (!mounted) return;
      setState(() {});
      await _openProject(result);
    }
  }

  Future<void> _confirmDelete(StoryProject p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: Text('“${p.title}” 프로젝트를 삭제합니다.\n(에피소드 포함 전체 삭제)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await StorageService.deleteProjectById(p.id);
      if (!mounted) return;
      setState(() {});
    }
  }

  // ✅ API 설정 화면 열기
  Future<void> _openApiSettings() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ApiSettingsScreen()),
    );

    // changed == true 면 저장 성공 후 돌아온 것
    if (changed == true) {
      await _loadApiBaseUrl();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API 주소 적용됨: ${_apiBaseUrl ?? "(기본값 사용)"}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader POV'),
        actions: [
          // ✅ API 설정(⚙️)
          IconButton(
            onPressed: _openApiSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'API 설정',
          ),
          IconButton(
            onPressed: _startNewStoryFlow,
            icon: const Icon(Icons.auto_awesome),
            tooltip: '소설 만들기(장르/템플릿 선택)',
          ),
          IconButton(
            onPressed: _createProject,
            icon: const Icon(Icons.add),
            tooltip: '새 프로젝트 만들기',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.link, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'API: ${_apiBaseUrl ?? "기본값 사용"}',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _projects.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '아직 프로젝트가 없어요.\n“소설 만들기”로 시작해보자 🙂',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _startNewStoryFlow,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('소설 만들기'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _createProject,
                      icon: const Icon(Icons.add),
                      label: const Text('직접 프로젝트 만들기'),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _openApiSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('API 설정'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '소설 만들기에서 장르 → 템플릿을 고르면\n1화 생성까지 이어질 거야.',
                          style: TextStyle(height: 1.25),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _startNewStoryFlow,
                        child: const Text('시작'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ API 상태 카드 (선택)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '현재 API: ${_apiBaseUrl ?? "기본값 사용"}',
                          style: const TextStyle(height: 1.25),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _openApiSettings,
                        child: const Text('변경'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final p = _projects[index];
                    return InkWell(
                      onTap: () => _openProject(p),
                      onLongPress: () => _confirmDelete(p), // ✅ 길게 누르면 삭제
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        tileColor: cs.surfaceContainerHighest,
                        title: Text(
                          p.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(p.logline),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _projects.length,
                ),
              ],
            ),
    );
  }
}



