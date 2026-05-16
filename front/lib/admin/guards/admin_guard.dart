import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/admin/services/admin_service.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminService.esAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()),);
        }
        if (snapshot.data == true) return child;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/home');
        });
        return const SizedBox();
      },
    );
  }
}