import 'package:flutter/material.dart';
import '../models/models.dart';
import 'template_select_screen.dart';

class GenreSelectScreen extends StatelessWidget {
  const GenreSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('장르 선택')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: StoryGenre.values.map((g) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: Icon(g.icon),
              title: Text(g.label, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(g.hint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TemplateSelectScreen(genre: g)),
                );

                // ✅ TemplateSelectScreen에서 StoryProject를 받으면 메인으로 전달
                if (result is StoryProject) {
                  Navigator.pop(context, result);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}


