import 'package:app_agent/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders app shell', (tester) async {
    await tester.pumpWidget(const AgentApp());
    await tester.pump();

    expect(find.text('App Agent'), findsWidgets);
  });
}
