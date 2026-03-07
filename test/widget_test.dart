import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_application_development/main.dart';

void main() {
  testWidgets('User list screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Supabase User Data'), findsOneWidget);
    expect(find.textContaining('Total Users:'), findsOneWidget);
  });
}
