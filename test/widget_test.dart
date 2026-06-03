import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studypath/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: StudyPathApp()));
    await tester.pumpAndSettle();

    // Verify app renders the branding
    expect(find.textContaining('StudyPath'), findsWidgets);
  });
}
