import 'package:flutter/material.dart';

class ExportFilterLabel extends StatelessWidget {
  final String label;

  const ExportFilterLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'Cairo', 
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF03121C),
          ),
        ),
      ),
    );
  }
}

class ExportNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const ExportNumberField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
