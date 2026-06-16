import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftsync/app/app.dart';

void main() {
  testWidgets('ShiftSyncApp initialization smoke test', (WidgetTester tester) async {
    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ShiftSyncApp(),
      ),
    );

    // Verify splash screen or initial elements render cleanly
    expect(find.byType(ShiftSyncApp), findsOneWidget);
  });
}
