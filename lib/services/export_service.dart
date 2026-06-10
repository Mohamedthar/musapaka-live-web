import 'dart:typed_data';
import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:syncfusion_officechart/officechart.dart' as chart_api;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/student.dart';
import '../data/models/competition_level.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/ranking_utils.dart';
import '../core/utils/filter_utils.dart';
import '../core/utils/app_logger.dart';

class ExportService {
  static const _headerBg = '#03121C';

  Future<Uint8List> studentsToExcel({
    required List<Student> students,
    required List<CompetitionLevel> levels,
    String? levelTitle,
    CompetitionLevel? selectedLevel,
    double? minScore,
    double? maxScore,
  }) async {
    final wb = xlsio.Workbook();
    
    // Sheet 1: Data
    final wsData = wb.worksheets[0];
    wsData.name = 'بيانات المتسابقين';
    wsData.isRightToLeft = true;

    // Sheet 2: Statistics
    final wsStats = wb.worksheets.addWithName('الإحصائيات');
    wsStats.isRightToLeft = true;

    final data = filterStudents(students, level: levelTitle, minScore: minScore, maxScore: maxScore);
    final cols = _buildColumns(selectedLevel, levels);

    // Build Data Sheet
    _addStudentExcelHeader(wsData, cols.length, level: levelTitle, minScore: minScore, maxScore: maxScore);
    _addStudentExcelTableHeaders(wsData, cols);
    _addStudentExcelData(wsData, data, cols);

    // Build Statistics Sheet
    _addStudentExcelSummary(wsStats, data, level: levelTitle);

    final bytes = wb.saveAsStream();
    wb.dispose();
    return Uint8List.fromList(bytes);
  }

  void _addStudentExcelHeader(xlsio.Worksheet ws, int totalCols, {String? level, double? minScore, double? maxScore}) {
    final titleRange = ws.getRangeByIndex(1, 1, 1, totalCols);
    titleRange.merge();
    titleRange.setText('لوحة تحكم المسابقة - تقرير المتسابقين الاحترافي');
    titleRange.cellStyle.fontSize = 20;
    titleRange.cellStyle.bold = true;
    titleRange.cellStyle.fontColor = '#FFFFFF';
    titleRange.cellStyle.backColor = '#001A33';
    titleRange.cellStyle.hAlign = xlsio.HAlignType.center;
    titleRange.cellStyle.vAlign = xlsio.VAlignType.center;
    ws.setRowHeightInPixels(1, 50);

    final subtitleRange = ws.getRangeByIndex(2, 1, 2, totalCols);
    subtitleRange.merge();
    String subtitle = 'المستوى: ${level ?? "الكل"}';
    subtitle += '    |    نطاق الدرجات: ${minScore != null ? AppTheme.formatScore(minScore) : 0} - ${maxScore != null ? AppTheme.formatScore(maxScore) : 100}';
    subtitleRange.setText(subtitle);
    subtitleRange.cellStyle.fontSize = 12;
    subtitleRange.cellStyle.bold = true;
    subtitleRange.cellStyle.fontColor = '#001A33';
    subtitleRange.cellStyle.backColor = '#E3F2FD';
    subtitleRange.cellStyle.hAlign = xlsio.HAlignType.center;
    subtitleRange.cellStyle.vAlign = xlsio.VAlignType.center;
    subtitleRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    subtitleRange.cellStyle.borders.all.color = '#BBDEFB';
    ws.setRowHeightInPixels(2, 35);
  }

  void _addStudentExcelTableHeaders(xlsio.Worksheet ws, List<_ColDef> cols) {
    for (int i = 0; i < cols.length; i++) {
      final cell = ws.getRangeByIndex(3, i + 1);
      cell.setText(cols[i].header);
      cell.cellStyle.bold = true;
      cell.cellStyle.fontColor = '#FFFFFF';
      cell.cellStyle.backColor = '#1976D2';
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
      cell.cellStyle.vAlign = xlsio.VAlignType.center;
      cell.cellStyle.wrapText = true;
      cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      cell.cellStyle.borders.all.color = '#DDDDDD';
      ws.setColumnWidthInPixels(i + 1, cols[i].width.toInt());
    }
    ws.autoFilters.filterRange = ws.getRangeByIndex(3, 1, 3, cols.length);
    ws.setRowHeightInPixels(3, 45);
  }

  String _getColName(int colIndex) {
    String result = '';
    int n = colIndex - 1;
    while (n >= 0) {
      result = String.fromCharCode(65 + (n % 26)) + result;
      n = n ~/ 26 - 1;
    }
    return result;
  }

  void _addStudentExcelData(xlsio.Worksheet ws, List<Student> data, List<_ColDef> cols) {
    int startRow = 4;
    for (int i = 0; i < data.length; i++) {
      final s = data[i];
      final row = startRow + i;

      for (int c = 0; c < cols.length; c++) {
        final val = cols[c].getValue(s);
        final cell = ws.getRangeByIndex(row, c + 1);
        
        if (cols[c].header == 'م') {
          cell.setNumber((i + 1).toDouble());
        } else if (cols[c].isTotalFormula) {
          int scoreStartIdx = cols.indexWhere((col) => col.isScore);
          final startColName = _getColName(scoreStartIdx + 1);
          // c is 0-based; _getColName expects 1-based so this yields the column
          // immediately before the total column (the last score column)
          final lastScoreColName = _getColName(c);
          cell.setFormula('=SUM($startColName$row:$lastScoreColName$row)');
        } else if (cols[c].isScore) {
          if (val is num) {
            cell.setNumber(val.toDouble());
          } else if (val is String) {
            cell.setText(val);
            cell.cellStyle.fontColor = '#9E9E9E'; // Gray color for 'غير مقرر'
          } else {
            cell.setText('-');
          }
        } else {
          if (val is num) {
            cell.setNumber(val.toDouble());
          } else {
            cell.setText(val?.toString() ?? '-');
          }
          if (cols[c].header == 'العنوان') {
            cell.cellStyle.wrapText = true;
          }
        }
      }

      if (i % 2 != 0) {
        ws.getRangeByIndex(row, 1, row, cols.length).cellStyle.backColor = '#F9FBFF';
      }
      final r = ws.getRangeByIndex(row, 1, row, cols.length);
      r.cellStyle.hAlign = xlsio.HAlignType.center;
      r.cellStyle.vAlign = xlsio.VAlignType.center;
      r.cellStyle.fontSize = 10;
      r.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      r.cellStyle.borders.all.color = '#E0E0E0';
    }

    final totalRow = startRow + data.length;
    ws.getRangeByIndex(totalRow, 1, totalRow, 3).merge();
    ws.getRangeByIndex(totalRow, 1).setText('إجمالي العدد: ${data.length}');
    ws.getRangeByIndex(totalRow, 1).cellStyle.bold = true;
    ws.getRangeByIndex(totalRow, 1).cellStyle.backColor = '#EEEEEE';
    ws.setRowHeightInPixels(totalRow, 30);

    ws.getRangeByIndex(5, 1).freezePanes();
  }

  void _addStudentExcelSummary(xlsio.Worksheet ws, List<Student> data, {String? level}) {
    // Worksheet Title
    final titleRange = ws.getRangeByIndex(1, 1, 1, 16);
    titleRange.merge();
    titleRange.setText('لوحة الإحصائيات التحليلية ${level != null ? "- $level" : ""}');
    titleRange.cellStyle.fontSize = 20;
    titleRange.cellStyle.bold = true;
    titleRange.cellStyle.fontColor = '#FFFFFF';
    titleRange.cellStyle.backColor = '#001A33';
    titleRange.cellStyle.hAlign = xlsio.HAlignType.center;
    titleRange.cellStyle.vAlign = xlsio.VAlignType.center;
    ws.setRowHeightInPixels(1, 50);

    const int startRow = 3;
    
    // 1. Gender Grid
    final males = data.where((s) => s.gender == 'ذكر' || s.gender == 'Male').length;
    final females = data.where((s) => s.gender == 'أنثى' || s.gender == 'Female').length;
    _addStatBox(ws, startRow, 1, 3, 'النوع', 'ذكر: $males | أنثى: $females', '#F3E5F5', '#7B1FA2');

    // 2. Performance Grid
    double avg = 0;
    double max = 0;
    if (data.isNotEmpty) {
      avg = data.map((s) => s.totalScore ?? 0).reduce((a, b) => a + b) / data.length;
      max = data.map((s) => s.totalScore ?? 0).reduce((a, b) => a > b ? a : b);
    }
    _addStatBox(ws, startRow, 4, 7, 'النتائج الكلية', 'المتوسط: ${avg.toStringAsFixed(1)} | الأعلى: $max', '#E3F2FD', '#1976D2');

    // 3. Age Grid
    double avgAge = 0;
    int minAge = 0;
    int maxAge = 0;
    if (data.isNotEmpty) {
      avgAge = data.map((s) => s.age).reduce((a, b) => a + b) / data.length;
      minAge = data.map((s) => s.age).reduce((a, b) => a < b ? a : b);
      maxAge = data.map((s) => s.age).reduce((a, b) => a > b ? a : b);
    }
    _addStatBox(ws, startRow, 8, 11, 'الأعمار', 'المتوسط: ${avgAge.toStringAsFixed(1)} | الأصغر: $minAge | الأكبر: $maxAge', '#FFF8E1', '#F57F17');

    ws.setRowHeightInPixels(startRow, 40);

    // Add Charts (Premium Detail)
    int chartDataRow = 30; // Hidden data below the charts
    
    // Gender Data
    ws.getRangeByIndex(chartDataRow + 4, 1).setText('ذكر');
    ws.getRangeByIndex(chartDataRow + 4, 2).setNumber(males.toDouble());
    ws.getRangeByIndex(chartDataRow + 5, 1).setText('أنثى');
    ws.getRangeByIndex(chartDataRow + 5, 2).setNumber(females.toDouble());

    final chart_api.ChartCollection charts = chart_api.ChartCollection(ws);
    
    final chart_api.Chart genderChart = charts.add();
    genderChart.chartType = chart_api.ExcelChartType.pie;
    genderChart.dataRange = ws.getRangeByIndex(chartDataRow + 4, 1, chartDataRow + 5, 2);
    genderChart.isSeriesInRows = false;
    genderChart.chartTitle = 'توزيع النوع';
    genderChart.topRow = 5;
    genderChart.bottomRow = 20;
    genderChart.leftColumn = 8;
    genderChart.rightColumn = 12;

    ws.charts = charts;
  }

  void _addStatBox(xlsio.Worksheet ws, int row, int startCol, int endCol, String title, String value, String bgColor, String textColor) {
    final range = ws.getRangeByIndex(row, startCol, row, endCol);
    range.merge();
    range.setText('$title: $value');
    range.cellStyle.backColor = bgColor;
    range.cellStyle.fontColor = textColor;
    range.cellStyle.bold = true;
    range.cellStyle.fontSize = 9;
    range.cellStyle.hAlign = xlsio.HAlignType.center;
    range.cellStyle.vAlign = xlsio.VAlignType.center;
    range.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    range.cellStyle.borders.all.color = textColor;
  }

  String _pdfScoreLabel(Student s, List<CompetitionLevel> levels) {
    if (s.score == null) return '-';
    
    final lvl = CompetitionLevel.findByTitle(levels, s.level);
    if (lvl == null) return AppTheme.formatScore(s.score!);
    
    final hasExtra = lvl.hasRewaya || lvl.hasTajweed || lvl.hasVoice || lvl.hasMeaning;
    if (!hasExtra) return AppTheme.formatScore(s.score!);
    
    final total = s.totalScore ?? 0.0;
    final maxPoints = lvl.totalMaxPoints;
    
    final row1 = <String>[];
    final row2 = <String>[];
    
    row1.add('حفظ: ${AppTheme.formatScore(s.score!)}');
    if (lvl.hasRewaya) {
      row1.add('رواية: ${s.rewayaScore != null ? AppTheme.formatScore(s.rewayaScore!) : '0'}');
    }
    if (lvl.hasTajweed) {
      row1.add('تجويد: ${s.tajweedScore != null ? AppTheme.formatScore(s.tajweedScore!) : '0'}');
    }
    if (lvl.hasVoice) {
      row2.add('صوت: ${s.voiceScore != null ? AppTheme.formatScore(s.voiceScore!) : '0'}');
    }
    if (lvl.hasMeaning) {
      row2.add('معاني: ${s.meaningScore != null ? AppTheme.formatScore(s.meaningScore!) : '0'}');
    }
    
    if (row2.isEmpty) {
      return '${AppTheme.formatScore(total)}/$maxPoints\n(${row1.join(' | ')})';
    } else {
      return '${AppTheme.formatScore(total)}/$maxPoints\n(${row1.join(' | ')})\n(${row2.join(' | ')})';
    }
  }

  Future<Uint8List> studentsToPDF({
    required List<Student> students,
    required List<CompetitionLevel> levels,
    String? level,
    double? minScore,
    double? maxScore,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    final data = filterStudents(students, level: level, minScore: minScore, maxScore: maxScore);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4, 
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          margin: const pw.EdgeInsets.only(bottom: 15),
          padding: const pw.EdgeInsets.only(bottom: 5),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('مسابقة القرآن الكريم - تقرير مخصص للطباعة المباشرة', style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.grey600)),
              pw.Text(DateTime.now().toString().split(' ')[0], style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ),
        build: (context) => [
          pw.Center(
            child: pw.Text('كشف أسماء المتسابقين والدرجات الكلية', style: pw.TextStyle(font: arabicFontBold, fontSize: 20, color: PdfColors.blue900)),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'المستوى: ${level ?? "الكل"} | نطاق الدرجات: ${minScore != null ? AppTheme.formatScore(minScore) : 0} - ${maxScore != null ? AppTheme.formatScore(maxScore) : 100}',
              style: pw.TextStyle(font: arabicFont, fontSize: 10.5, color: PdfColors.grey700),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            child: pw.TableHelper.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              headerStyle: pw.TextStyle(font: arabicFontBold, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: pw.TextStyle(font: arabicFont, fontSize: 9),
              cellAlignment: pw.Alignment.center,
              headerAlignment: pw.Alignment.center,
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.3), // الدرجة والتفاصيل
                1: const pw.FlexColumnWidth(1.1), // رقم الهاتف
                2: const pw.FlexColumnWidth(0.7), // السن
                3: const pw.FlexColumnWidth(1.5), // المستوى
                4: const pw.FlexColumnWidth(2.0), // اسم المتسابق
                5: const pw.FlexColumnWidth(1.3), // كود الطالب
                6: const pw.FlexColumnWidth(0.4), // م
              },
              headers: ['الدرجة الكلية والتفاصيل', 'رقم الهاتف', 'السن', 'المستوى', 'اسم المتسابق', 'كود الطالب', 'م'],
              data: List.generate(data.length, (i) {
                final s = data[i];
                return [
                  _pdfScoreLabel(s, levels),
                  s.phone,
                  s.age.toString(),
                  s.level,
                  s.name,
                  s.studentCode ?? '-',
                  (i + 1).toString(),
                ];
              }),
            ),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: pw.TextStyle(font: arabicFont, fontSize: 10, color: PdfColors.grey600)),
        ),
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> levelsToExcel({
    required List<CompetitionLevel> levels,
    required List<Student> allStudents,
    String status = 'all',
    int? minAge,
    int? maxAge,
  }) async {
    final wb = xlsio.Workbook();
    final ws = wb.worksheets[0];
    ws.name = 'المستويات';
    ws.isRightToLeft = true;

    final data = filterLevels(levels, status: status, minAge: minAge, maxAge: maxAge);

    final title = ws.getRangeByIndex(1, 1, 1, 8);
    title.merge();
    title.setText('تقرير مستويات المسابقة');
    title.cellStyle.fontSize = 16;
    title.cellStyle.bold = true;
    title.cellStyle.hAlign = xlsio.HAlignType.center;
    title.cellStyle.backColor = _headerBg;
    title.cellStyle.fontColor = '#FFFFFF';
    ws.setRowHeightInPixels(1, 38);

    final headers = ['المستوى', 'المحتوى', 'الملاحظات', 'السن الأدنى', 'السن الأقصى', 'السعة', 'المسجلين', 'الحالة'];
    for (int c = 0; c < headers.length; c++) {
      final cell = ws.getRangeByIndex(2, c + 1);
      cell.setText(headers[c]);
      cell.cellStyle.backColor = '#1565C0';
      cell.cellStyle.fontColor = '#FFFFFF';
      cell.cellStyle.bold = true;
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
      cell.cellStyle.vAlign = xlsio.VAlignType.center;
    }
    ws.setRowHeightInPixels(2, 28);

    ws.setColumnWidthInPixels(1, 140);
    ws.setColumnWidthInPixels(2, 320);
    ws.setColumnWidthInPixels(3, 200);
    ws.setColumnWidthInPixels(4, 80);
    ws.setColumnWidthInPixels(5, 80);
    ws.setColumnWidthInPixels(6, 80);
    ws.setColumnWidthInPixels(7, 80);
    ws.setColumnWidthInPixels(8, 90);

    for (int i = 0; i < data.length; i++) {
      final l = data[i];
      final row = i + 3;
      final count = allStudents.where((s) => s.level == l.title).length;
      ws.getRangeByIndex(row, 1).setText(l.title);
      ws.getRangeByIndex(row, 2).setText(l.content);
      ws.getRangeByIndex(row, 3).setText(l.notes ?? '-');
      if (l.minAge != null) ws.getRangeByIndex(row, 4).setNumber(l.minAge!.toDouble());
      if (l.maxAge != null) ws.getRangeByIndex(row, 5).setNumber(l.maxAge!.toDouble());
      if (l.maxCapacity != null) ws.getRangeByIndex(row, 6).setNumber(l.maxCapacity!.toDouble());
      ws.getRangeByIndex(row, 7).setNumber(count.toDouble());
      ws.getRangeByIndex(row, 8).setText(l.isActive ? 'نشط' : 'معطل');

      final r = ws.getRangeByIndex(row, 1, row, 8);
      r.cellStyle.hAlign = xlsio.HAlignType.center;
      r.cellStyle.vAlign = xlsio.VAlignType.center;
      r.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      r.cellStyle.borders.all.color = '#DDDDDD';
      if (i % 2 != 0) r.cellStyle.backColor = '#F8F9FB';
    }

    final bytes = wb.saveAsStream();
    wb.dispose();
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> levelsToPDF({
    required List<CompetitionLevel> levels,
    required List<Student> allStudents,
    String status = 'all',
    int? minAge,
    int? maxAge,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final now = DateTime.now().toString().split(' ')[0];

    final data = filterLevels(levels, status: status, minAge: minAge, maxAge: maxAge);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      header: (ctx) => pw.Column(children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('تقرير مستويات المسابقة', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue900)),
          pw.Text(now, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
        ]),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 1, color: PdfColors.blue900),
      ]),
      footer: (ctx) => pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text('صفحة ${ctx.pageNumber}', style: const pw.TextStyle(fontSize: 9))),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['المستوى', 'المحتوى', 'العمر', 'السعة', 'الطلاب', 'الحالة'],
          data: data.map((l) {
            final count = allStudents.where((s) => s.level == l.title).length;
            String age = l.ageDescription;
            return [l.title, l.content, age, l.maxCapacity?.toString() ?? '∞', '$count', l.isActive ? 'نشط' : 'معطل'];
          }).toList(),
          headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          cellAlignment: pw.Alignment.center,
          cellStyle: pw.TextStyle(font: font, fontSize: 9),
          cellPadding: const pw.EdgeInsets.all(8),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.2),
            1: const pw.FlexColumnWidth(3.0),
            2: const pw.FlexColumnWidth(0.8),
            3: const pw.FlexColumnWidth(0.6),
            4: const pw.FlexColumnWidth(0.6),
            5: const pw.FlexColumnWidth(0.7),
          },
        ),
      ],
    ));
    return pdf.save();
  }

  static const String _exportDirKey = 'export_directory_path';

  static Future<String?> getExportDir() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_exportDirKey);
  }

  static Future<void> setExportDir(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exportDirKey, path);
    final d = Directory(path);
    if (!await d.exists()) await d.create(recursive: true);
  }

  Future<String?> saveFile(Uint8List bytes, String fileName, String extension, {String? directory}) async {
    try {
      if (directory != null) {
        final d = Directory(directory);
        if (!await d.exists()) await d.create(recursive: true);
        final file = File('${d.path}\\$fileName');
        await file.writeAsBytes(bytes);
        return file.path;
      }
      final path = await FilePicker.saveFile(
        dialogTitle: 'Export File',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [extension],
        bytes: bytes,
      );
      return path;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save file: $fileName', error: e, stack: stackTrace);
      return null;
    }
  }

  Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  List<_ColDef> _buildColumns(CompetitionLevel? selectedLevel, List<CompetitionLevel> levels) {
    final cols = <_ColDef>[
      _ColDef('م', 40, false, (s) => ''),
      _ColDef('كود الطالب', 75, false, (s) => s.studentCode ?? '-'),
      _ColDef('اسم المتسابق', 180, false, (s) => s.name),
      _ColDef('النوع', 50, false, (s) => s.gender ?? 'ذكر'),
      _ColDef('تاريخ الميلاد', 85, false, (s) => s.birthDate != null ? s.birthDate!.toIso8601String().split('T')[0] : '-'),
      _ColDef('العمر', 45, false, (s) => s.age),
      _ColDef('الرقم القومي', 115, false, (s) => s.nationalId ?? '-'),
      _ColDef('المستوى', 120, false, (s) => s.level),
      _ColDef('رقم الهاتف', 95, false, (s) => s.phone),
      _ColDef('اسم المحفظ', 130, false, (s) => s.memorizerName ?? '-'),
      _ColDef('العنوان', 150, false, (s) => s.location ?? '-'),
    ];

    String memHeader = 'درجة الحفظ';
    if (selectedLevel != null) memHeader += '\n(${selectedLevel.totalPoints ?? 100})';
    cols.add(_ColDef(memHeader, 85, true, (s) => s.score));

    if (selectedLevel == null || selectedLevel.hasRewaya) {
      String h = 'درجة الرواية';
      if (selectedLevel != null) h += '\n(${selectedLevel.rewayaMaxScore})';
      cols.add(_ColDef(h, 85, true, (s) {
        final lvl = CompetitionLevel.findByTitle(levels, s.level);
        if (lvl != null && !lvl.hasRewaya) return 'غير مقرر';
        return s.rewayaScore;
      }));
    }

    if (selectedLevel == null || selectedLevel.hasTajweed) {
      String h = 'درجة التجويد';
      if (selectedLevel != null) h += '\n(${selectedLevel.tajweedMaxScore})';
      cols.add(_ColDef(h, 85, true, (s) {
        final lvl = CompetitionLevel.findByTitle(levels, s.level);
        if (lvl != null && !lvl.hasTajweed) return 'غير مقرر';
        return s.tajweedScore;
      }));
    }

    if (selectedLevel == null || selectedLevel.hasVoice) {
      String h = 'درجة الصوت\nوالتأثير';
      if (selectedLevel != null) h += '\n(${selectedLevel.voiceMaxScore})';
      cols.add(_ColDef(h, 85, true, (s) {
        final lvl = CompetitionLevel.findByTitle(levels, s.level);
        if (lvl != null && !lvl.hasVoice) return 'غير مقرر';
        return s.voiceScore;
      }));
    }

    if (selectedLevel == null || selectedLevel.hasMeaning) {
      String h = 'درجة فهم\nالمعاني والوقف';
      if (selectedLevel != null) h += '\n(${selectedLevel.meaningMaxScore})';
      cols.add(_ColDef(h, 95, true, (s) {
        final lvl = CompetitionLevel.findByTitle(levels, s.level);
        if (lvl != null && !lvl.hasMeaning) return 'غير مقرر';
        return s.meaningScore;
      }));
    }

    String totHeader = 'الدرجة الكلية';
    if (selectedLevel != null) totHeader += '\n(${selectedLevel.totalMaxPoints})';
    cols.add(_ColDef(totHeader, 85, true, (s) => s.totalScore, isTotalFormula: true));

    cols.add(_ColDef('النهاية الكبرى للمستوى', 115, false, (s) {
      final lvl = CompetitionLevel.findByTitle(levels, s.level);
      return lvl?.totalMaxPoints ?? 100;
    }));

    cols.add(_ColDef('النسبة المئوية', 85, false, (s) {
      final lvl = CompetitionLevel.findByTitle(levels, s.level);
      final maxPts = lvl?.totalMaxPoints ?? 100;
      final total = s.totalScore ?? 0.0;
      final pct = total / maxPts;
      return '${(pct * 100).toStringAsFixed(1)}%';
    }));

    return cols;
  }

  Future<void> exportRankingsToExcel(CompetitionLevel level, List<RankedStudent> rankedStudents) async {
    final wb = xlsio.Workbook();
    final ws = wb.worksheets[0];
    ws.name = 'نتائج ومراكز ${level.title}';
    ws.isRightToLeft = true;

    // Add Stats sheet
    final wsStats = wb.worksheets.addWithName('الإحصائيات العامة');
    wsStats.isRightToLeft = true;

    final title = ws.getRangeByIndex(1, 1, 1, 9);
    title.merge();
    title.setText('لوحة الشرف وتصنيف المتسابقين - ${level.title}');
    title.cellStyle.fontSize = 18;
    title.cellStyle.bold = true;
    title.cellStyle.hAlign = xlsio.HAlignType.center;
    title.cellStyle.vAlign = xlsio.VAlignType.center;
    title.cellStyle.backColor = _headerBg;
    title.cellStyle.fontColor = '#FFFFFF';
    ws.setRowHeightInPixels(1, 45);

    final headers = ['الترتيب', 'المركز', 'الاسم', 'الرقم القومي', 'رقم الهاتف', 'الدرجة', 'النسبة المئوية', 'الحالة', 'التفاصيل'];
    for (int c = 0; c < headers.length; c++) {
      final cell = ws.getRangeByIndex(2, c + 1);
      cell.setText(headers[c]);
      cell.cellStyle.backColor = '#1565C0';
      cell.cellStyle.fontColor = '#FFFFFF';
      cell.cellStyle.bold = true;
      cell.cellStyle.fontSize = 12;
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
      cell.cellStyle.vAlign = xlsio.VAlignType.center;
      cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      cell.cellStyle.borders.all.color = '#DDDDDD';
    }
    ws.setRowHeightInPixels(2, 35);
    ws.getRangeByIndex(3, 1).freezePanes();

    ws.setColumnWidthInPixels(1, 60);
    ws.setColumnWidthInPixels(2, 120);
    ws.setColumnWidthInPixels(3, 200);
    ws.setColumnWidthInPixels(4, 120);
    ws.setColumnWidthInPixels(5, 120);
    ws.setColumnWidthInPixels(6, 80);
    ws.setColumnWidthInPixels(7, 100);
    ws.setColumnWidthInPixels(8, 80);
    ws.setColumnWidthInPixels(9, 250);

    for (int i = 0; i < rankedStudents.length; i++) {
      final rs = rankedStudents[i];
      final s = rs.student;
      final row = i + 3;
      final total = s.totalScore ?? 0.0;
      final maxPoints = level.totalMaxPoints;
      final pct = maxPoints > 0 ? (total / maxPoints * 100) : 0.0;
      final isPassed = pct >= 50;

      final row1 = <String>[];
      row1.add('حفظ: ${s.score != null ? AppTheme.formatScore(s.score!) : '-'}');
      if (level.hasRewaya) row1.add('رواية: ${s.rewayaScore != null ? AppTheme.formatScore(s.rewayaScore!) : '-'}');
      if (level.hasTajweed) row1.add('تجويد: ${s.tajweedScore != null ? AppTheme.formatScore(s.tajweedScore!) : '-'}');
      if (level.hasVoice) row1.add('صوت: ${s.voiceScore != null ? AppTheme.formatScore(s.voiceScore!) : '-'}');
      if (level.hasMeaning) row1.add('معاني: ${s.meaningScore != null ? AppTheme.formatScore(s.meaningScore!) : '-'}');

      ws.getRangeByIndex(row, 1).setNumber((i + 1).toDouble());
      ws.getRangeByIndex(row, 2).setText(rs.rankTitle);
      ws.getRangeByIndex(row, 3).setText(s.name);
      ws.getRangeByIndex(row, 4).setText(s.nationalId ?? '-');
      ws.getRangeByIndex(row, 5).setText(s.phone);
      ws.getRangeByIndex(row, 6).setNumber(total);
      ws.getRangeByIndex(row, 7).setText('${pct.toStringAsFixed(1)}%');
      
      final statusCell = ws.getRangeByIndex(row, 8);
      statusCell.setText(isPassed ? 'ناجح' : 'راسب');
      statusCell.cellStyle.fontColor = isPassed ? '#2E7D32' : '#C62828';
      statusCell.cellStyle.bold = true;

      final detailsCell = ws.getRangeByIndex(row, 9);
      detailsCell.setText(row1.join(' | '));
      detailsCell.cellStyle.wrapText = true;
      
      final rRange = ws.getRangeByIndex(row, 1, row, 9);
      rRange.cellStyle.hAlign = xlsio.HAlignType.center;
      rRange.cellStyle.vAlign = xlsio.VAlignType.center;
      rRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      if (i % 2 != 0) rRange.cellStyle.backColor = '#F8F9FB';
    }

    final students = rankedStudents.map((e) => e.student).toList();
    _addStudentExcelSummary(wsStats, students, level: level.title);

    final bytes = wb.saveAsStream();
    wb.dispose();

    await saveFile(Uint8List.fromList(bytes), 'Rankings_${level.title}.xlsx', 'xlsx');
  }
}

class _ColDef {
  final String header;
  final double width;
  final bool isScore;
  final bool isTotalFormula;
  final dynamic Function(Student) getValue;
  _ColDef(this.header, this.width, this.isScore, this.getValue, {this.isTotalFormula = false});
}
