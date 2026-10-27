import 'dart:typed_data';

/// نوع الخطاب
enum LetterType {
  sharedRegistry, // خطاب السجلات المشتركة
  company, // خطاب الشركات
}

extension LetterTypeInfo on LetterType {
  String get title => switch (this) {
        LetterType.sharedRegistry => 'خطاب السجلات المشتركة',
        LetterType.company => 'خطاب الشركات',
      };

  /// السطر التوجيهي الذي يظهر في النموذج الورقي أعلى الصفحة
  String get headerNote => switch (this) {
        LetterType.sharedRegistry =>
          'يطبع في الورقة المروسة للمورد ( Consignee ) - حالة السجلات المشتركة',
        LetterType.company =>
          'يطبع في الورقة المروسة للمورد ( Consignee ) - حالة الشركات',
      };
}

/// كل البيانات المتغيرة في الخطاب.
class LetterData {
  final LetterType type;
  final DateTime date;
  final String recipient; // الجهة المرسل إليها
  final String importerName; // اسم المستورد / السجل
  final String brokerName; // اسم المخلص الجمركي
  final String brokerLicense; // رقم الرخصة
  final String billNumbers; // رقم البوليصة / البوالص
  final String followerName; // اسم متابع المخلص
  final String followerPhone; // رقم موبايل المتابع

  // خطاب السجلات المشتركة فقط
  final String goodsOwner; // اسم صاحب البضاعة
  final String ownerIdNumber; // رقم إثبات الشخصية

  // خطاب الشركات فقط
  final String signerName; // اسم المفوض بالتوقيع
  final String signerTitle; // وظيفة المفوض بالتوقيع

  final Uint8List? headerImage; // صورة الترويسة / الورقة المروسة
  final double imageAspect; // ارتفاع الصورة ÷ عرضها
  final double topMarginMm; // بداية منطقة الكتابة (ورقة كاملة) بالملم
  final double bottomMarginMm; // نهاية منطقة الكتابة (ورقة كاملة) بالملم
  final bool showSignBoxes; // إظهار التوقيع والختم في التذييل
  final bool printHeaderNote; // طباعة سطر "يطبع في الورقة المروسة..."

  const LetterData({
    required this.type,
    required this.date,
    required this.recipient,
    required this.importerName,
    required this.brokerName,
    required this.brokerLicense,
    required this.billNumbers,
    required this.followerName,
    required this.followerPhone,
    this.goodsOwner = '',
    this.ownerIdNumber = '',
    this.signerName = '',
    this.signerTitle = '',
    this.headerImage,
    this.imageAspect = 1.0,
    this.topMarginMm = 55,
    this.bottomMarginMm = 40,
    this.showSignBoxes = true,
    this.printHeaderNote = false,
  });
}
