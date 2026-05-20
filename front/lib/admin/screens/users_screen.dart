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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final usuarios = snapshot.data!;
          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (ctx, i) {
              final u = usuarios[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text((u['nombreUsu'] ?? '?')[0].toUpperCase()),
                ),
                title: Text(u['nombreUsu']),
                subtitle: Text(u['correoUsu']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (u['esAdmin'] == 1)
                      const Chip(
                        label: Text('Admin'),
                        backgroundColor: AppColors.blueishPurple,
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: AppColors.darkerPink,
                      ),
                      onPressed: () async {
                        await AdminService.eliminarUsuario(u['idUsu']);
                        _refresh();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
