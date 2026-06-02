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

class ExportFolderRow extends StatelessWidget {
  final String path;
  final VoidCallback onChangeTap;

  const ExportFolderRow({
    super.key,
    required this.path,
    required this.onChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        const Icon(Icons.folder_rounded, size: 15, color: Color(0xFF888888)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            path.isNotEmpty ? path : 'لم يتم تحديد مجلد',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF888888)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        InkWell(
          onTap: onChangeTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
            child: Text('تغيير', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w700, color: primary)),
          ),
        ),
      ]),
    );
  }
}
