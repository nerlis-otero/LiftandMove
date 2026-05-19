import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/customs_bg.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/rounded_container.dart';
import 'package:flutter_app_liftmove/core/api_config.dart';
import 'package:flutter_app_liftmove/core/Services/auth_service.dart';
import 'package:flutter_svg/svg.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_app_liftmove/screens/detalle_rutina_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _diaSeleccionado = DateTime.now();
  DateTime _mesFocused = DateTime.now();
  List<dynamic> _rutinasDelDia = [];
  bool _cargando = false;
  String? _idUsu;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final nombre = await AuthService().getNombre();
    setState(() => _idUsu = nombre);
    _cargarRutinas(_diaSeleccionado);
  }

  Future<void> _cargarRutinas(DateTime dia) async {
    if (_idUsu == null) return;
    setState(() => _cargando = true);
    try {
      final fecha = DateFormat('yyyy-MM-dd').format(dia);
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/rutinas/$_idUsu?fecha=$fecha',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() => _rutinasDelDia = json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error cargando rutinas: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'CALENDARIO',
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Calendario ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RoundedContainer(
                      color: AppColors.blueishPurple.withOpacity(0.3),
                      child: TableCalendar(
                        firstDay: DateTime(2024, 1, 1),
                        lastDay: DateTime(2040, 12, 31),
                        focusedDay: _mesFocused,
                        selectedDayPredicate: (day) =>
                            isSameDay(_diaSeleccionado, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _diaSeleccionado = selectedDay;
                            _mesFocused = focusedDay;
                          });
                          _cargarRutinas(selectedDay);
                        },
                        calendarStyle: CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: AppColors.oceanBlue,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppColors.berry,
                            shape: BoxShape.circle,
                          ),
                          weekendTextStyle: TextStyle(
                            color: AppColors.darkerPink,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            color: AppColors.darkPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Header rutinas ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RoundedContainer(
                      color: AppColors.oceanBlue,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/workout2.svg',
                            width: 40,
                            height: 40,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Rutinas del ${_diaSeleccionado.day}/${_diaSeleccionado.month}/${_diaSeleccionado.year}',
                              style: TextStyle(
                                color: AppColors.whiteHlight,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SvgPicture.asset(
                            'assets/images/workout1.svg',
                            width: 40,
                            height: 40,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Rutinas del día ──
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    )
                  else if (_rutinasDelDia.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay rutinas este día',
                        style: TextStyle(color: AppColors.blueishPurple),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: _rutinasDelDia.map((rutina) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              // 🟢 AGREGAMOS ESTE bloque onTap AQUÍ:
                              // 🟢 BUSCA EL ONTAP QUE METIMOS EN EL CALENDAR Y DÉJALO ASÍ:
                              onTap: () {
                                final String idLimpio = rutina['idPlantilla']
                                    .toString();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleRutinaScreen(
                                      idPlantilla: idLimpio,
                                      nombreRutina:
                                          rutina['nombre'] ?? 'Sin nombre',
                                    ),
                                  ),
                                );
                              },
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.oceanBlue.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: AppColors.oceanBlue,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                rutina['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${rutina['total_ejercicios']} ejercicio(s)',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
