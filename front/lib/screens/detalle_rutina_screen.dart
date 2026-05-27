import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/customs_bg.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/rounded_container.dart';
import 'package:flutter_app_liftmove/core/Services/auth_service.dart';
import 'package:flutter_app_liftmove/core/api_config.dart';

class DetalleRutinaScreen extends StatefulWidget {
  final String idPlantilla;
  final String nombreRutina;

  const DetalleRutinaScreen({
    super.key,
    required this.idPlantilla,
    required this.nombreRutina,
  });

  @override
  State<DetalleRutinaScreen> createState() => _DetalleRutinaScreenState();
}

class _DetalleRutinaScreenState extends State<DetalleRutinaScreen> {
  List<dynamic> _ejercicios = [];
  bool _cargando = true;
  bool _completada = false;
  String _fechaHoy = DateTime.now().toIso8601String().split('T')[0];
  String? _idUsu;

  @override
  void initState() {
    super.initState();
    _obtenerDetalleRutina();
    _verificarCompletada();
  }

  Future<void> _verificarCompletada() async {
    _idUsu = await AuthService().getNombre();
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/rutinas/${widget.idPlantilla}/completada?fecha=$_fechaHoy',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _completada = data['completada']);
      }
    } catch (e) {
      debugPrint('Error verificando completada: $e');
    }
  }

  Future<void> _toggleCompletar() async {
    if (_idUsu == null) return;
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/rutinas/${widget.idPlantilla}/completar',
      );
      final ejerciciosPayload = _ejercicios
          .map(
            (ej) => {
              'idEjercicio': ej['idEjercicio'],
              'series': ej['series'] ?? 0,
              'repeticiones': ej['repeticiones'] ?? 0,
              'peso_kg': (ej['peso'] as num?)?.toDouble() ?? 0.0,
            },
          )
          .toList();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idUsu': _idUsu,
          'fecha': _fechaHoy,
          'ejercicios': ejerciciosPayload,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nuevaCompletada = data['completada'] as bool;
        setState(() => _completada = nuevaCompletada);
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    nuevaCompletada
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    nuevaCompletada
                        ? '¡Sesión marcada como completada!'
                        : 'Sesión desmarcada',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor:
                  nuevaCompletada ? AppColors.berry : Colors.grey[600],
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error completando rutina: $e');
    }
  }

  Future<void> _eliminarRutina() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar rutina',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.darkPurple,
          ),
        ),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/rutinas/${widget.idPlantilla}',
      );
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rutina eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _obtenerDetalleRutina() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/rutinas/detalle/${widget.idPlantilla}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _ejercicios = json.decode(response.body);
          _cargando = false;
        });
      } else {
        setState(() => _cargando = false);
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
        title: Text(
          widget.nombreRutina.toUpperCase(),
          style: const TextStyle(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: AppColors.darkPurple,
            fontSize: 15,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkPurple),
        actions: [
          // Botón completar
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _completada
                    ? AppColors.berry.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: Icon(
                  _completada
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: _completada ? AppColors.berry : AppColors.darkPurple,
                ),
                onPressed: _toggleCompletar,
                tooltip: _completada
                    ? 'Marcar como no completada'
                    : 'Marcar como completada',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.darkPink),
              onPressed: _eliminarRutina,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const CustomBg(showLogo: false),
          SafeArea(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _ejercicios.isEmpty
                    ? Center(
                        child: RoundedContainer(
                          color: AppColors.blueishPurple.withOpacity(0.3),
                          child: const Text(
                            'Esta rutina no tiene ejercicios asignados.',
                            style: TextStyle(
                              color: AppColors.darkPurple,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _ejercicios.length,
                        itemBuilder: (context, index) {
                          final ej = _ejercicios[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.oceanBlue.withOpacity(0.09),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Número + nombre
                                  Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: AppColors.oceanBlue
                                              .withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.oceanBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          ej['nombreEj'] ?? 'Ejercicio',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.darkPurple,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Imagen
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 140,
                                      width: double.infinity,
                                      color: Colors.grey[100],
                                      child: Image.network(
                                        'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/${ej['idEjercicio'].toString().trim().replaceAll(' ', '_')}/0.jpg',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(
                                              Icons.fitness_center,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Stats
                                  Row(
                                    children: [
                                      _buildStatChip(
                                        Icons.repeat,
                                        'Sets',
                                        '${ej['series']}',
                                        AppColors.oceanBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatChip(
                                        Icons.loop,
                                        'Reps',
                                        '${ej['repeticiones']}',
                                        AppColors.berry,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatChip(
                                        Icons.fitness_center,
                                        'Peso',
                                        '${ej['peso']} kg',
                                        AppColors.darkerPink,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
