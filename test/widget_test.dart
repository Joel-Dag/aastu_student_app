import 'package:flutter_test/flutter_test.dart';

import 'package:aastu_student_app/main.dart';

void main() {
  testWidgets('App renders with title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AastuStudentGuideApp());

    // Verify that our app renders with the correct title.
    expect(find.text('AASTU Student Guide'), findsOneWidget);
  });
}
