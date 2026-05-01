import 'package:flutter_test/flutter_test.dart';
import 'package:blackjack_app/main.dart';

void main() {
  testWidgets('Blackjack app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BlackjackApp());

    // Verify that the title is present.
    expect(find.text('BLACKJACK'), findsOneWidget);
  });
}
