import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import '../../../data/models/student.dart';
import '../../../data/models/competition_level.dart';
import '../../../services/supabase_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/theme/app_theme.dart';

// دالة ضغط الصور في مسار منفصل لمنع تجميد الواجهة
Uint8List _compressImage(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return bytes;
  
  img.Image resized = image;
  if (image.width > 800) {
    resized = img.copyResize(image, width: 800);
  }
  
  return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
}

class RegistrationFormContent extends StatefulWidget {
  final Function(Student)? onSuccess;
  const RegistrationFormContent({super.key, this.onSuccess});

  @override
  State<RegistrationFormContent> createState() => _RegistrationFormContentState();
}

class _RegistrationFormContentState extends State<RegistrationFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _memorizerNameCtrl = TextEditingController();
  final _memorizerPhoneCtrl = TextEditingController();
  final _memorizerAddressCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _gender = 'ذكر';
  DateTime? _birthDate;
  final _service = SupabaseService();
  final _cloudinary = CloudinaryService();

  static const _primary = Color(0xFF03121C);

  CompetitionLevel? _selectedLevelObj;
  Uint8List? _profileBytes;
  String? _profileName;
  Uint8List? _birthCertBytes;
  String? _birthCertName;
  bool _isLoading = false;
  List<CompetitionLevel> _levels = [];
  bool _isLoadingLevels = true;
  Timer? _nameDebounce;
  bool _isDuplicateName = false;
  bool _isCheckingName = false;
  bool _isCheckingId = false;
  bool _isDuplicateId = false;
  String? _selectedRewaya;
  String? _selectedBranch;
  int? _memorizationAmount;

  @override
  void initState() {
    super.initState();
    _nationalIdCtrl.addListener(_onNationalIdChanged);
    _nameCtrl.addListener(_onNameChanged);
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    try {
      final levels = await _service.getLevels();
      if (mounted) {
        setState(() {
          _levels = levels;
          _isLoadingLevels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLevels = false);
        AppTheme.showError(context, e, contextLabel: 'تحميل المستويات');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _nationalIdCtrl.dispose();
    _memorizerNameCtrl.dispose();
    _memorizerPhoneCtrl.dispose();
    _memorizerAddressCtrl.dispose();
    _locationCtrl.dispose();
    _nationalIdCtrl.removeListener(_onNationalIdChanged);
    _nameCtrl.removeListener(_onNameChanged);
    _nameDebounce?.cancel();
    super.dispose();
  }

  void _onNameChanged() {
    if (_nameDebounce?.isActive ?? false) _nameDebounce?.cancel();
    
    final name = _nameCtrl.text.trim();
    if (name.length < 3) {
      if (_isDuplicateName) setState(() => _isDuplicateName = false);
      return;
    }

    _nameDebounce = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      setState(() => _isCheckingName = true);
      
      try {
        final exists = await _service.checkNameExists(name);
        if (mounted) {
          setState(() {
            _isDuplicateName = exists;
            _isCheckingName = false;
          });
          if (exists) {
            AppTheme.showSnack(context, 'تنبيه: هذا الاسم مسجل مسبقاً!', color: AppTheme.warningColor);
          }
        }
      } catch (e) {
        if (mounted) setState(() => _isCheckingName = false);
      }
    });
  }

  void _onNationalIdChanged() {
    final id = _nationalIdCtrl.text.trim();
    if (id.length == 14) {
      // 1. Extract Gender (13th digit)
      final int? digit13 = int.tryParse(id[12]);
      if (digit13 != null) {
        final bool isMale = digit13 % 2 != 0;
        final String detectedGender = isMale ? 'ذكر' : 'أنثى';
        if (_gender != detectedGender) {
          setState(() => _gender = detectedGender);
        }
      }

      // 2. Extract Birth Date & Age (Digits 1-7)
      final int? centuryDigit = int.tryParse(id[0]);
      final int? yearPart = int.tryParse(id.substring(1, 3));
      final int? monthPart = int.tryParse(id.substring(3, 5));
      final int? dayPart = int.tryParse(id.substring(5, 7));

          if (centuryDigit != null && yearPart != null && monthPart != null && dayPart != null) {
        final int year = (centuryDigit == 2 ? 1900 : 2000) + yearPart;
        try {
          final DateTime birthDate = DateTime(year, monthPart, dayPart);
          if (_birthDate != birthDate) {
            setState(() {
              _birthDate = birthDate;
            });
          }

          final DateTime now = DateTime.now();
          int age = now.year - birthDate.year;
          if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
            age--;
          }
          if (age >= 0 && age < 100) {
            final String ageStr = age.toString();
            if (_ageCtrl.text != ageStr) {
              _ageCtrl.text = ageStr;
            }
          }
          setState(() {});
        } catch (e, stackTrace) {
          AppLogger.error('Failed to parse national ID date in registration', error: e, stack: stackTrace);
        }
      }

      // 3. Real-time Duplicate ID Check
      _checkDuplicateId(id);
    } else {
      if (_isDuplicateId) setState(() => _isDuplicateId = false);
    }
  }

  Future<void> _checkDuplicateId(String id) async {
    setState(() => _isCheckingId = true);
    try {
      final exists = await _service.checkNationalIdExists(id);
      if (mounted) {
        setState(() {
          _isDuplicateId = exists;
          _isCheckingId = false;
        });
        if (exists) {
          AppTheme.showSnack(context, 'تنبيه: هذا الرقم القومي مسجل مسبقاً!', color: AppTheme.warningColor);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check duplicate national ID in registration', error: e, stack: stackTrace);
      if (mounted) setState(() => _isCheckingId = false);
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (!Validator.isValidImageType(file.name)) {
        if (mounted) AppTheme.showSnack(context, 'يجب أن تكون الصورة بصيغة JPG أو PNG', color: AppTheme.errorColor);
        return;
      }
      final bytes = file.bytes;
      if (bytes == null) return;
      setState(() => _isLoading = true);
      final compressedBytes = kIsWeb
          ? _compressImage(bytes)
          : await compute(_compressImage, bytes);
      setState(() {
        _isLoading = false;
        if (isProfile) { 
          _profileBytes = compressedBytes; 
          _profileName = file.name; 
        } else { 
          _birthCertBytes = compressedBytes; 
          _birthCertName = file.name; 
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileBytes == null || _birthCertBytes == null) {
      AppTheme.showSnack(context, 'يرجى رفع الصورتين المطلوبتين', color: AppTheme.warningColor);
      return;
    }
    
    if (_phoneCtrl.text.trim().isNotEmpty && 
        _memorizerPhoneCtrl.text.trim().isNotEmpty && 
        _phoneCtrl.text.trim() == _memorizerPhoneCtrl.text.trim()) {
      AppTheme.showSnack(context, 'رقم هاتف الطالب / ولي الأمر يجب أن يكون مختلفاً عن رقم هاتف المحفظ', color: Colors.red);
      return;
    }
    setState(() => _isLoading = true);
    try {
      String nationalId = _nationalIdCtrl.text.trim();

      // Validate National ID length and gender match BEFORE submission
      if (nationalId.isNotEmpty) {
        if (nationalId.length != 14) {
          AppTheme.showSnack(context, 'الرقم القومي يجب أن يكون 14 رقماً', color: Colors.red);
          setState(() => _isLoading = false);
          return;
        }

        final int? digit13 = int.tryParse(nationalId[12]);
        if (digit13 != null) {
          bool isMale = digit13 % 2 != 0;
          if ((_gender == 'ذكر' && !isMale) || (_gender == 'أنثى' && isMale)) {
            AppTheme.showSnack(context, 'النوع المحدد لا يتطابق مع الرقم القومي', color: Colors.red);
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      if (_selectedLevelObj != null) {
        final age = int.tryParse(_ageCtrl.text);
        if (age != null && !_selectedLevelObj!.ageMatches(age)) {
          final op = _selectedLevelObj!.ageOp;
          String msg = 'عمرك غير مناسب لهذا المستوى';
          if (op == 'gt') msg = 'يجب أن يكون عمرك أكبر من ${_selectedLevelObj!.minAge} سنة';
          else if (op == 'gte') msg = 'يجب أن يكون عمرك ${_selectedLevelObj!.minAge} سنة على الأقل';
          else if (op == 'lt') msg = 'يجب أن يكون عمرك أصغر من ${_selectedLevelObj!.maxAge} سنة';
          else if (op == 'lte') msg = 'يجب أن يكون عمرك ${_selectedLevelObj!.maxAge} سنة على الأكثر';
          else if (op == 'range') msg = 'العمر المطلوب من ${_selectedLevelObj!.minAge} إلى ${_selectedLevelObj!.maxAge} سنة';
          AppTheme.showSnack(context, msg, color: Colors.red);
          setState(() => _isLoading = false);
          return;
        }
      }

      final urls = await _cloudinary.uploadMultiple([
        (bytes: _profileBytes!, name: _profileName!),
        (bytes: _birthCertBytes!, name: _birthCertName!),
      ]);

      final createdStudent = await _service.createStudent(Student(
        name: _nameCtrl.text.trim(),
        age: int.parse(_ageCtrl.text),
        phone: _phoneCtrl.text.trim(),
        level: _selectedLevelObj!.title,
        nationalId: nationalId.isEmpty ? null : nationalId,
        gender: _gender,
        profileImageUrl: urls[0],
        birthCertificateUrl: urls[1],
        memorizerName: _memorizerNameCtrl.text.trim().isEmpty ? null : _memorizerNameCtrl.text.trim(),
        memorizerPhone: _memorizerPhoneCtrl.text.trim().isEmpty ? null : _memorizerPhoneCtrl.text.trim(),
        memorizerAddress: _memorizerAddressCtrl.text.trim().isEmpty ? null : _memorizerAddressCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        birthDate: _birthDate,
        selectedRewaya: (_selectedLevelObj!.hasRewaya) ? _selectedRewaya : null,
        branchName: _selectedBranch,
        memorizationAmount: _memorizationAmount,
      ));

      if (mounted) {
        AppTheme.showSnack(context, 'تم تسجيل المتسابق بنجاح ✓');
        _clear();
        widget.onSuccess?.call(createdStudent);
      }
    } catch (e) {
      if (mounted) AppTheme.showError(context, e, contextLabel: 'تسجيل المتسابق');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clear() {
    _nameCtrl.clear(); _ageCtrl.clear(); _phoneCtrl.clear(); _nationalIdCtrl.clear(); _memorizerNameCtrl.clear(); _memorizerPhoneCtrl.clear(); _memorizerAddressCtrl.clear(); _locationCtrl.clear();
    setState(() {
      _selectedLevelObj = null;
      _selectedRewaya = null;
      _selectedBranch = null;
      _memorizationAmount = null;
      _gender = 'ذكر';
      _profileBytes = null; _birthCertBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 480;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Section 1: Personal Info ─────────────────────────────
                _sectionHeader('المعلومات الشخصية', Icons.person),
                _fieldGroup([
                  _field(
                    _nameCtrl,
                    'الاسم الكامل',
                    Icons.person_outline,
                    Validator.validateName,
                    suffixIcon: _isCheckingName
                        ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                        : _isDuplicateName
                            ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
                            : null,
                  ),
                  if (_isDuplicateName)
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 12),
                      child: Text('هذا الاسم موجود مسبقاً في النظام',
                          style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    ),
                  const SizedBox(height: 12),
                  // National ID + Age
                  Row(children: [
                    Expanded(
                      flex: 3,
                      child: _field(
                        _nationalIdCtrl,
                        'الرقم القومي',
                        Icons.badge_outlined,
                        Validator.validateNationalId,
                        type: TextInputType.number,
                        suffixIcon: _isCheckingId
                            ? const SizedBox(width: 18, height: 18, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                            : _isDuplicateId
                                ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _field(_ageCtrl, 'العمر', Icons.cake_outlined, Validator.validateAge, type: TextInputType.number)),
                  ]),
                  if (_isDuplicateId)
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 12),
                      child: Text('هذا الرقم القومي موجود مسبقاً في النظام',
                          style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: _inputDec('النوع', Icons.wc_outlined),
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(value: 'ذكر', child: Row(children: [Icon(Icons.male, size: 18, color: Colors.blue), SizedBox(width: 10), Text('ذكر')])),
                      DropdownMenuItem(value: 'أنثى', child: Row(children: [Icon(Icons.female, size: 18, color: Colors.pink), SizedBox(width: 10), Text('أنثى')])),
                    ],
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ]),

                const SizedBox(height: 20),

                // ── Section 2: Quran & Contact ───────────────────────────
                _sectionHeader('بيانات الحفظ والتواصل (للطالب)', Icons.menu_book),
                _fieldGroup([
                  _isLoadingLevels
                      ? const Center(child: CircularProgressIndicator())
                      : _buildLevelDropdown(),
                  // Rewaya dropdown
                  if (_selectedLevelObj != null &&
                      _selectedLevelObj!.hasRewaya &&
                      _selectedLevelObj!.availableRewayas.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRewaya,
                      decoration: _inputDec('اختر الرواية أو القراءة', Icons.auto_stories_outlined),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      items: _selectedLevelObj!.availableRewayas
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r,
                                    style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedRewaya = v),
                      validator: (v) => v == null ? 'يرجى اختيار الرواية أو القراءة' : null,
                    ),
                  ],
                  // Branch / Custom Amount UI
                  if (_selectedLevelObj != null) ...[
                    if (_selectedLevelObj!.branches.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBranch,
                        decoration: _inputDec('اختر الكمية / القسم', Icons.account_tree_outlined),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        items: _selectedLevelObj!.branches
                            .map((b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(b,
                                      style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedBranch = v),
                        validator: (v) => v == null ? 'يرجى اختيار القسم أو الكمية' : null,
                      ),
                      if (_selectedLevelObj!.requireCustomAmount) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _memorizationAmount,
                          decoration: _inputDec('عدد الأجزاء المحفوظة', Icons.format_list_numbered_rounded),
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items: List.generate(30, (i) => i + 1).map((n) => DropdownMenuItem(
                                value: n,
                                child: Text(n == 1 ? 'جزء واحد' : n == 2 ? 'جزئين' : '$n أجزاء',
                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                              )).toList(),
                          onChanged: (v) => setState(() => _memorizationAmount = v),
                          validator: (v) => v == null ? 'يرجى اختيار عدد الأجزاء' : null,
                        ),
                      ],
                    ] else if (_selectedLevelObj!.requireCustomAmount) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _memorizationAmount,
                        decoration: _inputDec('عدد الأجزاء المحفوظة', Icons.format_list_numbered_rounded),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        items: List.generate(30, (i) => i + 1).map((n) => DropdownMenuItem(
                              value: n,
                              child: Text(n == 1 ? 'جزء واحد' : n == 2 ? 'جزئين' : '$n أجزاء',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                            )).toList(),
                        onChanged: (v) => setState(() {
                          _memorizationAmount = v;
                          _selectedBranch = v != null ? '$v أجزاء' : null;
                        }),
                        validator: (v) => v == null ? 'يرجى اختيار عدد الأجزاء' : null,
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  // Phone + Location — 2 columns when wide
                  if (isWide)
                    Row(children: [
                      Expanded(child: _field(_phoneCtrl, 'رقم هاتف الطالب / ولي الأمر', Icons.phone_outlined, Validator.validatePhone, type: TextInputType.phone)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_locationCtrl, 'عنوان الطالب', Icons.location_on_outlined, Validator.validateRequired)),
                    ])
                  else ...[
                    _field(_phoneCtrl, 'رقم هاتف الطالب / ولي الأمر', Icons.phone_outlined, Validator.validatePhone, type: TextInputType.phone),
                    const SizedBox(height: 12),
                    _field(_locationCtrl, 'عنوان الطالب', Icons.location_on_outlined, Validator.validateRequired),
                  ],
                ]),

                const SizedBox(height: 20),

                // ── Section 3: Memorizer ─────────────────────────────────
                _sectionHeader('بيانات المحفظ', Icons.person_add_alt_1_outlined),
                _fieldGroup([
                  _field(_memorizerNameCtrl, 'اسم المحفظ', Icons.person_pin_outlined, Validator.validateRequired),
                  const SizedBox(height: 12),
                  if (isWide)
                    Row(children: [
                      Expanded(child: _field(_memorizerPhoneCtrl, 'هاتف المحفظ', Icons.phone_outlined, Validator.validatePhone, type: TextInputType.phone)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_memorizerAddressCtrl, 'عنوان المحفظ', Icons.location_on_outlined, (_) => null)),
                    ])
                  else ...[
                    _field(_memorizerPhoneCtrl, 'هاتف المحفظ', Icons.phone_outlined, Validator.validatePhone, type: TextInputType.phone),
                    const SizedBox(height: 12),
                    _field(_memorizerAddressCtrl, 'عنوان المحفظ', Icons.location_on_outlined, (_) => null),
                  ],
                ]),

                const SizedBox(height: 20),

                // ── Section 4: Documents ─────────────────────────────────
                _sectionHeader('المستندات المرفقة', Icons.file_present),
                _fieldGroup([
                  Row(children: [
                    Expanded(child: _imgPicker(_profileBytes, 'الصورة الشخصية', Icons.face_outlined, () => _pickImage(true))),
                    const SizedBox(width: 10),
                    Expanded(child: _imgPicker(_birthCertBytes, 'شهادة الميلاد', Icons.description_outlined, () => _pickImage(false))),
                  ]),
                ]),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Colors.white),
                    label: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('تسجيل المتسابق',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            );
          },
        ),
      ),
    );
  }


  Widget _sectionHeader(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _primary.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: _primary)),
          ],
        ),
      );

  Widget _fieldGroup(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

   InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade600),
    floatingLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
    prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
    filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12), 
      borderSide: const BorderSide(color: Color(0xFF03121C), width: 1.5)
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

   Widget _field(TextEditingController ctrl, String label, IconData icon,
      String? Function(String?) validator, {TextInputType? type, Widget? suffixIcon}) =>
    TextFormField(
      controller: ctrl, keyboardType: type,
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
      decoration: _inputDec(label, icon).copyWith(suffixIcon: suffixIcon),
      validator: validator,
    );

  Widget _imgPicker(Uint8List? bytes, String label, IconData icon, VoidCallback onTap) {
    final hasImage = bytes != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasImage ? _primary : Colors.grey.shade300, width: hasImage ? 1.5 : 1),
        ),
        child: hasImage
            ? Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(bytes, width: double.infinity, height: double.infinity, fit: BoxFit.cover)),
                Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    )),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 26, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ]),
      ),
    );
  }

  List<CompetitionLevel> get _filteredLevels {
    final age = int.tryParse(_ageCtrl.text);
    if (age == null) return _levels;
    return _levels.where((l) => l.ageMatches(age)).toList();
  }

  Widget _buildLevelDropdown() {
    final filtered = _filteredLevels;
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Text('لا يوجد مستويات متاحة لهذا العمر',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
      );
    }
    return DropdownButtonFormField<CompetitionLevel>(
      initialValue: filtered.contains(_selectedLevelObj) ? _selectedLevelObj : null,
      decoration: _inputDec('اختر المستوى', Icons.school_outlined),
      isExpanded: true,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      items: filtered
          .map((l) => DropdownMenuItem(
                value: l,
                child: Text('${l.title} — ${l.content}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
              ))
          .toList(),
      onChanged: (v) {
        setState(() {
          _selectedLevelObj = v;
          _selectedBranch = null;
          if (v != null && v.hasRewaya && v.availableRewayas.isNotEmpty) {
            _selectedRewaya = v.availableRewayas.first;
          } else {
            _selectedRewaya = null;
          }
        });
      },
      validator: (v) => v == null ? 'يرجى اختيار المستوى' : null,
    );
  }
}

