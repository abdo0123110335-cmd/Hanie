import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'letter_data.dart';

/// تحميل الخط: أولاً من assets (يعمل بدون إنترنت)،
/// وإن لم يوجد يُحمَّل Cairo من Google Fonts ويُخزَّن مؤقتاً.
Future<pw.Font> _loadFont(
  String assetPath,
  Future<pw.Font> Function() fallback,
) async {
  try {
    final bytes = await rootBundle.load(assetPath);
    return pw.Font.ttf(bytes);
  } catch (_) {
    return fallback();
  }
}

Future<Uint8List> buildLetterPdf(LetterData d) async {
  final regular = await _loadFont(
      'assets/fonts/Cairo-Regular.ttf', PdfGoogleFonts.cairoRegular);
  final bold =
      await _loadFont('assets/fonts/Cairo-Bold.ttf', PdfGoogleFonts.cairoBold);
  final theme = pw.ThemeData.withFont(base: regular, bold: bold);

  final doc = pw.Document(title: 'خطاب تفويض', theme: theme);

  const mm = PdfPageFormat.mm;
  final pageW = PdfPageFormat.a4.width;
  final pageH = PdfPageFormat.a4.height;

  final header = d.headerImage == null ? null : pw.MemoryImage(d.headerImage!);
  final fullPage = header != null && d.imageAspect > 1.2;

  // حدود منطقة الكتابة
  final side = 18 * mm;
  double top, bottom;
  if (header == null) {
    top = 18 * mm;
    bottom = 18 * mm;
  } else if (fullPage) {
    top = d.topMarginMm * mm;
    bottom = d.bottomMarginMm * mm;
  } else {
    top = pageW * d.imageAspect + 8 * mm; // تحت الترويسة مباشرة
    bottom = 18 * mm;
  }
  final contentW = pageW - side * 2;
  final contentH = pageH - top - bottom;

  final dateText = DateFormat('yyyy/MM/dd').format(d.date);
  final isShared = d.type == LetterType.sharedRegistry;

  const bodySize = 13.0;
  pw.TextStyle b([double size = bodySize]) =>
      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: size);

  pw.Widget para(List<pw.InlineSpan> spans,
      {pw.TextAlign align = pw.TextAlign.justify, double gap = 12}) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: gap),
      child: pw.RichText(
        textAlign: align,
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: bodySize, lineSpacing: 5),
          children: spans,
        ),
      ),
    );
  }

  pw.InlineSpan t(String s) => pw.TextSpan(text: s);
  pw.InlineSpan v(String s) => pw.TextSpan(text: s, style: b());

  // سطر في التذييل بشكل نقطة + عنوان + قيمة + خط منقط (مثل النموذج الورقي)
  pw.Widget footerRow(String label, String value, {double height = 22}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(
            height: height,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6, left: 8),
                  child: pw.Container(
                    width: 4.5,
                    height: 4.5,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.black,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                ),
                pw.Text('$label: ', style: b(12)),
                pw.Expanded(
                  child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          pw.Divider(
            height: 1,
            thickness: 0.8,
            color: PdfColors.grey800,
            borderStyle: pw.BorderStyle.dotted,
          ),
        ],
      ),
    );
  }

  // الخلفية: ورقة كاملة تُمدّ على الصفحة، أو ترويسة في الأعلى فقط
  pw.Widget background(pw.Context ctx) {
    if (fullPage) {
      return pw.FullPage(
        ignoreMargins: true,
        child: pw.Image(header, fit: pw.BoxFit.fill),
      );
    }
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Align(
        alignment: pw.Alignment.topCenter,
        child: pw.Image(header!,
            width: pageW, height: pageW * d.imageAspect, fit: pw.BoxFit.fill),
      ),
    );
  }

  // ---------- نص الخطاب حسب النوع ----------
  final bodyWidgets = <pw.Widget>[
    // الفقرة الأولى (مشتركة بين النوعين)
    para([
      t('نفوض نحن '),
      v(d.importerName),
      t(' السيد/ '),
      v(d.brokerName),
      t(' رخصة رقم: '),
      v(d.brokerLicense),
      t(' للقيام بإجراءات تخليص الشحنة واستلام إذن التسليم '
          'الخاص ببوليصة/ البوالص رقم:'),
    ], gap: 4),
    // رقم البوليصة في سطر مستقل
    pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Text(d.billNumbers,
          style: b(), textAlign: pw.TextAlign.right),
    ),
    if (isShared) ...[
      para([
        t('ونفيدكم بأن صاحب البضاعة هو السيد/ '),
        v(d.goodsOwner),
        t('، وذلك ضمن السجل المشترك المشار إليه أعلاه.'),
      ]),
      para([t('مرفق بهذا التفويض صورة من إثبات شخصية صاحب البضاعة.')]),
    ],
    para([
      t('ويعتبر هذا الخطاب تفويضاً منا للمخلص المذكور أعلاه '
          'فيما يخص إجراءات التخليص واستلام إذن التسليم '
          'للبوليصة المشار إليها.'),
    ]),
  ];

  // ---------- التذييل حسب النوع ----------
  final footerRows = <pw.Widget>[
    if (isShared) ...[
      footerRow('اسم المستورد / السجل', d.importerName),
      footerRow('اسم صاحب البضاعة', d.goodsOwner),
      footerRow('رقم إثبات الشخصية', d.ownerIdNumber),
    ] else ...[
      footerRow('اسم المفوض بالتوقيع', d.signerName),
      footerRow('وظيفة المفوض بالتوقيع', d.signerTitle),
    ],
    if (d.showSignBoxes) ...[
      footerRow('التوقيع', '', height: 34),
      footerRow('الختم', '', height: 46),
    ],
    footerRow('اسم متابع المخلص', d.followerName),
    footerRow('رقم موبايل المتابع', d.followerPhone),
  ];

  final content = pw.SizedBox(
    width: contentW,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (d.printHeaderNote) ...[
          pw.Text(d.type.headerNote,
              style: b(12), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 14),
        ],
        pw.Text('التاريخ: $dateText',
            style: const pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.right),
        pw.SizedBox(height: 8),
        pw.Text('السادة/ ${d.recipient}',
            style: b(15), textAlign: pw.TextAlign.right),
        pw.SizedBox(height: 22),
        pw.Text(
          'الموضوع: تفويض لتخليص الشحنة واستلام إذن التسليم',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 14,
            decoration: pw.TextDecoration.underline,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 22),
        ...bodyWidgets,
        pw.SizedBox(height: 14),
        pw.Text('وتفضلوا بقبول فائق الاحترام.',
            style: const pw.TextStyle(fontSize: bodySize),
            textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 22),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: contentW * 0.78,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: footerRows,
            ),
          ),
        ),
      ],
    ),
  );

  doc.addPage(
    pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.fromLTRB(side, top, side, bottom),
        textDirection: pw.TextDirection.rtl,
        theme: theme,
        buildBackground: header == null ? null : background,
      ),
      // FittedBox يصغّر المحتوى تلقائياً إذا زاد عن منطقة الكتابة،
      // فلا يخرج أي جزء من الخطاب خارج الصفحة.
      build: (ctx) => pw.SizedBox(
        width: contentW,
        height: contentH,
        child: pw.FittedBox(
          fit: pw.BoxFit.scaleDown,
          alignment: pw.Alignment.topCenter,
          child: content,
        ),
      ),
    ),
  );

  return doc.save();
}
