import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'form_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  runApp(const CustomsLetterApp());
}

class CustomsLetterApp extends StatelessWidget {
  const CustomsLetterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'خطاب تفويض مخلص جمركي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0B4F8A),
      ),
      home: const FormScreen(),
    );
  }
}
