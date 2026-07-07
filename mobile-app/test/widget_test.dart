import 'package:flutter_test/flutter_test.dart';
import 'package:joftojoor_mobile/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JoftojoorApp());

    // Verify that our main shell or screen loaded.
    expect(find.byType(JoftojoorApp), findsOneWidget);
  });
}
