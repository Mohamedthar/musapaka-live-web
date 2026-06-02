import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/student.dart';
import '../../../data/models/competition_level.dart';

class StudentEditPanel extends StatelessWidget {
  final Student student;
  final Color primaryColor;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController nationalIdController;
  final TextEditingController ageController;
  final TextEditingController memorizerNameController;
  final TextEditingController memorizerPhoneController;
  final TextEditingController memorizerAddressController;
  final TextEditingController locationController;
  final TextEditingController birthDateController;
  final String? gender;
  final Function(String?) onGenderChanged;
  final String? currentLevel;
  final List<CompetitionLevel> levels;
  final Function(String?) onLevelChanged;
  final String? selectedRewaya;
  final Function(String?)? onRewayaChanged;
  final String? selectedBranchName;
  final Function(String?)? onBranchChanged;
  final int? memorizationAmount;
  final Function(int?)? onMemorizationAmountChanged;
  final Uint8List? profileBytes;
  final Uint8List? birthCertBytes;
  final String? profileUrl;
  final String? birthCertUrl;
  final VoidCallback onPickProfile;
  final VoidCallback onPickBirthCert;
  final bool isSaving;
  final bool isNameChecking;
  final bool isNameDuplicate;
  final bool isIdChecking;
  final bool isIdDuplicate;
  final VoidCallback onSave;
  final VoidCallback onClose;
  final double? width;

  const StudentEditPanel({
    super.key,
    required this.student,
    required this.primaryColor,
    required this.nameController,
    required this.phoneController,
    required this.nationalIdController,
    required this.ageController,
    required this.memorizerNameController,
    required this.memorizerPhoneController,
    required this.memorizerAddressController,
    required this.locationController,
    required this.birthDateController,
    required this.gender,
    required this.onGenderChanged,
    required this.currentLevel,
    required this.levels,
    required this.onLevelChanged,
    this.selectedRewaya,
    this.onRewayaChanged,
    this.selectedBranchName,
    this.onBranchChanged,
    this.memorizationAmount,
    this.onMemorizationAmountChanged,
    required this.profileBytes,
    required this.birthCertBytes,
    required this.profileUrl,
    required this.birthCertUrl,
    required this.onPickProfile,
    required this.onPickBirthCert,
    required this.isSaving,
    required this.isNameChecking,
    required this.isNameDuplicate,
    required this.isIdChecking,
    required this.isIdDuplicate,
    required this.onSave,
    required this.onClose,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final matchedLevel = levels.firstWhere(
      (l) => l.title == currentLevel,
      orElse: () => levels.isNotEmpty 
          ? levels.first 
          : CompetitionLevel(title: currentLevel ?? 'غير محدد', content: 'يرجى إضافة مستويات أولاً'),
    );
    
    return Container(
      width: isMobile ? double.infinity : (width ?? 400),
      margin: isMobile ? EdgeInsets.zero : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile 
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : BorderRadius.circular(24),
        boxShadow: isMobile ? [] : [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: isMobile 
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : BorderRadius.circular(24),
        child: Column(children: [
          if (isMobile) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: primaryColor,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 15),
              const Text('تعديل بيانات المتسابق',
                  style: TextStyle(fontFamily: 'Cairo', 
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
              const Spacer(),
              InkWell(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),

          // Content
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 480;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section 1: Personal Info ─────────────────────────
                      _sectionHeader('المعلومات الشخصية', Icons.person),
                      _fieldGroup([
                        _field(
                          nameController,
                          'الاسم بالكامل',
                          Icons.person_outline,
                          suffixIcon: isNameChecking
                              ? const SizedBox(width: 18, height: 18, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                              : isNameDuplicate
                                  ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
                                  : null,
                        ),
                        if (isNameDuplicate)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, right: 12),
                            child: Text('هذا الاسم مسجل لمشارك آخر',
                                style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                          ),
                        const SizedBox(height: 12),
                        // National ID + Age
                        Row(children: [
                          Expanded(
                            flex: 3,
                            child: _field(
                              nationalIdController,
                              'الرقم القومي',
                              Icons.badge_outlined,
                              isNum: true,
                              suffixIcon: isIdChecking
                                  ? const SizedBox(width: 18, height: 18, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                                  : isIdDuplicate
                                      ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(flex: 2, child: _field(ageController, 'العمر', Icons.cake_outlined, isNum: true, readOnly: true)),
                        ]),
                        if (isIdDuplicate)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, right: 12),
                            child: Text('هذا الرقم القومي مسجل لمتسابق آخر',
                                style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                          ),
                        const SizedBox(height: 12),
                        // Birth date + Gender — side by side when wide
                        if (isWide)
                          Row(children: [
                            Expanded(child: _field(birthDateController, 'تاريخ الميلاد', Icons.calendar_today_outlined, readOnly: true)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _dropdown<String?>(
                                label: 'النوع',
                                icon: Icons.wc_outlined,
                                value: gender,
                                items: const [
                                  DropdownMenuItem(value: 'ذكر', child: Row(children: [Icon(Icons.male, size: 18, color: Colors.blue), SizedBox(width: 8), Text('ذكر')])),
                                  DropdownMenuItem(value: 'أنثى', child: Row(children: [Icon(Icons.female, size: 18, color: Colors.pink), SizedBox(width: 8), Text('أنثى')])),
                                ],
                                onChanged: onGenderChanged,
                              ),
                            ),
                          ])
                        else ...[
                          _field(birthDateController, 'تاريخ الميلاد (تلقائي)', Icons.calendar_today_outlined, readOnly: true),
                          const SizedBox(height: 12),
                          _dropdown<String?>(
                            label: 'النوع',
                            icon: Icons.wc_outlined,
                            value: gender,
                            items: const [
                              DropdownMenuItem(value: 'ذكر', child: Row(children: [Icon(Icons.male, size: 18, color: Colors.blue), SizedBox(width: 10), Text('ذكر')])),
                              DropdownMenuItem(value: 'أنثى', child: Row(children: [Icon(Icons.female, size: 18, color: Colors.pink), SizedBox(width: 10), Text('أنثى')])),
                            ],
                            onChanged: onGenderChanged,
                          ),
                        ],
                      ]),

                      const SizedBox(height: 20),

                      // ── Section 2: Quran Data ────────────────────────────
                      _sectionHeader('بيانات الحفظ', Icons.menu_book),
                      _fieldGroup([
                        _buildEditLevelDropdown(),
                        if (matchedLevel.hasRewaya && onRewayaChanged != null) ...[
                          const SizedBox(height: 12),
                          _dropdown<String?>(
                            label: 'الرواية',
                            icon: Icons.auto_stories_outlined,
                            value: selectedRewaya,
                            items: matchedLevel.availableRewayas
                                .map((r) => DropdownMenuItem<String?>(
                                      value: r,
                                      child: Text(r, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                                    ))
                                .toList(),
                            onChanged: onRewayaChanged!,
                          ),
                        ],
                        // ── Branch / Custom Amount ───────────────────────
                        if (matchedLevel.branches.isNotEmpty && onBranchChanged != null) ...[
                          const SizedBox(height: 12),
                          _dropdown<String?>(
                            label: 'الكمية / القسم',
                            icon: Icons.account_tree_outlined,
                            value: matchedLevel.branches.contains(selectedBranchName) ? selectedBranchName : null,
                            items: matchedLevel.branches
                                .map((b) => DropdownMenuItem<String?>(
                                      value: b,
                                      child: Text(b, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                                    ))
                                .toList(),
                            onChanged: onBranchChanged!,
                          ),
                          if (matchedLevel.requireCustomAmount && onMemorizationAmountChanged != null) ...[
                            const SizedBox(height: 12),
                            _dropdown<int?>(
                              label: 'عدد الأجزاء المحفوظة',
                              icon: Icons.format_list_numbered_rounded,
                              value: memorizationAmount == 0 ? null : memorizationAmount,
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('-- لم يحدد --',
                                      style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ),
                                ...List.generate(30, (i) => i + 1).map((n) => DropdownMenuItem<int?>(
                                      value: n,
                                      child: Text(n == 1 ? 'جزء واحد' : n == 2 ? 'جزئين' : '$n أجزاء',
                                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                                    )),
                              ],
                              onChanged: onMemorizationAmountChanged!,
                            ),
                          ],
                        ] else if (matchedLevel.requireCustomAmount && matchedLevel.branches.isEmpty && onMemorizationAmountChanged != null) ...[
                          const SizedBox(height: 12),
                          _dropdown<int?>(
                            label: 'عدد الأجزاء المحفوظة',
                            icon: Icons.format_list_numbered_rounded,
                            value: memorizationAmount == 0 ? null : memorizationAmount,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('-- لم يحدد --',
                                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
                              ...List.generate(30, (i) => i + 1).map((n) => DropdownMenuItem<int?>(
                                    value: n,
                                    child: Text(n == 1 ? 'جزء واحد' : n == 2 ? 'جزئين' : '$n أجزاء',
                                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                                  )),
                            ],
                            onChanged: (v) {
                              onMemorizationAmountChanged!(v);
                              onBranchChanged?.call(v != null ? '$v أجزاء' : null);
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Memorizer name + phone — side by side when wide
                        if (isWide)
                          Row(children: [
                            Expanded(child: _field(memorizerNameController, 'اسم المحفظ', Icons.person_add_alt_1_outlined)),
                            const SizedBox(width: 10),
                            Expanded(child: _field(memorizerPhoneController, 'هاتف المحفظ', Icons.phone_outlined)),
                          ])
                        else ...[
                          _field(memorizerNameController, 'اسم المحفظ', Icons.person_add_alt_1_outlined),
                          const SizedBox(height: 12),
                          _field(memorizerPhoneController, 'هاتف المحفظ', Icons.phone_outlined),
                        ],
                        const SizedBox(height: 12),
                        _field(memorizerAddressController, 'عنوان المحفظ', Icons.location_on_outlined),
                      ]),

                      const SizedBox(height: 20),

                      // ── Section 3: Contact ───────────────────────────────
                      _sectionHeader('بيانات التواصل', Icons.contact_phone),
                      _fieldGroup([
                        if (isWide)
                          Row(children: [
                            Expanded(child: _field(phoneController, 'رقم هاتف الطالب / ولي الأمر', Icons.phone_outlined, isNum: true)),
                            const SizedBox(width: 10),
                            Expanded(child: _field(locationController, 'عنوان الطالب', Icons.location_on_outlined)),
                          ])
                        else ...[
                          _field(phoneController, 'رقم هاتف الطالب / ولي الأمر', Icons.phone_outlined, isNum: true),
                          const SizedBox(height: 12),
                          _field(locationController, 'عنوان الطالب', Icons.location_on_outlined),
                        ],
                      ]),

                      const SizedBox(height: 20),

                      // ── Section 4: Documents ─────────────────────────────
                      _sectionHeader('المستندات المرفقة', Icons.file_present),
                      _fieldGroup([
                        Row(children: [
                          Expanded(
                            child: _imgPicker(
                              bytes: profileBytes,
                              existingUrl: profileUrl,
                              label: 'الصورة الشخصية',
                              icon: Icons.face_outlined,
                              onTap: onPickProfile,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _imgPicker(
                              bytes: birthCertBytes,
                              existingUrl: birthCertUrl,
                              label: 'شهادة الميلاد',
                              icon: Icons.description_outlined,
                              onTap: onPickBirthCert,
                            ),
                          ),
                        ]),
                      ]),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: isSaving ? null : onSave,
                          icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                          label: isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('حفظ التعديلات',
                                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }



  Widget _sectionHeader(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: primaryColor.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: primaryColor)),
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

  Widget _field(TextEditingController c, String label, IconData icon, {bool isNum = false, bool readOnly = false, Widget? suffixIcon}) =>
      TextField(
        controller: c,
        readOnly: readOnly,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: readOnly ? Colors.grey.shade600 : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade600, fontSize: 13),
          floatingLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: readOnly ? BorderSide(color: Colors.grey.shade200) : const BorderSide(color: Color(0xFF03121C), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) =>
      DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade600, fontSize: 13),
          floatingLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF03121C), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _imgPicker({
    required Uint8List? bytes,
    required String? existingUrl,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasNew = bytes != null;
    final hasExisting = Validator.isValidImageUrl(existingUrl);
    final hasImage = hasNew || hasExisting;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? primaryColor : Colors.grey.shade300,
            width: hasImage ? 1.5 : 1,
          ),
        ),
        child: hasNew
            ? Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(bytes,
                      width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    )),
              ])
            : hasExisting
                ? Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                          imageUrl: existingUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Icon(icon, size: 26, color: Colors.grey.shade400)),
                    ),
                    Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 14),
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

  List<CompetitionLevel> get _ageFilteredLevels {
    final age = int.tryParse(ageController.text);
    if (age == null) return levels;
    final filtered = levels.where((l) => l.ageMatches(age)).toList();
    final current = levels.where((l) => l.title == currentLevel).toList();
    for (final l in current) {
      if (!filtered.contains(l)) filtered.add(l);
    }
    return filtered;
  }

  Widget _buildEditLevelDropdown() {
    final filtered = _ageFilteredLevels;
    return _dropdown<String?>(
      label: 'المستوى',
      icon: Icons.school_outlined,
      value: currentLevel,
      items: filtered
          .map((l) => DropdownMenuItem<String?>(
                value: l.title,
                child: Text('${l.title} — ${l.content}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, height: 1.0)),
              ))
          .toList(),
      onChanged: onLevelChanged,
    );
  }
}

