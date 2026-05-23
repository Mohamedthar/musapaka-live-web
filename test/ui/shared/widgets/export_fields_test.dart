import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_contest_app/ui/shared/widgets/export_fields.dart';

void main() {
  group('ExportFilterLabel', () {
    testWidgets('displays the label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportFilterLabel(label: 'حالة المستوى'),
          ),
        ),
      );

      expect(find.text('حالة المستوى'), findsOneWidget);
    });
  });

  group('ExportNumberField', () {
    testWidgets('displays hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportNumberField(
              controller: TextEditingController(),
              hintText: 'من عمر',
            ),
          ),
        ),
      );

      expect(find.text('من عمر'), findsOneWidget);
    });

    testWidgets('accepts numeric input', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportNumberField(
              controller: controller,
              hintText: 'من عمر',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '25');
      expect(controller.text, '25');
    });
  });
}
