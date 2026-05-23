import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_contest_app/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const QuranContestApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
