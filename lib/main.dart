import 'package:flutter/material.dart';
import 'screens/project_list_screen.dart';
import 'services/server_warmup_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ServerWarmupService.instance.warmup(); // 백그라운드 웜업, 결과 무시
  runApp(const ReaderPovApp());
}

class ReaderPovApp extends StatelessWidget {
  const ReaderPovApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reader POV',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ProjectListScreen(),
    );
  }
}






