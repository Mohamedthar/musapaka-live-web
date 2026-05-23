import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_contest_app/ui/shared/widgets/confirm_dialog.dart';

void main() {
  group('ConfirmDialog', () {
    Future<void> pumpDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const ConfirmDialog(
                  title: 'تأكيد الحذف',
                  message: 'هل أنت متأكد؟',
                  confirmText: 'حذف',
                  confirmColor: Colors.red,
                  icon: Icons.delete_forever_rounded,
                ),
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
    }

    testWidgets('displays title, message, and confirm text', (tester) async {
      await pumpDialog(tester);

      expect(find.text('تأكيد الحذف'), findsOneWidget);
      expect(find.text('هل أنت متأكد؟'), findsOneWidget);
      expect(find.text('حذف'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
    });

    testWidgets('returns true when confirm is tapped', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();

      expect(find.text('تأكيد الحذف'), findsNothing);
    });

    testWidgets('returns false when cancel is tapped', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      expect(find.text('تأكيد الحذف'), findsNothing);
    });

    testWidgets('displays the correct icon', (tester) async {
      await pumpDialog(tester);

      expect(find.byIcon(Icons.delete_forever_rounded), findsOneWidget);
    });
  });
}
