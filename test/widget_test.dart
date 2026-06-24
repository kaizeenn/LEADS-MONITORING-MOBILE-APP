import 'package:flutter_test/flutter_test.dart';
import 'package:leads_monitoring_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LeadsMonitoringApp());
    expect(find.byType(LeadsMonitoringApp), findsOneWidget);
  });
}
