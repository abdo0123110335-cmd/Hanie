# خطاب تفويض مخلص جمركي

تطبيق Flutter لتعبئة وتوليد خطاب تفويض رسمي بصيغة PDF على ورقة مروسة.

## بناء APK على GitHub
1. ارفع محتوى هذا المجلد إلى مستودع جديد على GitHub (فرع main).
2. ادخل تبويب **Actions** وانتظر انتهاء "Build Android APK" (٥-١٠ دقائق).
3. افتح التشغيل المكتمل وحمّل **customs-letter-apk** من قسم Artifacts، ثم فك الضغط لتجد app-release.apk.
4. (اختياري) لإنشاء Release: `git tag v1.0.0 && git push origin v1.0.0`.

## التشغيل محلياً
    flutter create --platforms=android .
    flutter pub get
    flutter run
