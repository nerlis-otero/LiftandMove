import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_app_liftmove/core/api_config.dart';

class AdminService {
  static final _storage = const FlutterSecureStorage();

  static Future<String?> _getToken() => _storage.read(key: 'access_token');

  static Future<bool> esAdmin() async {
    final esAdminStr = await _storage.read(key: 'esAdmin');
    return esAdminStr == 'true';
  }

  static Future<List<Map<String, dynamic>>> getUsuarios() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/usuarios'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Error al cargar usuarios');
  }

  static Future<void> eliminarUsuario(String idUsu) async {
    final token = await _getToken();
    print('TOKEN AL ELIMINAR: $token');
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/usuarios/$idUsu'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('STATUS: ${response.statusCode}');
  }
}
