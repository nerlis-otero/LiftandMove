import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/customs_bg.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/rounded_container.dart';
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

      final token = await AuthService().getToken();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/rutinas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        _snack('Rutina guardada!', color: AppColors.mainBlue);
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
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'NUEVA RUTINA',
          style: TextStyle(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: AppColors.darkPurple,
            fontSize: 15,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkPurple),
      ),
      body: Stack(
        children: [
          const CustomBg(showLogo: false),
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Nombre ──
                    RoundedContainer(
                      color: AppColors.blueishPurple.withOpacity(0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nombre de la rutina',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkPurple,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nombreRutinaController,
                            decoration: InputDecoration(
                              hintText: 'Ej. Pecho y Tríceps',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: const Icon(
                                Icons.edit,
                                color: AppColors.oceanBlue,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.85),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Días ──
                    RoundedContainer(
                      color: AppColors.blueishPurple.withOpacity(0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Qué días se repite?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkPurple,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.darkerPink
                                        : Colors.white.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                    boxShadow: sel
                                        ? [
                                            BoxShadow(
                                              color: AppColors.darkerPink
                                                  .withOpacity(0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _nombresDias[i],
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: sel
                                            ? Colors.white
                                            : AppColors.darkPurple,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Fechas ──
                    RoundedContainer(
                      color: AppColors.blueishPurple.withOpacity(0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Durante qué período?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkPurple,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _botonFecha(
                                  label: 'Inicio',
                                  fecha: fmt.format(_fechaInicio),
                                  onTap: () =>
                                      _seleccionarFecha(esInicio: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _botonFecha(
                                  label: 'Fin',
                                  fecha: fmt.format(_fechaFin),
                                  onTap: () =>
                                      _seleccionarFecha(esInicio: false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Selector corporal ──
                    RoundedContainer(
                      color: AppColors.blueishPurple.withOpacity(0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Añadir ejercicios',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkPurple,
                              letterSpacing: 0.5,
                            ),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No hay ejercicios con ese músculo primario.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (_ejerciciosEncontrados.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.oceanBlue.withOpacity(0.2),
                                ),
                              ),
                              child: ListView.builder(
                                itemCount: _ejerciciosEncontrados.length,
                                itemBuilder: (context, i) {
                                  final ej = _ejerciciosEncontrados[i];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      ej['nombreEj'] ?? 'Sin nombre',
                                      style: const TextStyle(
                                        color: AppColors.darkPurple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      ej['tipo'] ?? '',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11),
                                    ),
                                    trailing: const Icon(
                                      Icons.add_circle_outline,
                                      color: AppColors.berry,
                                    ),
                                    onTap: () => _agregarEjercicio(ej),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Lista ejercicios seleccionados ──
                    if (_ejerciciosSeleccionados.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            'Aún no has agregado ejercicios.',
                            style: TextStyle(
                              color: AppColors.blueishPurple,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ejerciciosSeleccionados.length,
                        itemBuilder: (context, index) {
                          final sel = _ejerciciosSeleccionados[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.oceanBlue.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          sel['nombreEj'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.darkPurple,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: AppColors.darkPink,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                          () => _ejerciciosSeleccionados
                                              .removeAt(index),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    sel['tipo'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      height: 100,
                                      width: double.infinity,
                                      child: Image.network(
                                        'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/${sel['idEjercicio'].toString().trim().replaceAll(' ', '_')}/0.jpg',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          color: Colors.grey[100],
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
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _campoNum(sel['series'], 'Sets'),
                                      const SizedBox(width: 8),
                                      _campoNum(
                                          sel['repeticiones'], 'Reps'),
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
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.oceanBlue, AppColors.mainBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.oceanBlue.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
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
                        label: Text(
                          _guardando ? 'Guardando...' : 'Guardar Rutina',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
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
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.oceanBlue.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 16, color: AppColors.oceanBlue),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.blueishPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  fecha,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.darkPurple,
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
        style: const TextStyle(
          color: AppColors.darkPurple,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.blueishPurple,
            fontSize: 12,
          ),
          hintText: '0',
          isDense: true,
          filled: true,
          fillColor: Colors.white.withOpacity(0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}
