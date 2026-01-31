// Basic Flutter widget test for YemenChat
//
// This is a placeholder test that verifies the app can be built.

import 'package:flutter_test/flutter_test.dart';
import 'package:yemenchat/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const YemenChatApp());

    // Verify the app builds without crashing
    expect(find.byType(YemenChatApp), findsOneWidget);
  });
}
