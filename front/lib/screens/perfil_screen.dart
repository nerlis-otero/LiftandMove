import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/customs_bg.dart';
import 'package:flutter_app_liftmove/core/api_config.dart';
import 'package:flutter_app_liftmove/core/Services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_app_liftmove/screens/login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _usuario;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final token = await AuthService().getToken();
      final url = Uri.parse('${ApiConfig.baseUrl}/me');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _usuario = json.decode(response.body);
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'PERFIL',
          style: TextStyle(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: AppColors.darkPurple,
            fontSize: 15,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const CustomBg(showLogo: false),
          SafeArea(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _usuario == null
                ? const Center(child: Text('Error cargando perfil'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Avatar
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.oceanBlue,
                          child: Text(
                            (_usuario!['nombreUsu'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _usuario!['nombreUsu'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkPurple,
                          ),
                        ),

                        Text(
                          _usuario!['correoUsu'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Tarjetas de datos
                        _buildInfoCard(
                          Icons.monitor_weight,
                          'Peso',
                          '${_usuario!['peso']} kg',
                        ),
                        _buildInfoCard(
                          Icons.height,
                          'Altura',
                          '${_usuario!['altura_cm']} cm',
                        ),
                        _buildInfoCard(
                          _usuario!['sexo'] == 'M' ? Icons.male : Icons.female,
                          'Sexo',
                          _usuario!['sexo'] == 'M' ? 'Masculino' : 'Femenino',
                        ),
                        _buildInfoCard(
                          Icons.flag,
                          'Objetivo',
                          _usuario!['objetivo_entreno'] ?? '-',
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await AuthService().logout();
                              if (mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Cerrar sesión'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.oceanBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.oceanBlue.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.oceanBlue, size: 22),
        ),
        title: Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.darkPurple,
          ),
        ),
      ),
    );
  }
}
