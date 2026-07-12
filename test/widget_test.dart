// Smoke test for the Bamboo Weave Classifier app shell.
//
// The TFLite model cannot load in a host `flutter test` (no native runtime),
// so the app enters its error state gracefully; this test only checks that the
// shell renders and the capture controls are present.

import 'package:bambooapp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the app shell and capture controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BambooApp());
    await tester.pump(); // start initState / model load
    await tester.pump(const Duration(seconds: 1)); // let the load future settle

    expect(find.text('Bamboo Weave Classifier'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(2));
  });
}
