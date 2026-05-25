import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/admin/services/admin_service.dart';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Future<List<Map<String, dynamic>>> _usuarios;

  @override
  void initState() {
    super.initState();
    _usuarios = AdminService.getUsuarios();
  }

  void _refresh() => setState(() => _usuarios = AdminService.getUsuarios());

  Future<void> _confirmarEliminar(String idUsu, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar usuario',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.darkPurple,
          ),
        ),
        content: Text(
          '¿Seguro que quieres eliminar a "$nombre"? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.greyPurple),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.berry,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await AdminService.eliminarUsuario(idUsu);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _usuarios,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Error cargando usuarios',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.oceanBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final usuarios = snapshot.data!;

        if (usuarios.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No hay usuarios registrados',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header con conteo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    '${usuarios.length} usuarios registrados',
                    style: TextStyle(
                      color: AppColors.greyPurple.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _refresh,
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: AppColors.oceanBlue,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                itemCount: usuarios.length,
                itemBuilder: (ctx, i) {
                  final u = usuarios[i];
                  final esAdmin = u['esAdmin'] == 1 || u['esAdmin'] == true;
                  final inicial = (u['nombreUsu'] ?? '?')[0].toUpperCase();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.babyGrey.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.mainBlue,
                                  AppColors.oceanBlue,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                inicial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      u['nombreUsu'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.darkPurple,
                                      ),
                                    ),
                                    if (esAdmin) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.oceanBlue
                                              .withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          'Admin',
                                          style: TextStyle(
                                            color: AppColors.oceanBlue,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  u['correoUsu'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.greyPurple.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Botón eliminar
                          if (!esAdmin)
                            GestureDetector(
                              onTap: () => _confirmarEliminar(
                                u['idUsu'],
                                u['nombreUsu'],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.berry.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.berry,
                                  size: 18,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 36),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
