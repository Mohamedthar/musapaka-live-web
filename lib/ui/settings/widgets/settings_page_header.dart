import 'package:flutter/material.dart';

class SettingsPageHeader extends StatelessWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onSave;
  final bool isSaving;
  final bool isMobile;
  final Color primaryColor;

  const SettingsPageHeader({
    super.key,
    required this.onRefresh,
    required this.onSave,
    required this.isSaving,
    required this.isMobile,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 24.0,
        vertical: 14.0,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildIconBadge(),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTitleSection()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildRefreshButton()),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSaveButton()),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                _buildIconBadge(),
                const SizedBox(width: 16),
                Expanded(child: _buildTitleSection()),
                _buildRefreshButton(),
                const SizedBox(width: 12),
                _buildSaveButton(),
              ],
            ),
    );
  }

  Widget _buildIconBadge() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.settings_rounded, color: primaryColor, size: 24),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'إعدادات النظام',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF03121C),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'التحكم الكامل في إعدادات المسابقة والجدولة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return OutlinedButton.icon(
      onPressed: isSaving ? null : onRefresh,
      icon: Icon(Icons.refresh_rounded, size: 18, color: Colors.grey.shade600),
      label: const Text(
        'تحديث',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: isSaving ? null : onSave,
      icon: isSaving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.check_circle_rounded, size: 18),
      label: Text(
        isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
