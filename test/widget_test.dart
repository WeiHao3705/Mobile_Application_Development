import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_application_development/main.dart';

void main() {
  testWidgets('Landing screen renders login and sign up actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Welcome to FitTrack'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });
}
