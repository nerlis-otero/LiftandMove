import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
import 'package:flutter_app_liftmove/core/api_config.dart';
import 'package:flutter_app_liftmove/core/Services/auth_service.dart';
import 'package:flutter_app_liftmove/widgets/body_muscle_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class RutinaScreen extends StatefulWidget {
  const RutinaScreen({super.key});

  @override
  State<RutinaScreen> createState() => _RutinaScreenState();
}

class _RutinaScreenState extends State<RutinaScreen> {
  final TextEditingController _nombreRutinaController = TextEditingController();

  List<dynamic> _ejerciciosEncontrados = [];
  final List<dynamic> _ejerciciosSeleccionados = [];
  String? _musculoSeleccionadoId;
  bool _cargandoEjercicios = false;

  final Set<int> _diasSeleccionados = {};
  final List<String> _nombresDias = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 30));

  bool _guardando = false;
  String? _idUsu;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final nombre = await AuthService().getNombre();
    setState(() => _idUsu = nombre);
  }

  Future<void> _cargarEjerciciosPorMusculo(MuscleRegion region) async {
    setState(() {
      _musculoSeleccionadoId = region.id;
      _cargandoEjercicios = true;
      _ejerciciosEncontrados = [];
    });

    try {
      final Uri url;
      if (region.primaryMuscles.length == 1) {
        final musculo = Uri.encodeQueryComponent(region.primaryMuscles.first);
        url = Uri.parse(
          '${ApiConfig.baseUrl}/ejercicios/por-musculo?musculo=$musculo&limit=40',
        );
      } else {
        final musculos = region.primaryMuscles
            .map(Uri.encodeQueryComponent)
            .join(',');
        url = Uri.parse(
          '${ApiConfig.baseUrl}/ejercicios/por-musculos?musculos=$musculos&limit=40',
        );
      }

      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() => _ejerciciosEncontrados = json.decode(response.body));
      } else {
        _snack('No se pudieron cargar los ejercicios');
      }
    } catch (e) {
      debugPrint('Error al cargar por músculo: $e');
      _snack('Error de conexión al cargar ejercicios');
    } finally {
      if (mounted) setState(() => _cargandoEjercicios = false);
    }
  }

  void _onMusculoSeleccionado(MuscleRegion region) {
    if (_musculoSeleccionadoId == region.id) {
      setState(() {
        _musculoSeleccionadoId = null;
        _ejerciciosEncontrados = [];
      });
      return;
    }
    _cargarEjerciciosPorMusculo(region);
  }

  void _agregarEjercicio(Map<String, dynamic> ejercicio) {
    bool yaExiste = _ejerciciosSeleccionados.any(
      (e) => e['idEjercicio'] == ejercicio['idEjercicio'],
    );
    if (!yaExiste) {
      setState(() {
        _ejerciciosSeleccionados.add({
          'idEjercicio': ejercicio['idEjercicio'],
          'nombreEj': ejercicio['nombreEj'],
          'tipo': ejercicio['tipo'],
          'series': TextEditingController(),
          'repeticiones': TextEditingController(),
          'peso': TextEditingController(),
        });
        _ejerciciosEncontrados = [];
      });
    } else {
      _snack('Este ejercicio ya está en tu rutina');
    }
  }

  Future<void> _seleccionarFecha({required bool esInicio}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
          if (_fechaInicio.isAfter(_fechaFin)) {
            _fechaFin = _fechaInicio.add(const Duration(days: 7));
          }
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _guardarRutina() async {
    if (_idUsu == null) {
      _snack('No se pudo obtener el usuario. Vuelve a iniciar sesión.');
      return;
    }
    if (_nombreRutinaController.text.trim().isEmpty) {
      _snack('Ponle un nombre a tu rutina');
      return;
    }
    if (_diasSeleccionados.isEmpty) {
      _snack('Selecciona al menos un día de la semana');
      return;
    }
    if (_fechaFin.isBefore(_fechaInicio)) {
      _snack('La fecha fin no puede ser antes de la fecha inicio');
      return;
    }
    if (_ejerciciosSeleccionados.isEmpty) {
      _snack('Agrega al menos un ejercicio');
      return;
    }

    setState(() => _guardando = true);

    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final ejercicios = _ejerciciosSeleccionados
          .map(
            (ej) => {
              'idEjercicio': ej['idEjercicio'],
              'series': int.tryParse(ej['series'].text) ?? 0,
              'repeticiones': int.tryParse(ej['repeticiones'].text) ?? 0,
              'peso_kg': double.tryParse(ej['peso'].text) ?? 0.0,
            },
          )
          .toList();

      final body = json.encode({
        'idUsu': _idUsu,
        'nombre': _nombreRutinaController.text.trim(),
        'fecha_inicio': fmt.format(_fechaInicio),
        'fecha_fin': fmt.format(_fechaFin),
        'dias_semana': _diasSeleccionados.toList()..sort(),
        'ejercicios': ejercicios,
      });

      final token = await AuthService().getToken(); // ← agregar esto antes

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/rutinas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ← agregar esto
        },
        body: body,
      );

      if (response.statusCode == 200) {
        _snack('Rutina guardada!', color: Colors.green);
        if (mounted) Navigator.pop(context);
      } else {
        final err = json.decode(response.body);
        _snack('Error: ${err['detail'] ?? 'desconocido'}');
      }
    } catch (e) {
      _snack('Error de conexión: $e');
    } finally {
      setState(() => _guardando = false);
    }
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Registrar Rutina',
          style: TextStyle(color: Color.fromARGB(255, 247, 249, 251)),
        ),
        backgroundColor: AppColors.oceanBlue,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Nombre ──
              TextField(
                controller: _nombreRutinaController,
                decoration: InputDecoration(
                  hintText: 'Nombre de la rutina (ej. Pecho y Tríceps)',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Días ──
              const Text(
                '¿Qué días se repite?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final sel = _diasSeleccionados.contains(i);
                  return GestureDetector(
                    onTap: () => setState(
                      () => sel
                          ? _diasSeleccionados.remove(i)
                          : _diasSeleccionados.add(i),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.oceanBlue : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _nombresDias[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sel ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // ── Fechas ──
              const Text(
                '¿Durante qué período?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _botonFecha(
                      label: 'Inicio',
                      fecha: fmt.format(_fechaInicio),
                      onTap: () => _seleccionarFecha(esInicio: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _botonFecha(
                      label: 'Fin',
                      fecha: fmt.format(_fechaFin),
                      onTap: () => _seleccionarFecha(esInicio: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Selector corporal ──
              const Text(
                'Añadir ejercicios:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              BodyMusclePicker(
                selectedId: _musculoSeleccionadoId,
                onRegionSelected: _onMusculoSeleccionado,
              ),
              if (_cargandoEjercicios)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_musculoSeleccionadoId != null &&
                  _ejerciciosEncontrados.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No hay ejercicios con ese músculo primario.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_ejerciciosEncontrados.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.oceanBlue.withValues(alpha: 0.25),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: _ejerciciosEncontrados.length,
                    itemBuilder: (context, i) {
                      final ej = _ejerciciosEncontrados[i];
                      return ListTile(
                        dense: true,
                        title: Text(ej['nombreEj'] ?? 'Sin nombre'),
                        subtitle: Text(ej['tipo'] ?? ''),
                        trailing: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.green,
                        ),
                        onTap: () => _agregarEjercicio(ej),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),

              // ── Lista ejercicios seleccionados ──
              if (_ejerciciosSeleccionados.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Aún no has agregado ejercicios.')),
                )
              else
                ListView.builder(
                  shrinkWrap: true, // 👈 clave: no necesita altura fija
                  physics:
                      const NeverScrollableScrollPhysics(), // 👈 el scroll lo maneja el padre
                  itemCount: _ejerciciosSeleccionados.length,
                  itemBuilder: (context, index) {
                    final sel = _ejerciciosSeleccionados[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    sel['nombreEj'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _ejerciciosSeleccionados.removeAt(
                                      index,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              sel['tipo'] ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 100,
                                width: double.infinity,
                                child: Image.network(
                                  'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/${sel['idEjercicio'].toString().trim().replaceAll(' ', '_')}/0.jpg',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(
                                        Icons.fitness_center,
                                        size: 36,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _campoNum(sel['series'], 'Sets'),
                                const SizedBox(width: 8),
                                _campoNum(sel['repeticiones'], 'Reps'),
                                const SizedBox(width: 8),
                                _campoNum(sel['peso'], 'Peso kg'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // ── Botón Guardar ──
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardarRutina,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar Rutina'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.oceanBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonFecha({
    required String label,
    required String fecha,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  fecha,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoNum(TextEditingController controller, String label) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: '0',
          isDense: true,
        ),
      ),
    );
  }
}
