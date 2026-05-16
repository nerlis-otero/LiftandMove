import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/customs_bg.dart';
// ignore: unused_import
import 'package:flutter_svg/svg.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/rounded_container.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _diaSeleccionado = DateTime.now();
  DateTime _mesFocused = DateTime.now();

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
                        },
                        calendarStyle: CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: AppColors.oceanBlue.withOpacity(0.7),
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RoundedContainer(
                      color: AppColors.oceanBlue.withOpacity(0.7),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/workout2.svg',
                            width: 40, // ← reducido de 60
                            height: 40,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            // ← envuelve el Text con Flexible
                            child: Text(
                              'Rutinas del ${_diaSeleccionado.day}/${_diaSeleccionado.month}/${_diaSeleccionado.year}',
                              style: TextStyle(
                                color: AppColors.whiteHlight,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis, // ← por si acaso
                            ),
                          ),
                          const SizedBox(width: 8),
                          SvgPicture.asset(
                            'assets/images/workout1.svg',
                            width: 40, // ← reducido de 60
                            height: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'No hay rutinas este día',
                      style: TextStyle(color: AppColors.blueishPurple),
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
}
