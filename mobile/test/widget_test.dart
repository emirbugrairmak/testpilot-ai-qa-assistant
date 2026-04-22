import "package:flutter_test/flutter_test.dart";

import "package:testpilot_mobile/main.dart";

void main() {
  testWidgets("App boots", (WidgetTester tester) async {
    await tester.pumpWidget(const TestPilotMobileApp());
    expect(find.byType(TestPilotMobileApp), findsOneWidget);
  });
}
