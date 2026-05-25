import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/customs_bg.dart';
import 'guards/admin_guard.dart';
import 'screens/users_screen.dart';
import 'package:flutter_app_liftmove/admin/services/admin_service.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [UsersScreen(), DashboardScreen()];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.people_alt_rounded, label: 'Usuarios'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Dashboard'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'PANEL ADMIN',
            style: TextStyle(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: AppColors.darkPurple,
              fontSize: 15,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.oceanBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 14,
                      color: AppColors.oceanBlue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Admin',
                      style: TextStyle(
                        color: AppColors.oceanBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            const CustomBg(showLogo: false),
            SafeArea(child: _screens[_selectedIndex]),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.babyGrey.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final selected = _selectedIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.oceanBlue.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: selected
                                ? AppColors.oceanBlue
                                : AppColors.greyPurple.withOpacity(0.5),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 6),
                            Text(
                              item.label,
                              style: const TextStyle(
                                color: AppColors.oceanBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ── Reemplaza la clase DashboardScreen en admin_panel.dart ──────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final lista = await AdminService.getUsuarios();
      setState(() => _usuarios = lista);
    } catch (_) {
    } finally {
      setState(() => _cargando = false);
    }
  }

  // ── Cálculos derivados ────────────────────────────────────────────────────
  int get _totalUsuarios => _usuarios.length;
  int get _totalAdmins =>
      _usuarios.where((u) => u['esAdmin'] == 1 || u['esAdmin'] == true).length;
  int get _totalNormales => _totalUsuarios - _totalAdmins;

  int get _masculinos => _usuarios.where((u) => u['sexo'] == 'M').length;
  int get _femeninos => _usuarios.where((u) => u['sexo'] == 'F').length;

  double get _pesoPromedio {
    final conPeso = _usuarios
        .where((u) => u['peso'] != null && u['peso'] > 0)
        .toList();
    if (conPeso.isEmpty) return 0;
    final suma = conPeso.fold<double>(
      0,
      (s, u) => s + (u['peso'] as num).toDouble(),
    );
    return suma / conPeso.length;
  }

  double get _alturaPromedio {
    final conAltura = _usuarios
        .where((u) => u['altura_cm'] != null && u['altura_cm'] > 0)
        .toList();
    if (conAltura.isEmpty) return 0;
    final suma = conAltura.fold<double>(
      0,
      (s, u) => s + (u['altura_cm'] as num).toDouble(),
    );
    return suma / conAltura.length;
  }

  Map<String, int> get _objetivosCont {
    final Map<String, int> map = {};
    for (final u in _usuarios) {
      final obj = (u['objetivo_entreno'] as String? ?? 'Sin objetivo').trim();
      if (obj.isEmpty) {
        map['Sin objetivo'] = (map['Sin objetivo'] ?? 0) + 1;
      } else {
        // Puede venir como "Perder peso, Ganar músculo" → split
        for (final parte in obj.split(',')) {
          final k = parte.trim();
          if (k.isNotEmpty) map[k] = (map[k] ?? 0) + 1;
        }
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final objetivos = _objetivosCont;
    final maxObj = objetivos.values.fold(0, (m, v) => v > m ? v : m);

    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppColors.oceanBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título sección ─────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(bottom: 14, top: 4),
              child: Text(
                'Resumen general',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.lightPink,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // ── Fila 1: Tarjetas principales ───────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.people_alt_rounded,
                    label: 'Total usuarios',
                    value: '$_totalUsuarios',
                    color: AppColors.oceanBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.shield_rounded,
                    label: 'Admins',
                    value: '$_totalAdmins',
                    color: AppColors.periwinkle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.person_rounded,
                    label: 'Usuarios',
                    value: '$_totalNormales',
                    color: AppColors.mainBlue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Fila 2: Peso y altura ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.monitor_weight_rounded,
                    label: 'Peso promedio',
                    value: '${_pesoPromedio.toStringAsFixed(1)} kg',
                    color: const Color(0xFF7B5EA7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.height_rounded,
                    label: 'Altura promedio',
                    value: '${_alturaPromedio.toStringAsFixed(0)} cm',
                    color: Colors.teal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Distribución por sexo ──────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Distribución por sexo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.lightPink,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.babyGrey.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _GenderBar(
                      icon: Icons.male_rounded,
                      label: 'Masculino',
                      count: _masculinos,
                      total: _totalUsuarios,
                      color: AppColors.mainBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _GenderBar(
                      icon: Icons.female_rounded,
                      label: 'Femenino',
                      count: _femeninos,
                      total: _totalUsuarios,
                      color: AppColors.berry,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Objetivos de entrenamiento ─────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Objetivos de entrenamiento',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.lightPink,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.babyGrey.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: objetivos.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin datos aún',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Column(
                      children: objetivos.entries.map((entry) {
                        final pct = maxObj > 0 ? entry.value / maxObj : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkPurple,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${entry.value} usuarios',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: pct),
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, val, __) =>
                                      LinearProgressIndicator(
                                        value: val,
                                        minHeight: 9,
                                        backgroundColor: AppColors.oceanBlue
                                            .withOpacity(0.1),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              AppColors.oceanBlue,
                                            ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 20),

            // ── Lista reciente ─────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Últimos usuarios registrados',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.lightPink,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.babyGrey.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: _usuarios.reversed.take(5).map((u) {
                  final esAdmin = u['esAdmin'] == 1 || u['esAdmin'] == true;
                  final inicial = (u['nombreUsu'] ?? '?')[0].toUpperCase();
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.oceanBlue.withOpacity(0.15),
                      child: Text(
                        inicial,
                        style: const TextStyle(
                          color: AppColors.oceanBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      u['nombreUsu'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.darkPurple,
                      ),
                    ),
                    subtitle: Text(
                      u['objetivo_entreno'] ?? 'Sin objetivo',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.greyPurple.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: esAdmin
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.oceanBlue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.oceanBlue,
                              ),
                            ),
                          )
                        : Icon(
                            u['sexo'] == 'M'
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            color: u['sexo'] == 'M'
                                ? AppColors.mainBlue
                                : AppColors.berry,
                          ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets helper ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.babyGrey.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final int total;
  final Color color;

  const _GenderBar({
    required this.icon,
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    final pctStr = '${(pct * 100).toStringAsFixed(0)}%';

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.darkPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => LinearProgressIndicator(
              value: val,
              minHeight: 9,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            pctStr,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }
}

@override
Widget build(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.oceanBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.bar_chart_rounded,
            size: 48,
            color: AppColors.oceanBlue,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkPurple,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Próximamente',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.greyPurple.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}
