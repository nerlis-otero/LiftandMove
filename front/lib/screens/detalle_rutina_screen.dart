import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
// Asegúrate de importar la configuración de tu API aquí
// import 'package:flutter_app_liftmove/core/config/api_config.dart';

class DetalleRutinaScreen extends StatefulWidget {
  final int idPlantilla;
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

  @override
  void initState() {
    super.initState();
    _obtenerDetalleRutina();
  }

  Future<void> _obtenerDetalleRutina() async {
    try {
      // Reemplaza con tu variable global ApiConfig.baseUrl si la tienes activa.
      // Por ahora dejamos fija la IP dinámica .75 que usamos hoy
      final url = Uri.parse(
        'http://172.18.10.139:8000/rutinas/detalle/${widget.idPlantilla}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _ejercicios = json.decode(response.body);
          _cargando = false;
        });
      } else {
        print('Error en el servidor: ${response.statusCode}');
        setState(() {
          _cargando = false;
        });
      }
    } catch (e) {
      print('Error de conexión: $e');
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreRutina.toUpperCase()),
        backgroundColor: AppColors.oceanBlue,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _ejercicios.isEmpty
          ? const Center(
              child: Text('Esta rutina no tiene ejercicios asignados.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ejercicios.length,
              itemBuilder: (context, index) {
                final ej = _ejercicios[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ej['nombreEj'] ?? 'Ejercicio',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Imagen del ejercicio con tu lógica de limpieza de caracteres
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/${ej['idEjercicio'].toString().trim().replaceAll(' ', '_')}/0.jpg',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
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

                        // Detalles de Sets, Reps y Peso fijados
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('Sets', '${ej['series']}'),
                            _buildStatColumn('Reps', '${ej['repeticiones']}'),
                            _buildStatColumn('Peso', '${ej['peso']} kg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
