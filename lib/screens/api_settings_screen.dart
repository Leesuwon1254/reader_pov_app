import 'package:flutter/material.dart';
import '../services/api_config.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _ctrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ApiConfig.getBaseUrl();
    _ctrl.text = 'https://reader-pov-app.onrender.com';
    if (mounted) setState(() => _loading = false);
  }

  bool _isValidUrl(String s) {
    final t = s.trim();
    if (!t.startsWith('http://') && !t.startsWith('https://')) return false;
    try {
      final u = Uri.parse(t);
      return u.host.isNotEmpty && (u.port != 0);
    } catch (_) {
      return false;
    }
  }

  Future<void> _save() async {
    final v = _ctrl.text.trim();
    if (!_isValidUrl(v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 URL 형식이 아닙니다. 예: https://reader-pov-app.onrender.com')),
      );
      return;
    }
    await ApiConfig.setBaseUrl(v);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API 주소 저장 완료')),
    );
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API 설정')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '서버(API) 주소를 입력하세요.\n(같은 Wi-Fi에 있는 PC의 IPv4 주소 + 포트)',
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'https://reader-pov-app.onrender.com',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('저장'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
