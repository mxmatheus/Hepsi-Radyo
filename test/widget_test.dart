import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hepsiradyo/main.dart';

void main() {
  testWidgets('App loads basic shell test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HepsiRadyoApp(),
      ),
    );
    expect(find.byType(HepsiRadyoApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
