import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const bool _usePhysicalDevice =
      true; // Cambia a true si quieres usar la IP fija en dispositivos físicos

  // IP
  static const String _myIP = "192.168.1.60";

  static String get baseUrl {
    // WEB
    if (kIsWeb) return "http://localhost:8000";

    // ANDROID
    if (Platform.isAndroid) {
      return _usePhysicalDevice ? "http://$_myIP:8000" : "http://10.0.2.2:8000";
    }

    // IOS
    if (Platform.isIOS) {
      return _usePhysicalDevice
          ? "http://$_myIP:8000"
          : "http://localhost:8000";
    }

    return "http://localhost:8000";
  }
}
