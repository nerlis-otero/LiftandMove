import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
import 'package:flutter_app_liftmove/core/theme/widgets/customs_bg.dart';
import 'package:flutter_app_liftmove/core/api_config.dart';
import 'package:flutter_app_liftmove/core/Services/auth_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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

  List<dynamic> _ejerciciosHistorial = [];
  String? _ejercicioSeleccionadoId;
  List<dynamic> _historialCargas = [];
  bool _cargandoCargas = false;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    await _cargarStats();
    await _cargarEjerciciosHistorial();
  }

  Future<void> _cargarStats() async {
    setState(() => _cargando = true);
    try {
      _idUsu = await AuthService().getNombre();
      _token = await AuthService().getToken();
      if (_idUsu == null || _token == null) {
        // ← AGREGA estas líneas
        debugPrint(
          'Stats: sesión no disponible (_idUsu=$_idUsu, token=$_token)',
        );
        return; // _stats queda null → muestra "Error cargando estadísticas"
      }

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

  Future<void> _cargarEjerciciosHistorial() async {
    if (_idUsu == null || _token == null) return;
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/usuarios/$_idUsu/ejercicios-historial',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final lista = json.decode(response.body) as List<dynamic>;
        setState(() {
          _ejerciciosHistorial = lista;
          if (lista.isNotEmpty && _ejercicioSeleccionadoId == null) {
            _ejercicioSeleccionadoId = lista.first['idEjercicio'] as String?;
          }
        });
        if (_ejercicioSeleccionadoId != null) {
          await _cargarHistorialCargas(_ejercicioSeleccionadoId!);
        }
      }
    } catch (e) {
      debugPrint('Error cargando ejercicios historial: $e');
    }
  }

  Future<void> _cargarHistorialCargas(String idEjercicio) async {
    if (_idUsu == null || _token == null) return;
    setState(() => _cargandoCargas = true);
    try {
      final id = Uri.encodeQueryComponent(idEjercicio);
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/usuarios/$_idUsu/historial-cargas?idEjercicio=$id',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        setState(() => _historialCargas = json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error cargando historial cargas: $e');
    } finally {
      setState(() => _cargandoCargas = false);
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
                    onRefresh: _cargarTodo,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── Resumen general ──
                          _buildResumenGeneral(),

                          const SizedBox(height: 16),
                          _buildRachaYActividad(),

                          const SizedBox(height: 20),
                          _buildPesoChart(),

                          const SizedBox(height: 20),
                          _buildCargasChart(),

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
                          if ((_stats!['por_tipo'] as List?)?.isNotEmpty ==
                              true) ...[
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
    final variacion = (_stats!['variacion_peso'] as num?)?.toDouble() ?? 0;
    final signo = variacion > 0 ? '+' : '';
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.fitness_center,
            'Rutinas\nregistradas',
            '${_stats!['total_rutinas'] ?? 0}',
            AppColors.oceanBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.monitor_weight,
            'Peso\nactual',
            '${(_stats!['peso_actual'] as num?)?.toStringAsFixed(1) ?? '—'} kg',
            AppColors.berry,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.trending_up,
            'Cambio\ntotal',
            historialVacio ? '—' : '$signo${variacion.toStringAsFixed(1)} kg',
            variacion <= 0 ? Colors.teal : AppColors.darkerPink,
          ),
        ),
      ],
    );
  }

  bool get historialVacio {
    final h = _stats!['historial_peso'];
    return h is! List || h.isEmpty;
  }

  Widget _buildRachaYActividad() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.local_fire_department,
            'Racha de\nentrenamiento',
            '${_stats!['racha_entrenamiento'] ?? 0} días',
            AppColors.darkerPink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.check_circle_outline,
            'Completadas\nesta semana',
            '${_stats!['rutinas_completadas_semana'] ?? 0}',
            AppColors.oceanBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.emoji_events_outlined,
            'Total\ncompletadas',
            '${_stats!['rutinas_completadas_total'] ?? 0}',
            AppColors.darkPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildPesoChart() {
    final historial = (_stats!['historial_peso'] as List?) ?? [];
    final pesoObjetivo = (_stats!['peso_objetivo'] as num?)?.toDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progreso de peso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              historial.isEmpty
                  ? 'Registra tu peso desde Inicio para ver la evolución'
                  : '${historial.length} registro(s)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (historial.isEmpty)
              SizedBox(
                height: 120,
                child: Center(
                  child: Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: _buildLineChart(historial, pesoObjetivo),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List historial, double? pesoObjetivo) {
    final spots = <FlSpot>[];
    final labels = <String>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var i = 0; i < historial.length; i++) {
      final item = historial[i] as Map<String, dynamic>;
      final y = (item['peso_kg'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), y));
      minY = y < minY ? y : minY;
      maxY = y > maxY ? y : maxY;

      try {
        final d = DateTime.parse(item['fecha'].toString());
        labels.add(DateFormat('d/M').format(d));
      } catch (_) {
        labels.add('${i + 1}');
      }
    }

    if (pesoObjetivo != null && pesoObjetivo > 0) {
      minY = minY < pesoObjetivo ? minY : pesoObjetivo;
      maxY = maxY > pesoObjetivo ? maxY : pesoObjetivo;
    }

    final padding = ((maxY - minY) * 0.15).clamp(1.0, 5.0);
    minY = (minY - padding).floorToDouble();
    maxY = (maxY + padding).ceilToDouble();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 4).clamp(0.5, 10.0),
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: historial.length > 6
                  ? (historial.length / 4).ceilToDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.berry,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.berry,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.berry.withOpacity(0.12),
            ),
          ),
          if (pesoObjetivo != null && pesoObjetivo > 0)
            LineChartBarData(
              spots: [
                FlSpot(0, pesoObjetivo),
                FlSpot((historial.length - 1).toDouble(), pesoObjetivo),
              ],
              isCurved: false,
              color: AppColors.darkerPink.withOpacity(0.6),
              barWidth: 2,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }

  Widget _buildCargasChart() {
    final nombreSeleccionado = _ejerciciosHistorial
        .cast<Map<String, dynamic>>()
        .where((e) => e['idEjercicio'] == _ejercicioSeleccionadoId)
        .map((e) => e['nombreEj'] as String?)
        .firstOrNull;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolución de cargas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Elige un ejercicio para ver solo su progreso',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            if (_ejerciciosHistorial.isEmpty)
              Text(
                'Completa rutinas para generar historial de cargas.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              )
            else
              DropdownButtonFormField<String>(
                value: _ejercicioSeleccionadoId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Ejercicio',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _ejerciciosHistorial.map((ej) {
                  final map = ej as Map<String, dynamic>;
                  return DropdownMenuItem<String>(
                    value: map['idEjercicio'] as String,
                    child: Text(
                      map['nombreEj']?.toString() ?? 'Ejercicio',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() => _ejercicioSeleccionadoId = id);
                  _cargarHistorialCargas(id);
                },
              ),
            if (_ejerciciosHistorial.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (nombreSeleccionado != null)
                Text(
                  nombreSeleccionado,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.oceanBlue,
                  ),
                ),
              const SizedBox(height: 8),
              if (_cargandoCargas)
                const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_historialCargas.isEmpty)
                SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Sin registros para este ejercicio.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: _buildCargasLineChart(_historialCargas),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCargasLineChart(List historial) {
    final spots = <FlSpot>[];
    final labels = <String>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var i = 0; i < historial.length; i++) {
      final item = historial[i] as Map<String, dynamic>;
      final y = (item['peso_kg'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), y));
      minY = y < minY ? y : minY;
      maxY = y > maxY ? y : maxY;

      try {
        final d = DateTime.parse(item['fecha'].toString());
        labels.add(DateFormat('d/M').format(d));
      } catch (_) {
        labels.add('${i + 1}');
      }
    }

    if (minY == maxY) {
      minY = (minY - 2).clamp(0, double.infinity);
      maxY = maxY + 2;
    } else {
      final padding = ((maxY - minY) * 0.15).clamp(1.0, 5.0);
      minY = (minY - padding).floorToDouble();
      maxY = (maxY + padding).ceilToDouble();
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 4).clamp(0.5, 50.0),
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: historial.length > 6
                  ? (historial.length / 4).ceilToDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.oceanBlue,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.oceanBlue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.oceanBlue.withOpacity(0.12),
            ),
          ),
        ],
      ),
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
    final pesoInicial =
        (_stats!['peso_inicial'] as num?)?.toDouble() ?? pesoActual;
    final pesoObjetivo = (_stats!['peso_objetivo'] as num?)?.toDouble();
    final tieneMeta = pesoObjetivo != null && pesoObjetivo > 0;

    double progreso = 0;
    if (tieneMeta && pesoInicial > pesoObjetivo!) {
      final totalBajar = pesoInicial - pesoObjetivo;
      final bajado = (pesoInicial - pesoActual).clamp(0.0, totalBajar);
      progreso = (bajado / totalBajar).clamp(0.0, 1.0);
    } else if (tieneMeta && pesoActual <= pesoObjetivo) {
      progreso = 1.0;
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
            _buildBarraProgreso(progreso, AppColors.darkerPink),
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
    final lista = (_stats!['por_tipo'] as List?) ?? [];
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
