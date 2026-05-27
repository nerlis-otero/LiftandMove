import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Agrégale el /api al final si tu backend lo requiere para los endpoints
  static const String _productionUrl = "https://liftandmove.onrender.com";

  static String get baseUrl => _productionUrl;
}
