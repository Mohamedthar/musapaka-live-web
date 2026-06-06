import 'dart:async';
import 'dart:io';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;
  Timer? _checkTimer;

  Stream<bool> get onStatusChanged => _controller.stream;
  bool get isOnline => _isOnline;

  void start({Duration interval = const Duration(seconds: 10)}) {
    _checkNow();
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(interval, (_) => _checkNow());
  }

  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<void> _checkNow() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        _controller.add(false);
      }
    }
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
