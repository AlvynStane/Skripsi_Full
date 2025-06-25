import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/constants/app_images.dart';
import 'package:skripsi/pages/admin/admin_attendance_list_page.dart';
import 'package:skripsi/pages/admin/admin_home_page.dart';
import 'package:skripsi/pages/admin/admin_employee_list_page.dart';
import 'package:skripsi/pages/admin/settings/admin_setting_page.dart';
import 'package:skripsi/pages/admin/admin_location_page.dart';
import 'package:skripsi/pages/admin/admin_request_time_off_page.dart';
import 'package:skripsi/pages/admin/admin_attendance_report_page.dart';
import 'package:skripsi/pages/auth/login_page.dart';
import 'package:skripsi/providers/auth_provider.dart';
import 'package:skripsi/providers/profile_provider.dart';
import 'package:skripsi/widgets/confirmation_dialog.dart';

class AllAdminPage extends StatefulWidget {
  const AllAdminPage({super.key});

  @override
  State<AllAdminPage> createState() => _AllAdminPageState();
}

class _AllAdminPageState extends State<AllAdminPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminHomePage(),
    const AdminAttendanceListPage(),
    const AdminEmployeeListPage(),
    AdminRequestTimeOffPage(),
    const AdminLocationPage(),
    const AdminAttendanceReportPage(),
    const AdminSettingPage(),
  ];

  final List<String> _pageTitles = [
    "Dashboard",
    "Attendance List",
    "Employee List",
    "Request Time Off List",
    "Location",
    "Attendance Report",
    "Settings",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).loadProfile();
    });
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  void _logout() async {
    await Provider.of<MyAuthProvider>(context, listen: false).signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(_pageTitles[_selectedIndex]),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 150,
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Center(
              child: Image.asset(
                AppImages.logo,
                fit: BoxFit.contain,
                height: 120,
              ),
            ),
          ),
          _buildDrawerItem(Icons.dashboard, "Dashboard", 0),
          _buildDrawerItem(Icons.list, "Attendance List", 1),
          _buildDrawerItem(Icons.people, "Employee List", 2),
          _buildDrawerItem(Icons.approval, "Request Time Off List", 3),
          const Divider(),
          _buildDrawerItem(Icons.map, "Location", 4),
          _buildDrawerItem(Icons.report, "Attendance Report", 5),
          const Divider(),
          _buildDrawerItem(Icons.settings, "Settings", 6),
          _buildDrawerItem(Icons.logout, "Logout", -1),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyan),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      selected: _selectedIndex == index && index >= 0,
      onTap: () {
        if (index == -1) {
          _showLogoutDialog();
        } else if (index >= 0) {
          _onDrawerItemTapped(index);
        }
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Logout",
        content: "Are you sure you want to logout?",
        confirmText: "Logout",
        cancelText: "Cancel",
        onConfirm: _logout,
      ),
    );
  }
}
