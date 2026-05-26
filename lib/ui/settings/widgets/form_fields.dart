import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class SettingsFormFields {
  // ─── Enhanced Text Input ───────────────────────────────────────────────
  static InputDecoration enhancedInputDecoration({
    required String label,
    required IconData icon,
    required Color primaryColor,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        color: Colors.grey.shade500,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        fontFamily: 'Cairo',
        color: Colors.grey.shade300,
        fontSize: 13,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: primaryColor.withValues(alpha: 0.7)),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  // ─── Enhanced Stepper (Counter) ───────────────────────────────────────
  static Widget enhancedStepperField({
    required int value,
    required ValueChanged<int> onChanged,
    required Color primaryColor,
    required String label,
    String? description,
    int minValue = 1,
    int maxValue = 20,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.people_rounded, size: 20, color: primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF03121C),
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stepperButton(
                  icon: Icons.remove_rounded,
                  onPressed: value > minValue ? () => onChanged(value - 1) : null,
                  primaryColor: primaryColor,
                  isLeft: true,
                ),
                Container(
                  width: 44,
                  alignment: Alignment.center,
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                ),
                _stepperButton(
                  icon: Icons.add_rounded,
                  onPressed: value < maxValue ? () => onChanged(value + 1) : null,
                  primaryColor: primaryColor,
                  isLeft: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _stepperButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color primaryColor,
    required bool isLeft,
  }) {
    final disabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isLeft ? 0 : 12),
          bottomLeft: Radius.circular(isLeft ? 0 : 12),
          topRight: Radius.circular(isLeft ? 12 : 0),
          bottomRight: Radius.circular(isLeft ? 12 : 0),
        ),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: disabled
                ? Colors.grey.shade50
                : primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isLeft ? 0 : 11),
              bottomLeft: Radius.circular(isLeft ? 0 : 11),
              topRight: Radius.circular(isLeft ? 11 : 0),
              bottomRight: Radius.circular(isLeft ? 11 : 0),
            ),
          ),
          child: Icon(
            icon,
            size: 17,
            color: disabled ? Colors.grey.shade300 : primaryColor,
          ),
        ),
      ),
    );
  }

  // ─── Enhanced Date Field ──────────────────────────────────────────────
  static Widget enhancedDateField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    final hasDate = selectedDate != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: hasDate ? primaryColor.withValues(alpha: 0.04) : const Color(0xFFFAFBFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasDate ? primaryColor.withValues(alpha: 0.25) : Colors.grey.shade200,
              width: hasDate ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasDate
                      ? primaryColor.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: hasDate ? primaryColor : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: hasDate ? primaryColor.withValues(alpha: 0.7) : Colors.grey.shade400,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedDate == null
                          ? 'انقر لتحديد التاريخ'
                          : intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(selectedDate),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: selectedDate == null
                            ? Colors.grey.shade300
                            : const Color(0xFF03121C),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                hasDate ? Icons.edit_calendar_rounded : Icons.add_circle_outline_rounded,
                color: hasDate ? primaryColor.withValues(alpha: 0.6) : Colors.grey.shade300,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Enhanced Toggle (Switch) Field ──────────────────────────────────
  static Widget enhancedToggleField({
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color primaryColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? primaryColor.withValues(alpha: 0.04) : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? primaryColor.withValues(alpha: 0.25) : Colors.grey.shade200,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: value
                  ? primaryColor.withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              value ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
              size: 20,
              color: value ? primaryColor : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: value ? const Color(0xFF03121C) : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.88,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: primaryColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade200,
              trackOutlineColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? primaryColor.withValues(alpha: 0.3)
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
