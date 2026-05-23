import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_contest_app/ui/levels/widgets/levels_stats_cards.dart';

void main() {
  group('LevelsStatsCards', () {
    Widget buildCard({
      int totalLevels = 10,
      int activeLevels = 7,
      int inactiveLevels = 3,
      int totalStudents = 150,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: LevelsStatsCards(
            totalLevels: totalLevels,
            activeLevels: activeLevels,
            inactiveLevels: inactiveLevels,
            totalStudents: totalStudents,
            primaryColor: const Color(0xFF03121C),
          ),
        ),
      );
    }

    testWidgets('displays all stat values', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('10'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
    });

    testWidgets('displays all stat labels', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('إجمالي المستويات'), findsOneWidget);
      expect(find.text('المستويات النشطة'), findsOneWidget);
      expect(find.text('المعطلة مؤقتاً'), findsOneWidget);
      expect(find.text('إجمالي الطلاب'), findsOneWidget);
    });

    testWidgets('handles zero values', (tester) async {
      await tester.pumpWidget(buildCard(
        totalLevels: 0,
        activeLevels: 0,
        inactiveLevels: 0,
        totalStudents: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNWidgets(4));
    });
  });
}
