import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/student.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/phone_utils.dart';

class RegistrationMapScreen extends StatefulWidget {
  final List<Student> students;

  const RegistrationMapScreen({super.key, required this.students});

  @override
  State<RegistrationMapScreen> createState() => _RegistrationMapScreenState();
}

class _RegistrationMapScreenState extends State<RegistrationMapScreen> {
  late final List<Student> _mapped;

  @override
  void initState() {
    super.initState();
    _mapped = widget.students
        .where((s) => s.ipLat != null && s.ipLng != null)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_mapped.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('خريطة أماكن التسجيل', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('لا توجد بيانات مواقع حتى الآن',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey)),
              Text('ستظهر هنا أماكن تسجيل الطلاب من الموقع',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Average center
    var sumLat = 0.0, sumLng = 0.0;
    for (final s in _mapped) {
      sumLat += s.ipLat!;
      sumLng += s.ipLng!;
    }
    final center = LatLng(sumLat / _mapped.length, sumLng / _mapped.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('خريطة أماكن التسجيل (${_mapped.length} طالب)',
          style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 6.5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.musapaka.quran_contest_app',
          ),
          MarkerLayer(
            markers: _mapped.map((s) => Marker(
              point: LatLng(s.ipLat!, s.ipLng!),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => _showStudentInfo(context, s),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Text(_firstName(s),
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 10,
                          color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.location_on, color: Colors.red, size: 28),
                  ],
                ),
              ),
            )).toList(),
          ),
          RichAttributionWidget(
            attributions: const [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }

  String _firstName(Student s) => s.name.split(' ').first;

  void _showStudentInfo(BuildContext context, Student s) {
    final info = [
      'الاسم: ${s.name}',
      'الهاتف: ${s.phone}',
      'المستوى: ${s.level}',
      if (s.ipCity != null) 'المدينة: ${s.ipCity}',
      if (s.ipRegion != null) 'المنطقة: ${s.ipRegion}',
    ].join('\n');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.name, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text(info, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openWhatsApp(s.phone);
            },
            child: const Text('واتساب', style: TextStyle(fontFamily: 'Cairo', color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
