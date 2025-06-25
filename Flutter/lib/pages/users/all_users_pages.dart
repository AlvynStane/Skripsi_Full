import 'package:flutter/material.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/pages/users/home/home_page.dart';
import 'package:skripsi/pages/users/profile/profile_page.dart';
import 'package:skripsi/pages/users/request/request_page.dart';

class AllPages extends StatefulWidget {
  const AllPages({super.key});

  @override
  State<AllPages> createState() => _AllPagesState();
}

class _AllPagesState extends State<AllPages> {
  int _selectedIndex = 1;
  final List<Widget> _pages = [
    const RequestPage(),
    const HomePage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.access_time,
            ),
            label: 'Request',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        iconSize: 30.0,
        selectedFontSize: 14.0,
        unselectedFontSize: 12.0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}
