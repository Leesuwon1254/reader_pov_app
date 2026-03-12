import 'package:flutter_test/flutter_test.dart';

import 'package:reader_pov_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ReaderPovApp());
    expect(find.byType(ReaderPovApp), findsOneWidget);
  });
}
