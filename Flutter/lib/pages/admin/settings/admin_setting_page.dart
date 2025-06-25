import 'package:flutter/material.dart';
import 'package:skripsi/pages/admin/settings/admin_change_password_page.dart';
import 'package:skripsi/pages/admin/settings/admin_holiday_dialog.dart';
import 'package:skripsi/pages/admin/settings/admin_profile_page.dart';
import 'package:skripsi/pages/admin/settings/admin_shift_dialog.dart';

class AdminSettingPage extends StatefulWidget {
  const AdminSettingPage({super.key});

  @override
  State<AdminSettingPage> createState() => _AdminSettingPageState();
}

class _AdminSettingPageState extends State<AdminSettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProfilePage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text("Manage Holidays"),
            onTap: () => _showHolidayDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text("Shift Configuration"),
            onTap: () => _showShiftDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Change Password"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const AdminChangePasswordPage(),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About App"),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "Attendance App",
      applicationVersion: "1.0.0",
      applicationLegalese: "© 2025 PT. Surya Cemerlang Logistik",
    );
  }

  void _showHolidayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AdminHolidayDialog(),
    );
  }

  void _showShiftDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AdminShiftDialog(),
    );
  }
}
