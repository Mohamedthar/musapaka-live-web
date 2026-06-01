import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/error/connectivity_service.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  final _service = ConnectivityService();
  bool _online = true;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _service.start();
    _online = _service.isOnline;
    _sub = _service.onStatusChanged.listen((online) {
      if (mounted) setState(() => _online = online);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_online)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 12, right: 12, top: 12,
              bottom: 8,
            ),
            color: const Color(0xFFD32F2F),
            child: const SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'لا يوجد اتصال بالإنترنت - البيانات قد لا تكون محدثة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_online)
          Material(
            color: const Color(0xFF2E7D32),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 0,
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
