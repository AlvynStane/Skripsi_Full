import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skripsi/pages/admin/all_admin_pages.dart';
import 'package:skripsi/pages/auth/login_page.dart';
import 'package:skripsi/pages/users/all_users_pages.dart';
import 'package:skripsi/providers/auth_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<String?> _getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('savedUserEmail');
  }

  @override
  Widget build(BuildContext context) {
    final myAuth = Provider.of<MyAuthProvider>(context);

    return FutureBuilder<String?>(
      future: _getSavedUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        String? savedEmail = snapshot.data?.toLowerCase();

        if (savedEmail != null) {
          if (savedEmail == myAuth.adminEmail && kIsWeb) {
            return const AllAdminPage();
          } else if (savedEmail != myAuth.adminEmail && !kIsWeb) {
            return const AllPages();
          }
        }

        return const LoginPage();
      },
    );
  }
}
