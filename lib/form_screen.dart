import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'letter_data.dart';
import 'preview_screen.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  LetterType _type = LetterType.sharedRegistry;
  DateTime _date = DateTime.now();

  Uint8List? _header;
  double _aspect = 1.0; // ارتفاع ÷ عرض الصورة
  double _topMm = 55;
  double _bottomMm = 40;
  bool _signBoxes = true;
  bool _headerNote = false;

  bool get _fullPage => _header != null && _aspect > 1.2;
  bool get _isShared => _type == LetterType.sharedRegistry;

  final _recipient =
      TextEditingController(text: 'شركة سي ام ايه لإدارة الحاويات');
  final _importer = TextEditingController();
  final _broker = TextEditingController();
  final _license = TextEditingController();
  final _bills = TextEditingController();
  final _owner = TextEditingController();
  final _ownerId = TextEditingController();
  final _signerName = TextEditingController();
  final _signerTitle = TextEditingController();
  final _followerName = TextEditingController();
  final _followerPhone = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _recipient, _importer, _broker, _license, _bills, _owner, _ownerId,
      _signerName, _signerTitle, _followerName, _followerPhone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickHeader() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 90,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final img = await decodeImageFromList(bytes);
    setState(() {
      _header = bytes;
      _aspect = img.height / img.width;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final data = LetterData(
      type: _type,
      date: _date,
      recipient: _recipient.text.trim(),
      importerName: _importer.text.trim(),
      brokerName: _broker.text.trim(),
      brokerLicense: _license.text.trim(),
      billNumbers: _bills.text.trim(),
      followerName: _followerName.text.trim(),
      followerPhone: _followerPhone.text.trim(),
      goodsOwner: _isShared ? _owner.text.trim() : '',
      ownerIdNumber: _isShared ? _ownerId.text.trim() : '',
      signerName: _isShared ? '' : _signerName.text.trim(),
      signerTitle: _isShared ? '' : _signerTitle.text.trim(),
      headerImage: _header,
      imageAspect: _aspect,
      topMarginMm: _topMm,
      bottomMarginMm: _bottomMm,
      showSignBoxes: _signBoxes,
      printHeaderNote: _headerNote,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PreviewScreen(data: data)),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    IconData? icon,
    TextInputType? type,
    bool last = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      );

  Widget _headerPreview() {
    if (!_fullPage) {
      return Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.memory(_header!, fit: BoxFit.contain),
      );
    }
    return Column(
      children: [
        const Text(
          'تم اكتشاف ورقة مروسة كاملة، وستُستخدم كخلفية للصفحة.\n'
          'اضبط حدود الكتابة (المستطيل الأحمر) بين الترويسة والتذييل:',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: AspectRatio(
              aspectRatio: 1 / _aspect,
              child: LayoutBuilder(builder: (context, c) {
                final h = c.maxHeight;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(_header!, fit: BoxFit.fill),
                    ),
                    Positioned(
                      left: c.maxWidth * 0.08,
                      right: c.maxWidth * 0.08,
                      top: h * _topMm / 297,
                      bottom: h * _bottomMm / 297,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 1.5),
                          color: const Color(0x14FF0000),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        Row(children: [
          const SizedBox(width: 90, child: Text('الهامش العلوي')),
          Expanded(
            child: Slider(
              min: 20,
              max: 120,
              divisions: 100,
              label: '${_topMm.round()} مم',
              value: _topMm,
              onChanged: (v) => setState(() => _topMm = v),
            ),
          ),
        ]),
        Row(children: [
          const SizedBox(width: 90, child: Text('الهامش السفلي')),
          Expanded(
            child: Slider(
              min: 10,
              max: 120,
              divisions: 110,
              label: '${_bottomMm.round()} مم',
              value: _bottomMm,
              onChanged: (v) => setState(() => _bottomMm = v),
            ),
          ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy/MM/dd').format(_date);

    return Scaffold(
      appBar: AppBar(title: const Text('خطاب تفويض مخلص جمركي')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('نوع الخطاب'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<LetterType>(
                showSelectedIcon: false,
                segments: [
                  for (final t in LetterType.values)
                    ButtonSegment(
                      value: t,
                      label: Text(t.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13)),
                    ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
            const SizedBox(height: 6),
            Text(_type.headerNote,
                style: Theme.of(context).textTheme.bodySmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('طباعة سطر "يطبع في الورقة المروسة..."'),
              subtitle: const Text(
                  'هذا السطر توجيهي في النموذج الورقي، والأصل ألا يُطبع'),
              value: _headerNote,
              onChanged: (v) => setState(() => _headerNote = v),
            ),
            _section('الترويسة'),
            if (_header != null) _headerPreview(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickHeader,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_header == null
                        ? 'اختيار صورة الترويسة'
                        : 'تغيير الصورة'),
                  ),
                ),
                if (_header != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'إزالة',
                    onPressed: () => setState(() => _header = null),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('إظهار التوقيع والختم في التذييل'),
              subtitle: const Text(
                  'أوقفه إذا كانت الورقة المروسة تحتوي ختماً وتوقيعاً مطبوعين'),
              value: _signBoxes,
              onChanged: (v) => setState(() => _signBoxes = v),
            ),
            _section('بيانات الخطاب'),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(dateText),
              ),
            ),
            const SizedBox(height: 12),
            _field('السادة / (الجهة المرسل إليها)', _recipient,
                icon: Icons.apartment_outlined),
            _field(_isShared ? 'اسم المستورد / السجل' : 'اسم المستورد (الشركة)',
                _importer,
                icon: Icons.business_outlined),
            _section('المخلص الجمركي'),
            _field('اسم المخلص الجمركي', _broker, icon: Icons.person_outline),
            _field('رقم الرخصة', _license, icon: Icons.badge_outlined),
            _field('رقم البوليصة / البوالص', _bills,
                icon: Icons.receipt_long_outlined),
            if (_isShared) ...[
              _section('صاحب البضاعة'),
              _field('اسم صاحب البضاعة', _owner, icon: Icons.person_outline),
              _field('رقم إثبات الشخصية', _ownerId,
                  icon: Icons.credit_card, type: TextInputType.number),
            ] else ...[
              _section('المفوض بالتوقيع'),
              _field('اسم المفوض بالتوقيع', _signerName,
                  icon: Icons.draw_outlined),
              _field('وظيفة المفوض بالتوقيع', _signerTitle,
                  icon: Icons.work_outline),
            ],
            _section('متابع المخلص'),
            _field('اسم متابع المخلص', _followerName,
                icon: Icons.support_agent_outlined),
            _field('رقم موبايل المتابع', _followerPhone,
                icon: Icons.phone_outlined,
                type: TextInputType.phone,
                last: true),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('معاينة وتحميل / طباعة الخطاب',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
