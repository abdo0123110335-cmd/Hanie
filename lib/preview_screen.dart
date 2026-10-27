import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'letter_data.dart';
import 'pdf_builder.dart';

class PreviewScreen extends StatelessWidget {
  final LetterData data;
  const PreviewScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معاينة الخطاب')),
      body: PdfPreview(
        build: (format) => buildLetterPdf(data),
        pdfFileName: 'authorization_letter.pdf',
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true, // طباعة
        allowSharing: true, // مشاركة / حفظ / تحميل
        loadingWidget: const CircularProgressIndicator(),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'تعذر إنشاء الملف:\n$error\n\n'
              'تأكد من الاتصال بالإنترنت لأول مرة (لتحميل الخط) '
              'أو أضف الخط داخل assets.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
