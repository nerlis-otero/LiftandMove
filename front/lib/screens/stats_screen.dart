import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/customs_bg.dart';
import 'package:flutter_app_liftmove/core/api_config.dart';
import 'package:flutter_app_liftmove/core/Services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  bool _cargando = true;
  String? _idUsu;
  String? _token;

  @override
  void initState() {
    super.initState();
    _cargarStats();
  }

  Future<void> _cargarStats() async {
    setState(() => _cargando = true);
    try {
      _idUsu = await AuthService().getNombre();
      _token = await AuthService().getToken();
      if (_idUsu == null || _token == null) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/stats/$_idUsu');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        setState(() => _stats = json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error cargando stats: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarMeta(String campo, double valor) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/stats/$_idUsu/meta');
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'campo': campo, 'valor': valor}),
      );
      if (response.statusCode == 200) {
        await _cargarStats();
      }
    } catch (e) {
      debugPrint('Error guardando meta: $e');
    }
  }

  void _mostrarDialogoMeta({
    required String titulo,
    required String campo,
    required String unidad,
    required bool esEntero,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Meta en $unidad',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixText: unidad,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx);
                _guardarMeta(campo, val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.oceanBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'ESTADÍSTICAS',
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
                : _stats == null
                ? const Center(child: Text('Error cargando estadísticas'))
                : RefreshIndicator(
                    onRefresh: _cargarStats,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── Resumen general ──
                          _buildResumenGeneral(),

                          const SizedBox(height: 20),

                          // ── Goals según objetivo ──
                          const Text(
                            'Mis metas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkPurple,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildGoalsSections(),

                          // ── Ejercicios por tipo ──
                          if ((_stats!['por_tipo'] as List).isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Ejercicios por categoría',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkPurple,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPorTipo(),
                          ],

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Resumen general ──────────────────────────────────────────────────────────
  Widget _buildResumenGeneral() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.fitness_center,
            'Rutinas\nregistradas',
            '${_stats!['total_rutinas']}',
            AppColors.oceanBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.calendar_today,
            'Días activos\nesta semana',
            '${_stats!['dias_semana_activos']}',
            AppColors.berry,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Goals según objetivos ────────────────────────────────────────────────────
  Widget _buildGoalsSections() {
    final objetivos = (_stats!['objetivo_entreno'] as String? ?? '').split(
      ', ',
    );
    final widgets = <Widget>[];

    for (final obj in objetivos) {
      final trimmed = obj.trim();
      if (trimmed == 'Perder peso') {
        widgets.add(_buildGoalPerderPeso());
        widgets.add(const SizedBox(height: 12));
      } else if (trimmed == 'Ganar músculo') {
        widgets.add(_buildGoalGanarMusculo());
        widgets.add(const SizedBox(height: 12));
      } else if (trimmed == 'Ganar fuerza') {
        widgets.add(_buildGoalGanarFuerza());
        widgets.add(const SizedBox(height: 12));
      } else if (trimmed == 'Ser más flexible') {
        widgets.add(_buildGoalFlexibilidad());
        widgets.add(const SizedBox(height: 12));
      }
    }

    if (widgets.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No tienes objetivos registrados.'),
        ),
      );
    }

    return Column(children: widgets);
  }

  // ── Goal: Perder peso ────────────────────────────────────────────────────────
  Widget _buildGoalPerderPeso() {
    final pesoActual = (_stats!['peso_actual'] as num?)?.toDouble() ?? 0;
    final pesoObjetivo = (_stats!['peso_objetivo'] as num?)?.toDouble();
    final tieneMeta = pesoObjetivo != null && pesoObjetivo > 0;

    double progreso = 0;
    if (tieneMeta && pesoActual > pesoObjetivo) {
      // Cuánto le falta bajar
      final totalBajar = pesoActual - pesoObjetivo;
      // Como no tenemos histórico, mostramos 0% hasta que actualice su peso
      progreso = 0;
    } else if (tieneMeta && pesoActual <= pesoObjetivo) {
      progreso = 1.0; // Meta alcanzada
    }

    return _buildGoalCard(
      titulo: 'Perder peso',
      color: AppColors.darkerPink,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(
                'Peso actual',
                '${pesoActual.toStringAsFixed(1)} kg',
              ),
              _buildMiniStat(
                'Meta',
                tieneMeta ? '${pesoObjetivo!.toStringAsFixed(1)} kg' : '—',
              ),
              _buildMiniStat(
                'Por bajar',
                tieneMeta && pesoActual > pesoObjetivo!
                    ? '${(pesoActual - pesoObjetivo).toStringAsFixed(1)} kg'
                    : tieneMeta
                    ? '¡Meta!'
                    : '—',
              ),
            ],
          ),
          if (tieneMeta) ...[
            const SizedBox(height: 12),
            _buildBarraProgreso(
              tieneMeta && pesoActual <= pesoObjetivo! ? 1.0 : 0.0,
              AppColors.darkerPink,
            ),
          ],
          const SizedBox(height: 12),
          _buildBotonMeta(
            label: tieneMeta ? 'Actualizar meta' : 'Definir meta',
            onTap: () => _mostrarDialogoMeta(
              titulo: 'Meta de peso',
              campo: 'peso_objetivo',
              unidad: 'kg',
              esEntero: false,
            ),
          ),
        ],
      ),
    );
  }

  // ── Goal: Ganar músculo ──────────────────────────────────────────────────────
  Widget _buildGoalGanarMusculo() {
    final seriesActuales =
        (_stats!['series_esta_semana'] as num?)?.toInt() ?? 0;
    final metaSeries = (_stats!['meta_series_semanales'] as num?)?.toInt();
    final tieneMeta = metaSeries != null && metaSeries > 0;
    final progreso = tieneMeta
        ? (seriesActuales / metaSeries!).clamp(0.0, 1.0)
        : 0.0;

    return _buildGoalCard(
      titulo: 'Ganar músculo',
      color: AppColors.oceanBlue,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Series esta semana', '$seriesActuales'),
              _buildMiniStat('Meta semanal', tieneMeta ? '$metaSeries' : '—'),
              _buildMiniStat(
                'Progreso',
                tieneMeta ? '${(progreso * 100).toStringAsFixed(0)}%' : '—',
              ),
            ],
          ),
          if (tieneMeta) ...[
            const SizedBox(height: 12),
            _buildBarraProgreso(progreso, AppColors.oceanBlue),
          ],
          const SizedBox(height: 12),
          _buildBotonMeta(
            label: tieneMeta ? 'Actualizar meta' : 'Definir meta',
            onTap: () => _mostrarDialogoMeta(
              titulo: 'Meta de series semanales',
              campo: 'meta_series_semanales',
              unidad: 'series',
              esEntero: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── Goal: Ganar fuerza ───────────────────────────────────────────────────────
  Widget _buildGoalGanarFuerza() {
    final pesoMax = (_stats!['peso_max_levantado'] as num?)?.toDouble() ?? 0;
    final metaPeso = (_stats!['meta_peso_maximo'] as num?)?.toDouble();
    final tieneMeta = metaPeso != null && metaPeso > 0;
    final progreso = tieneMeta ? (pesoMax / metaPeso!).clamp(0.0, 1.0) : 0.0;

    return _buildGoalCard(
      titulo: 'Ganar fuerza',
      color: Color(0xFF7B5EA7),
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Peso máx.', '${pesoMax.toStringAsFixed(1)} kg'),
              _buildMiniStat(
                'Meta',
                tieneMeta ? '${metaPeso!.toStringAsFixed(1)} kg' : '—',
              ),
              _buildMiniStat(
                'Progreso',
                tieneMeta ? '${(progreso * 100).toStringAsFixed(0)}%' : '—',
              ),
            ],
          ),
          if (tieneMeta) ...[
            const SizedBox(height: 12),
            _buildBarraProgreso(progreso, const Color(0xFF7B5EA7)),
          ],
          const SizedBox(height: 12),
          _buildBotonMeta(
            label: tieneMeta ? 'Actualizar meta' : 'Definir meta',
            onTap: () => _mostrarDialogoMeta(
              titulo: 'Meta de peso máximo',
              campo: 'meta_peso_maximo',
              unidad: 'kg',
              esEntero: false,
            ),
          ),
        ],
      ),
    );
  }

  // ── Goal: Ser más flexible ───────────────────────────────────────────────────
  Widget _buildGoalFlexibilidad() {
    final diasActivos = (_stats!['dias_semana_activos'] as num?)?.toInt() ?? 0;
    final metaDias = (_stats!['meta_dias_semana'] as num?)?.toInt();
    final tieneMeta = metaDias != null && metaDias > 0;
    final progreso = tieneMeta
        ? (diasActivos / metaDias!).clamp(0.0, 1.0)
        : 0.0;

    return _buildGoalCard(
      titulo: 'Ser más flexible',
      color: Colors.teal,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Días esta semana', '$diasActivos'),
              _buildMiniStat(
                'Meta semanal',
                tieneMeta ? '$metaDias días' : '—',
              ),
              _buildMiniStat(
                'Progreso',
                tieneMeta ? '${(progreso * 100).toStringAsFixed(0)}%' : '—',
              ),
            ],
          ),
          if (tieneMeta) ...[
            const SizedBox(height: 12),
            _buildBarraProgreso(progreso, Colors.teal),
          ],
          const SizedBox(height: 12),
          _buildBotonMeta(
            label: tieneMeta ? 'Actualizar meta' : 'Definir meta',
            onTap: () => _mostrarDialogoMeta(
              titulo: 'Meta de días por semana',
              campo: 'meta_dias_semana',
              unidad: 'días',
              esEntero: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── Ejercicios por tipo ──────────────────────────────────────────────────────
  Widget _buildPorTipo() {
    final lista = _stats!['por_tipo'] as List;
    final total = lista.fold<int>(0, (sum, e) => sum + (e['total'] as int));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: lista.map((e) {
            final pct = total > 0 ? (e['total'] as int) / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e['tipo'] ?? 'Sin tipo',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${e['total']} ejerc.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildBarraProgreso(pct, AppColors.oceanBlue),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Widgets helpers ──────────────────────────────────────────────────────────
  Widget _buildGoalCard({
    required String titulo,
    required Color color,
    required Widget contenido,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            contenido,
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBarraProgreso(double valor, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: valor,
        minHeight: 10,
        backgroundColor: color.withOpacity(0.15),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildBotonMeta({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.oceanBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label, style: const TextStyle(color: AppColors.oceanBlue)),
      ),
    );
  }
}
