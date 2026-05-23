import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_contest_app/ui/levels/widgets/levels_filter_bar.dart';

Widget wrapFilterBar(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1920,
        child: child,
      ),
    ),
  );
}

void main() {
  late String currentFilter;
  late String searchText;
  late bool activateCalled;
  late bool deactivateCalled;
  late bool deleteCalled;

  setUp(() {
    currentFilter = 'all';
    searchText = '';
    activateCalled = false;
    deactivateCalled = false;
    deleteCalled = false;
  });

  Widget buildFilter({
    int selectedIdsCount = 0,
    int filteredCount = 5,
  }) {
    return wrapFilterBar(
      LevelsFilterBar(
        currentFilterStatus: currentFilter,
        onStatusChanged: (v) => currentFilter = v,
        onSearchChanged: (v) => searchText = v,
        selectedIdsCount: selectedIdsCount,
        bulkUpdating: false,
        bulkDeleting: false,
        onBulkActivate: () => activateCalled = true,
        onBulkDeactivate: () => deactivateCalled = true,
        onBulkDelete: () => deleteCalled = true,
        filteredCount: filteredCount,
        primaryColor: const Color(0xFF03121C),
      ),
    );
  }

  testWidgets('displays search field and filter dropdown', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(buildFilter());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.text('ابحث عن مستوى...'), findsOneWidget);
  });

  testWidgets('shows bulk action buttons when items selected', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(buildFilter(selectedIdsCount: 3));
    await tester.pumpAndSettle();

    expect(find.text('تنشيط (3)'), findsOneWidget);
    expect(find.text('تعطيل (3)'), findsOneWidget);
    expect(find.text('حذف (3)'), findsOneWidget);
  });

  testWidgets('shows filtered count', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(buildFilter(filteredCount: 8));
    await tester.pumpAndSettle();

    expect(find.text('8'), findsOneWidget);
    expect(find.text('نتائج'), findsOneWidget);
  });

  testWidgets('calls onBulkActivate when activate button tapped', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(buildFilter(selectedIdsCount: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تنشيط (2)'));
    expect(activateCalled, isTrue);
  });

  testWidgets('calls onBulkDeactivate when deactivate button tapped', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(buildFilter(selectedIdsCount: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تعطيل (2)'));
    expect(deactivateCalled, isTrue);
  });

  testWidgets('calls onBulkDelete when delete button tapped', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(buildFilter(selectedIdsCount: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('حذف (2)'));
    expect(deleteCalled, isTrue);
  });

  testWidgets('search field updates onSearchChanged', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(buildFilter());
    await tester.pumpAndSettle();

    final TextField textField = tester.widget(find.byType(TextField));
    textField.onChanged!('مستوى');
    expect(searchText, 'مستوى');
  });
}
