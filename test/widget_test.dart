import 'package:flutter_test/flutter_test.dart';
import 'package:smart_to_do_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartToDoApp());

    // Verify that our app starts.
    expect(find.text('Smart To-Do'), findsOneWidget);
  });
}
