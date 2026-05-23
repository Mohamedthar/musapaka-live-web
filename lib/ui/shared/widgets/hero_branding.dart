import 'package:flutter/material.dart';

class HeroBranding extends StatelessWidget {
  const HeroBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: Container(
        color: const Color(0xFF03121C),
        child: Stack(
          children: [
            // دوائر زخرفية خفيفة
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.02),
                ),
              ),
            ),

            // المحتوى الرئيسي
            Center(
              child: Padding(
                padding: const EdgeInsets.all(60.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // اللوجو الحقيقي
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/logo_musapaka.jpeg',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'مسابقة القرآن الكريم',
                      style: TextStyle(fontFamily: 'Cairo', 
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 40,
                      height: 2,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'نظام إداري متكامل لإدارة\nوتحكيم المسابقات القرآنية',
                      style: TextStyle(fontFamily: 'Cairo', 
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.55),
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
