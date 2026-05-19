import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/customs_bg.dart';
import 'package:flutter_app_liftmove/screens/calendar_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app_liftmove/screens/rutina_screen.dart';
import 'package:flutter_app_liftmove/screens/detalle_rutina_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_app_liftmove/core/Services/auth_service.dart';
import 'package:flutter_app_liftmove/core/api_config.dart'; // O la ruta exacta de tu ApiConfig

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _HomeContent(),
    const CalendarScreen(),
    const Center(child: Text('Stats')),
    const Center(child: Text('Perfil')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: AppColors.pinkie),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today, color: AppColors.pinkie),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart, color: AppColors.pinkie),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: AppColors.pinkie),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'HOME',
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
          Center(
            child: Column(
              children: [
                const SizedBox(height: 80),
                const DateDisplay(),
                const SizedBox(height: 30),
                Container(
                  width: 200,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.mainBlue, AppColors.oceanBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.babyGrey,
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RutinaScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar Rutina'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),

                // 🟢 LO NUEVO EMPIEZA AQUÍ: Justo debajo del botón de registrar
                const SizedBox(height: 30),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: (() async {
                      try {
                        final idUsu = await AuthService().getNombre();
                        if (idUsu == null) return [];
                        final fechaHoy = DateTime.now().toString().split(
                          ' ',
                        )[0]; // YYYY-MM-DD

                        final url = Uri.parse(
                          '${ApiConfig.baseUrl}/rutinas/$idUsu?fecha=$fechaHoy',
                        );
                        final response = await http.get(url);
                        if (response.statusCode == 200) {
                          return json.decode(response.body) as List<dynamic>;
                        }
                      } catch (e) {
                        print('Error cargando rutinas en Home: $e');
                      }
                      return [];
                    })(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final rutinasHoy = snapshot.data ?? [];

                      if (rutinasHoy.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Text(
                            '¡Hoy toca descanso! 💤',
                            style: TextStyle(
                              color: AppColors.darkPurple,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          const Text(
                            'Tus rutinas de hoy:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkPurple,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...rutinasHoy.map((rutina) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                // 🟢 BUSCA EL ONTAP EN EL HOME Y DÉJALO ASÍ:
                                onTap: () {
                                  // Solución definitiva para el tipo de dato
                                  final idRaw = rutina['idPlantilla'];
                                  final int idLimpio = idRaw is int
                                      ? idRaw
                                      : (int.tryParse(idRaw.toString()) ?? 0);

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
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.oceanBlue.withOpacity(
                                      0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center,
                                    color: AppColors.oceanBlue,
                                    size: 20,
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
                        ],
                      );
                    },
                  ),
                ),
                // 🟢 AQUÍ TERMINA LO NUEVO
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DateDisplay extends StatefulWidget {
  const DateDisplay({super.key});

  @override
  State<DateDisplay> createState() => _DateDisplayState();
}

class _DateDisplayState extends State<DateDisplay> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dia = DateFormat('dd').format(now);
    final mes = DateFormat('MMM', 'es').format(now).toUpperCase();
    final diaSemana = DateFormat('EEEE', 'es').format(now).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          diaSemana,
          style: const TextStyle(
            color: AppColors.darkerPink,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              dia,
              style: const TextStyle(
                color: AppColors.oceanBlue,
                fontSize: 52,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                mes,
                style: const TextStyle(
                  color: AppColors.lightPink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
