import 'package:flutter/material.dart';
import 'widgets/registration_form_content.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF03121C);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header matching Admin Panels
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
                    'تسجيل متسابق جديد',
                    style: TextStyle(fontFamily: 'Cairo', 
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: RegistrationFormContent(
                onSuccess: (_) => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
