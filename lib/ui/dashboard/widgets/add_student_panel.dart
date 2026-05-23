import 'package:flutter/material.dart';
import '../../registration/widgets/registration_form_content.dart';
import '../../../core/utils/responsive.dart';

class AddStudentPanel extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onSuccess;
  final Color primaryColor;
  final double? width;

  const AddStudentPanel({
    super.key,
    required this.onClose,
    required this.onSuccess,
    required this.primaryColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
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
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: isMobile 
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : BorderRadius.circular(24),
        child: Column(
          children: [
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    'إضافة متسابق جديد',
                    style: TextStyle(fontFamily: 'Cairo', 
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
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
                ],
              ),
            ),
            
            // Content (The form)
            Expanded(
              child: RegistrationFormContent(
                onSuccess: (student) {
                  onSuccess();
                  onClose();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
