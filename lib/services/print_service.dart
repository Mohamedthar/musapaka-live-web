import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models/student.dart';
import '../data/models/competition_level.dart';
import '../data/models/exam_schedule_slot.dart';
import '../services/supabase_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

class PrintService {
  static final Map<String, pw.ImageProvider> _imageCache = {};
  static const int _maxCacheSize = 50;
  static final List<String> _cacheOrder = [];

  static void _addToCache(String url, pw.ImageProvider image) {
    if (_imageCache.containsKey(url)) {
      _cacheOrder.remove(url);
    } else if (_imageCache.length >= _maxCacheSize) {
      final oldest = _cacheOrder.removeAt(0);
      _imageCache.remove(oldest);
    }
    _imageCache[url] = image;
    _cacheOrder.add(url);
  }

  Future<void> printStudentCard(Student s, List<CompetitionLevel> levels) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    pw.ImageProvider? profileImage = await _fetchImage(s.profileImageUrl);
    pw.ImageProvider? logoImage = await _loadLogoAsset();
    List<CompetitionLevel> freshLevels = await _fetchLevels(levels);
    CompetitionLevel levelData = _matchLevel(s.level, freshLevels);

    pdf.addPage(_buildStudentPage(s, levelData, profileImage, arabicFont, arabicFontBold, logoImage: logoImage));
    pdf.addPage(_buildEvaluationPage(s, levelData, profileImage, arabicFont, arabicFontBold, logoImage: logoImage));

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${s.name}_${s.studentCode ?? s.id}.pdf',
    );
  }

  Future<void> printMultipleStudentCards(List<Student> students, List<CompetitionLevel> levels) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();
    
    pw.ImageProvider? logoImage = await _loadLogoAsset();
    List<CompetitionLevel> freshLevels = await _fetchLevels(levels);

    for (final s in students) {
      pw.ImageProvider? profileImage = await _fetchImage(s.profileImageUrl);
      CompetitionLevel levelData = _matchLevel(s.level, freshLevels);
      pdf.addPage(_buildStudentPage(s, levelData, profileImage, arabicFont, arabicFontBold, logoImage: logoImage));
      pdf.addPage(_buildEvaluationPage(s, levelData, profileImage, arabicFont, arabicFontBold, logoImage: logoImage));
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'طباعة_جماعية_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<String> saveStudentCardsToDownloads(List<Student> students, List<CompetitionLevel> levels) async {
    Directory? downloadsDir;
    if (Platform.isWindows) {
      downloadsDir = Directory(p.join(Platform.environment['USERPROFILE']!, 'Downloads'));
    } else if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) downloadsDir = await getExternalStorageDirectory();
    } else {
      downloadsDir = await getDownloadsDirectory();
    }
    
    if (downloadsDir == null) throw Exception('تعذر الوصول لمجلد التحميلات');

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final baseDir = Directory(p.join(downloadsDir.path, 'طلاب المسابقة'));
    final targetDir = Directory(p.join(baseDir.path, today));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();
    pw.ImageProvider? logoImage = await _loadLogoAsset();
    List<CompetitionLevel> freshLevels = await _fetchLevels(levels);

    for (final s in students) {
      final pdf = pw.Document();
      pw.ImageProvider? profileImage = await _fetchImage(s.profileImageUrl);
      CompetitionLevel levelData = _matchLevel(s.level, freshLevels);
      
      pdf.addPage(_buildStudentPage(s, levelData, profileImage, arabicFont, arabicFontBold, logoImage: logoImage));
      pdf.addPage(_buildEvaluationPage(s, levelData, profileImage, arabicFont, arabicFontBold, logoImage: logoImage));

      final fileName = '${s.name}_${s.studentCode ?? s.id}.pdf'.replaceAll(' ', '_');
      final file = File(p.join(targetDir.path, fileName));
      await file.writeAsBytes(await pdf.save());
    }

    return targetDir.path;
  }

  Future<pw.ImageProvider?> _loadLogoAsset() async {
    try {
      final data = await rootBundle.load('assets/images/logo_musapaka.jpeg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<pw.ImageProvider?> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    if (_imageCache.containsKey(url)) return _imageCache[url];
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: { 'User-Agent': 'Mozilla/5.0', 'Accept': 'image/*' },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final image = pw.MemoryImage(response.bodyBytes);
        _addToCache(url, image);
        return image;
      } else if (response.statusCode == 404) {
        final cleanedUrl = url.replaceAll(' ', '%20');
        if (cleanedUrl != url) {
          final retryResponse = await http.get(Uri.parse(cleanedUrl)).timeout(const Duration(seconds: 10));
          if (retryResponse.statusCode == 200) {
            final image = pw.MemoryImage(retryResponse.bodyBytes);
            _addToCache(cleanedUrl, image);
            return image;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<CompetitionLevel>> _fetchLevels(List<CompetitionLevel> defaultLevels) async {
    try {
      final service = SupabaseService();
      return await service.getLevels();
    } catch (_) {
      return defaultLevels;
    }
  }

  CompetitionLevel _matchLevel(String levelName, List<CompetitionLevel> levels) {
    String normalizeArabic(String text) {
      return text.replaceAll('ي', 'ى').replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه').trim();
    }
    
    String displayLevel = levelName;
    if (displayLevel.contains('المستو') && !displayLevel.contains('المستوى')) {
      displayLevel = displayLevel.replaceAll('المستو', 'المستوى');
    }

    final normalized = normalizeArabic(levelName);
    try {
      return levels.firstWhere((l) => normalizeArabic(l.title) == normalized);
    } catch (_) {
      try {
        return levels.firstWhere((l) => normalizeArabic(l.title).contains(normalized) || normalized.contains(normalizeArabic(l.title)));
      } catch (_) {
        return CompetitionLevel(title: displayLevel, content: 'محتوى الاختبار غير متوفر حالياً');
      }
    }
  }

  pw.Page _buildStudentPage(Student s, CompetitionLevel levelData, pw.ImageProvider? profileImage, pw.Font arabicFont, pw.Font arabicFontBold, {pw.ImageProvider? logoImage}) {
    const String svgUser = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>';
    const String svgLayers = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M11.99 18.54l-7.37-5.73L3 14.07l9 7 9-7-1.63-1.27-7.38 5.74zM12 16l7.36-5.73L21 9l-9-7-9 7 1.63 1.27L12 16z"/></svg>';
    const String svgCalendar = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11z"/></svg>';
    const String svgPhone = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M20.01 15.38c-1.23 0-2.42-.2-3.53-.56-.35-.12-.74-.03-1.01.24l-1.57 1.97c-2.83-1.35-5.48-3.9-6.89-6.83l1.95-1.66c.27-.28.35-.67.24-1.02-.37-1.11-.56-2.3-.56-3.53 0-.54-.45-.99-.99-.99H4.19C3.65 3 3 3.24 3 3.99 3 13.28 10.73 21 20.03 21c.75 0 .99-.65.99-1.19v-3.44c0-.54-.45-.99-.99-.99z"/></svg>';
    const String svgIdCard = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M2 7v10c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2H4c-1.1 0-2 .9-2 2zm18 10H4V7h16v10zm-9-4.5c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zM15 15h-8v-1c0-1.33 2.67-2 4-2s4 .67 4 2v1z"/></svg>';
    const String svgList = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M3 13h2v-2H3v2zm0 4h2v-2H3v2zm0-8h2V7H3v2zm4 4h14v-2H7v2zm0 4h14v-2H7v2zM7 7v2h14V7H7z"/></svg>';
    const String svgWarning = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    const String svgLocation = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>';
    const String svgBook = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M21 5c-1.11-.35-2.33-.5-3.5-.5-1.95 0-4.05.4-5.5 1.5-1.45-1.1-3.55-1.5-5.5-1.5S2.45 4.9 1 6v14.65c0 .25.25.5.5.5.1 0 .15-.05.25-.05C3.1 20.45 5.05 20 6.5 20c1.95 0 4.05.4 5.5 1.5 1.35-.85 3.8-1.5 5.5-1.5 1.65 0 3.35.3 4.75 1.05.1.05.15.05.25.05.25 0 .5-.25.5-.5V6c-.6-.45-1.25-.75-2-1zM21 18.5c-1.1-.35-2.3-.5-3.5-.5-1.7 0-4.15.65-5.5 1.5V8c1.35-.85 3.8-1.5 5.5-1.5 1.2 0 2.4.15 3.5.5v11.5z"/></svg>';

    final blueDark = PdfColor.fromHex('#0f172a');
    final blueLight = PdfColor.fromHex('#1e293b');
    final gold = PdfColor.fromHex('#b45309');
    final goldLight = PdfColor.fromHex('#f59e0b');
    final faintGray = PdfColor.fromHex('#f8fafc');

    String displayLevel = s.level;
    if (displayLevel.contains('المستو') && !displayLevel.contains('المستوى')) displayLevel = displayLevel.replaceAll('المستو', 'المستوى');

    String getArabicDay(int weekday) {
      switch (weekday) {
        case 1: return 'الإثنين';
        case 2: return 'الثلاثاء';
        case 3: return 'الأربعاء';
        case 4: return 'الخميس';
        case 5: return 'الجمعة';
        case 6: return 'السبت';
        case 7: return 'الأحد';
        default: return '';
      }
    }

    String examDateStr = 'لم يتم التحديد';
    if (s.examDate != null && s.examHour != null) {
      final String dayName = getArabicDay(s.examDate!.weekday);
      final String dateOnly = s.examDate!.toIso8601String().split('T')[0];
      final String timeStr = ExamScheduleSlot.hourCaptionAr(s.examHour!);
      examDateStr = 'يوم $dayName الموافق $dateOnly - الساعة $timeStr';
    }

    pw.Widget buildIconRow(String label, String value, String svg, {PdfColor? bgColor, PdfColor? textColor}) {
      return pw.Container(
        padding: bgColor != null ? const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4) : const pw.EdgeInsets.all(0),
        decoration: bgColor != null ? pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColors.blue100, width: 0.5),
        ) : null,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(color: blueLight, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
              child: pw.SvgImage(svg: svg, width: 12, height: 12, colorFilter: PdfColors.white),
            ),
            pw.SizedBox(width: 8),
            pw.Text(label, style: pw.TextStyle(font: arabicFont, fontSize: 11, color: textColor ?? blueDark)),
            pw.SizedBox(width: 4),
            pw.Text(':', style: pw.TextStyle(font: arabicFont, fontSize: 11, color: textColor ?? blueDark)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.Text(value, style: pw.TextStyle(font: arabicFontBold, fontSize: 12, color: textColor ?? blueDark), textAlign: pw.TextAlign.right)),
          ]
        )
      );
    }

    pw.Widget buildGridCell(String label, String value, String svg) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(color: blueLight, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.SvgImage(svg: svg, width: 10, height: 10, colorFilter: PdfColors.white),
            ),
            pw.SizedBox(width: 6),
            pw.Text(label, style: pw.TextStyle(font: arabicFont, fontSize: 9, color: blueDark)),
            pw.SizedBox(width: 4),
            pw.Text(':', style: pw.TextStyle(font: arabicFont, fontSize: 9, color: blueDark)),
            pw.SizedBox(width: 4),
            pw.Expanded(child: pw.Text(value, style: pw.TextStyle(font: arabicFontBold, fontSize: 10, color: blueDark), textAlign: pw.TextAlign.right)),
          ]
        )
      );
    }

    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),

      ),
      build: (pw.Context context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 12),
                margin: const pw.EdgeInsets.only(top: 36, left: 24, right: 24),
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#e2e8f0'), width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('مسابقة أهل القرآن الكبرى', style: pw.TextStyle(color: blueDark, fontSize: 20, font: arabicFontBold)),
                          pw.SizedBox(height: 6),
                          pw.Text('مقر اللجنة: مركز فاقوس - قرية الديدمون - شارع الشيخ - منزل المشرف العام', style: pw.TextStyle(color: gold, fontSize: 13, font: arabicFontBold)),
                        ]
                      )
                    ),
                    pw.SizedBox(width: 16),
                    logoImage != null
                        ? pw.Container(
                            width: 70, height: 70,
                            decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle),
                            child: pw.ClipOval(
                              child: pw.Image(logoImage, width: 70, height: 70, fit: pw.BoxFit.cover),
                            ),
                          )
                        : pw.SvgImage(svg: svgBook, width: 36, height: 36, colorFilter: gold),
                  ]
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: pw.Column(
                  children: [
                    // Basic Info Card
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        border: pw.Border.all(color: PdfColor.fromHex('#e2e8f0'), width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              children: [
                                buildIconRow('الاسم', s.name, svgUser),
                                pw.SizedBox(height: 8),
                                buildIconRow('المستوى', '$displayLevel - ${levelData.content}', svgLayers),
                                pw.SizedBox(height: 8),
                                buildIconRow('موعد الامتحان', examDateStr, svgCalendar, textColor: PdfColor.fromHex('#1e40af')),
                                pw.SizedBox(height: 8),
                                buildIconRow('العمر', '${s.age} سنة', svgUser),
                              ]
                            )
                          ),
                          pw.SizedBox(width: 20),
                          pw.Column(
                            children: [
                              pw.Container(
                                width: 90, height: 90,
                                decoration: pw.BoxDecoration(
                                  shape: pw.BoxShape.circle,
                                  border: pw.Border.all(color: goldLight, width: 2.5),
                                ),
                                child: pw.ClipOval(
                                  child: profileImage != null ? pw.Image(profileImage, fit: pw.BoxFit.cover) : pw.Center(child: pw.SvgImage(svg: svgUser, width: 45, height: 45, colorFilter: PdfColors.grey)),
                                )
                              ),
                              pw.SizedBox(height: 10),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.grey200,
                                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
                                ),
                                child: pw.Row(
                                  mainAxisSize: pw.MainAxisSize.min,
                                  children: [
                                    pw.Text(s.studentCode ?? s.nationalId ?? '', style: pw.TextStyle(font: arabicFontBold, fontSize: 11, color: blueDark)),
                                    pw.SizedBox(width: 4),
                                    pw.SvgImage(svg: svgUser, width: 10, height: 10, colorFilter: blueDark),
                                  ]
                                )
                              )
                            ]
                          )
                        ]
                      )
                    ),
                    pw.SizedBox(height: 14),

                    // Detailed Info Grid
                    pw.Stack(
                      alignment: pw.Alignment.topCenter,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 12),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            border: pw.Border.all(color: PdfColor.fromHex('#e2e8f0'), width: 1),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                          ),
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 16, bottom: 6, left: 6, right: 6),
                            child: pw.Table(
                              border: pw.TableBorder.all(color: PdfColor.fromHex('#e2e8f0'), width: 1),
                              columnWidths: { 0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(1) },
                              children: [
                                pw.TableRow(
                                  decoration: pw.BoxDecoration(color: faintGray),
                                  children: [
                                    buildGridCell('الرقم القومي', s.nationalId ?? '-', svgIdCard),
                                    buildGridCell('رقم هاتف الطالب / ولي الأمر', s.phone, svgPhone),
                                  ]
                                ),
                                pw.TableRow(
                                  children: [
                                    buildGridCell('تاريخ الميلاد', s.birthDate != null ? "${s.birthDate!.year}-${s.birthDate!.month.toString().padLeft(2,'0')}-${s.birthDate!.day.toString().padLeft(2,'0')}" : '-', svgCalendar),
                                    buildGridCell('النوع', s.gender ?? '-', svgUser),
                                  ]
                                ),
                                pw.TableRow(
                                  decoration: pw.BoxDecoration(color: faintGray),
                                  children: [
                                    buildGridCell('المحفظ', s.memorizerName ?? '-', svgUser),
                                    buildGridCell('رقم المحفظ', s.memorizerPhone ?? '-', svgBook),
                                  ]
                                ),
                                pw.TableRow(
                                  children: [
                                    buildGridCell('عنوان الطالب', s.location ?? '-', svgLocation),
                                    buildGridCell('عنوان المحفظ', s.memorizerAddress ?? '-', svgLocation),
                                  ]
                                ),
                              ]
                            )
                          )
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: blueDark,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          ),
                          child: pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.all(2),
                                decoration: pw.BoxDecoration(color: blueDark, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                                child: pw.SvgImage(svg: svgList, width: 12, height: 12, colorFilter: PdfColors.white),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Text('البيانات التفصيلية', style: pw.TextStyle(color: PdfColors.white, font: arabicFontBold, fontSize: 12)),
                            ]
                          )
                        ),
                      ]
                    ),
                    pw.SizedBox(height: 14),

                    // Conditions
                    pw.Stack(
                      alignment: pw.Alignment.topCenter,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 12),
                          padding: const pw.EdgeInsets.only(top: 20, bottom: 8, left: 12, right: 12),
                          decoration: pw.BoxDecoration(
                            color: faintGray,
                            border: pw.Border.all(color: PdfColor.fromHex('#e2e8f0'), width: 1),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              'القبول بشروط المسابقة، يحظر تقديم أي رسوم مالية',
                              'كل متسابق يلتزم بالمواعيد المحدده له( التقديم -الاختبار-الحفلة)',
                              'يتم التصفيه في المسابقة بوضع سؤال للتصفية في الامتحان سؤال في ضبط المتشابهات',
                              'سيتم تكريم الاوائل الثلاثة على المنصة فقط والباقي في أماكنهم والرجاء الرضا بذالك',
                              'عند عدم الحضور المُكرم الحفل يحجب من الجائزة وتودع في الامانات',
                              'يحظر الجمع بين جائزتين فأكثر ،سيتم تكريم الفائزين بدرجة الامتياز فأكثر',
                            ].asMap().entries.map((e) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Container(
                                    width: 16, height: 16,
                                    alignment: pw.Alignment.center,
                                    decoration: pw.BoxDecoration(color: blueDark, shape: pw.BoxShape.circle),
                                    child: pw.Text('${e.key + 1}', style: pw.TextStyle(font: arabicFontBold, fontSize: 9, color: PdfColors.white)),
                                  ),
                                  pw.SizedBox(width: 8),
                                  pw.Expanded(child: pw.Text(e.value, style: pw.TextStyle(font: arabicFont, fontSize: 10, color: blueDark))),
                                ],
                              ),
                            )).toList(),
                          )
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)), border: pw.Border.all(color: goldLight, width: 1.5)),
                          child: pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.all(3),
                                decoration: pw.BoxDecoration(color: blueDark, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                                child: pw.SvgImage(svg: svgList, width: 10, height: 10, colorFilter: PdfColors.white),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Text('ملاحظات هامة', style: pw.TextStyle(color: gold, font: arabicFontBold, fontSize: 12)),
                            ]
                          )
                        ),
                      ]
                    ),
                    
                    pw.SizedBox(height: 24),

                    // Supervisor
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text('المشرف العام علي المسابقة', style: pw.TextStyle(font: arabicFontBold, fontSize: 11, color: gold)),
                          pw.SizedBox(height: 2),
                          pw.Text('أ/ مصطفى عبدالرحمن محمد سالم', style: pw.TextStyle(font: arabicFontBold, fontSize: 15, color: blueDark)),
                        ]
                      )
                    ),
                    pw.SizedBox(height: 20),

                    // Warning Box
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#fffbeb'),
                        border: pw.Border.all(color: PdfColor.fromHex('#f59e0b'), width: 2),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.SvgImage(svg: svgWarning, width: 18, height: 18, colorFilter: PdfColor.fromHex('#b45309')),
                          pw.SizedBox(width: 10),
                          pw.Text('ملاحظة هامة:', style: pw.TextStyle(font: arabicFontBold, fontSize: 11, color: PdfColor.fromHex('#92400e'))),
                          pw.SizedBox(width: 6),
                          pw.Expanded(child: pw.Text('يجب طباعة هذه الاستمارة في ورقة واحدة وإحضارها معك في موعد الاختبار المحدد لك أعلاه.', style: pw.TextStyle(font: arabicFontBold, fontSize: 9.5, color: PdfColor.fromHex('#92400e')))),
                        ]
                      )
                    ),
                  ]
                )
              ),
            ]
          )
        );
      }
    );
  }

  pw.Page _buildEvaluationPage(Student s, CompetitionLevel levelData, pw.ImageProvider? profileImage, pw.Font arabicFont, pw.Font arabicFontBold, {pw.ImageProvider? logoImage}) {
    const String svgBook = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M21 5c-1.11-.35-2.33-.5-3.5-.5-1.95 0-4.05.4-5.5 1.5-1.45-1.1-3.55-1.5-5.5-1.5S2.45 4.9 1 6v14.65c0 .25.25.5.5.5.1 0 .15-.05.25-.05C3.1 20.45 5.05 20 6.5 20c1.95 0 4.05.4 5.5 1.5 1.35-.85 3.8-1.5 5.5-1.5 1.65 0 3.35.3 4.75 1.05.1.05.15.05.25.05.25 0 .5-.25.5-.5V6c-.6-.45-1.25-.75-2-1zM21 18.5c-1.1-.35-2.3-.5-3.5-.5-1.7 0-4.15.65-5.5 1.5V8c1.35-.85 3.8-1.5 5.5-1.5 1.2 0 2.4.15 3.5.5v11.5z"/></svg>';
    final blueDark = PdfColor.fromHex('#0f172a');
    final gold = PdfColor.fromHex('#b45309');
    final faintGray = PdfColor.fromHex('#f8fafc');

    pw.Widget buildTableCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.center, bool isBold = false, pw.TextDirection? textDir, double leftPadding = 6, double? fontSize, pw.BoxDecoration? decoration}) {
      return pw.Container(
        padding: pw.EdgeInsets.only(top: 6, bottom: 6, right: 8, left: leftPadding),
        alignment: align == pw.TextAlign.right ? pw.Alignment.centerRight : (align == pw.TextAlign.left ? pw.Alignment.centerLeft : pw.Alignment.center),
        decoration: decoration ?? (isHeader ? pw.BoxDecoration(color: blueDark) : null),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: (isHeader || isBold) ? arabicFontBold : arabicFont, 
            fontSize: fontSize ?? (isHeader ? 12 : 11), 
            color: isHeader ? PdfColors.white : blueDark
          ),
          textAlign: align,
          textDirection: textDir,
        ),
      );
    }

    final List<String> questions = [
      'السؤال الأول', 'السؤال الثاني', 'السؤال الثالث', 'السؤال الرابع', 'السؤال الخامس',
      'السؤال السادس', 'السؤال السابع', 'السؤال الثامن', 'السؤال التاسع', 'السؤال العاشر'
    ];

    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
      ),
      build: (pw.Context context) {
        return [
          // Header
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.only(bottom: 12),
              margin: const pw.EdgeInsets.only(top: 36, left: 24, right: 24),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#e2e8f0'), width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('مسابقة أهل القرآن الكبرى', style: pw.TextStyle(color: blueDark, fontSize: 20, font: arabicFontBold)),
                        pw.SizedBox(height: 6),
                        pw.Text('استمارة تقييم المتسابق', style: pw.TextStyle(color: gold, fontSize: 14, font: arabicFontBold)),
                      ]
                    )
                  ),
                  pw.SizedBox(width: 16),
                  logoImage != null
                      ? pw.Container(
                          width: 70, height: 70,
                          decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle),
                          child: pw.ClipOval(
                            child: pw.Image(logoImage, width: 70, height: 70, fit: pw.BoxFit.cover),
                          ),
                        )
                      : pw.SvgImage(svg: svgBook, width: 36, height: 36, colorFilter: gold),
                ]
              ),
            ),
          ),

          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Student Info
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: pw.BoxDecoration(
                      color: faintGray,
                      border: pw.Border.all(color: PdfColor.fromHex('#e2e8f0'), width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text('الاسم: ${s.name}', style: pw.TextStyle(font: arabicFontBold, fontSize: 12, color: blueDark), textDirection: pw.TextDirection.rtl),
                        ),
                        pw.Expanded(
                          flex: 6,
                          child: pw.RichText(
                            textDirection: pw.TextDirection.rtl,
                            text: pw.TextSpan(
                              style: pw.TextStyle(font: arabicFontBold, fontSize: 12, color: blueDark),
                              children: [
                                pw.TextSpan(text: '${levelData.title} - ${levelData.content}${s.selectedRewaya != null && s.selectedRewaya!.isNotEmpty ? ' - ${s.selectedRewaya}' : ''}'),
                                if (s.branchName != null && s.branchName!.isNotEmpty)
                                  pw.TextSpan(
                                    text: ' (${s.branchName})',
                                    style: pw.TextStyle(font: arabicFontBold, fontSize: 12, color: PdfColor.fromHex('#dc2626')),
                                  ),
                              ]
                            )
                          ),
                        ),
                      ]
                    )
                  ),
                  pw.SizedBox(height: 18),
                ]
              )
            )
          ),

          // Evaluation Table (Standalone to allow splitting)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: blueDark, width: 1.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Table(
                    border: pw.TableBorder(
                      horizontalInside: pw.BorderSide(color: PdfColor.fromHex('#cbd5e1'), width: 1),
                      verticalInside: pw.BorderSide(color: PdfColor.fromHex('#cbd5e1'), width: 1),
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2.5), // Score
                      1: const pw.FlexColumnWidth(4.5), // Notes
                      2: const pw.FlexColumnWidth(3.0), // Question
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          buildTableCell('الدرجة', isHeader: true),
                          buildTableCell('ملاحظات', isHeader: true),
                          buildTableCell('السؤال', isHeader: true),
                        ]
                      ),
                      ...questions.asMap().entries.map((e) => pw.TableRow(
                        decoration: pw.BoxDecoration(color: e.key % 2 != 0 ? faintGray : PdfColors.white),
                        children: [
                          buildTableCell('10 / ', isBold: true, textDir: pw.TextDirection.ltr, align: pw.TextAlign.left, fontSize: 13, leftPadding: 20),
                          buildTableCell('', align: pw.TextAlign.right),
                          buildTableCell(e.value, isBold: true),
                        ]
                      )),
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#f1f5f9')),
                        children: [
                          buildTableCell('100 / ', isBold: true, textDir: pw.TextDirection.ltr, align: pw.TextAlign.left, fontSize: 13, leftPadding: 20, decoration: pw.BoxDecoration(color: PdfColor.fromHex('#f1f5f9'), border: pw.Border(top: pw.BorderSide(color: blueDark, width: 2)))),
                          buildTableCell('', decoration: pw.BoxDecoration(color: PdfColor.fromHex('#f1f5f9'), border: pw.Border(top: pw.BorderSide(color: blueDark, width: 2)))),
                          buildTableCell('المجموع', isBold: true, decoration: pw.BoxDecoration(color: PdfColor.fromHex('#f1f5f9'), border: pw.Border(top: pw.BorderSide(color: blueDark, width: 2)))),
                        ]
                      ),
                      
                      if (levelData.hasRewaya)
                        pw.TableRow(
                          children: [
                            buildTableCell('${levelData.rewayaMaxScore} / ', isBold: true, textDir: pw.TextDirection.ltr, align: pw.TextAlign.left, fontSize: 14, leftPadding: 24),
                            buildTableCell('', align: pw.TextAlign.right),
                            buildTableCell('الرواية', isBold: true),
                          ]
                        ),
                      if (levelData.hasTajweed)
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: faintGray),
                          children: [
                            buildTableCell('${levelData.tajweedMaxScore} / ', isBold: true, textDir: pw.TextDirection.ltr, align: pw.TextAlign.left, fontSize: 14, leftPadding: 24),
                            buildTableCell('', align: pw.TextAlign.right),
                            buildTableCell('التجويد', isBold: true),
                          ]
                        ),
                      if (levelData.hasVoice)
                        pw.TableRow(
                          children: [
                            buildTableCell('${levelData.voiceMaxScore} / ', isBold: true, textDir: pw.TextDirection.ltr, align: pw.TextAlign.left, fontSize: 14, leftPadding: 24),
                            buildTableCell('', align: pw.TextAlign.right),
                            buildTableCell('حُسن الصوت', isBold: true),
                          ]
                        ),
                      if (levelData.hasMeaning)
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: faintGray),
                          children: [
                            buildTableCell('${levelData.meaningMaxScore} / ', isBold: true, textDir: pw.TextDirection.ltr, align: pw.TextAlign.left, fontSize: 14, leftPadding: 24),
                            buildTableCell('', align: pw.TextAlign.right),
                            buildTableCell('فهم المعاني والوقف', isBold: true),
                          ]
                        ),
                      
                      // Grand Total
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#fef3c7')),
                        children: [
                          buildTableCell('${levelData.totalMaxPoints} / ', isBold: true, textDir: pw.TextDirection.ltr, align: pw.TextAlign.left, fontSize: 14, leftPadding: 24),
                          buildTableCell(''),
                          buildTableCell('المجموع الكلي للقسم', isBold: true),
                        ]
                      ),
                    ]
                  ),
                )
              )
            )
          ),
          
          pw.SizedBox(height: 24),
          
        ];
      }
    );
  }
}
