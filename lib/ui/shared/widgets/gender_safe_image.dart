import 'package:flutter/material.dart';
import 'dart:ui';

class GenderSafeImage extends StatefulWidget {
  final Widget image;
  final String? gender;
  final bool enabled;

  const GenderSafeImage({
    super.key,
    required this.image,
    this.gender,
    this.enabled = true,
  });

  @override
  State<GenderSafeImage> createState() => _GenderSafeImageState();
}

class _GenderSafeImageState extends State<GenderSafeImage> {
  bool _blurred = true;

  bool get _shouldBlur => widget.enabled && widget.gender == 'أنثى';

  @override
  void didUpdateWidget(GenderSafeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender != widget.gender) {
      _blurred = true;
    }
  }

  void _toggle() {
    if (!_shouldBlur) return;
    setState(() => _blurred = !_blurred);
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = widget.image;

    if (_shouldBlur && _blurred) {
      imageWidget = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: imageWidget,
      );
    }

    return Stack(
      children: [
        imageWidget,
            if (_shouldBlur && _blurred)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggle,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 50 || constraints.maxHeight < 50) {
                          return const Icon(Icons.visibility_off_rounded, color: Colors.white70, size: 16);
                        }
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_off_rounded, color: Colors.white70, size: 28),
                              SizedBox(height: 4),
                              Text(
                                'اضغط للعرض',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
        if (_shouldBlur && !_blurred)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.visibility_off_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }
}
