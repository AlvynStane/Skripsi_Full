import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skripsi/models/employee_model.dart';
import 'package:skripsi/utility/date_extensions.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  Future<Employee?> _fetchEmployeeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('profile').doc(user.uid).get();
    if (!doc.exists) return null;

    return Employee(
      uid: doc['uid'],
      no: doc['no'],
      name: doc['name'],
      nik: doc['nik'],
      email: doc['email'],
      gender: doc['gender'],
      dob: DateTime.tryParse(doc['dob'] ?? '') ?? DateTime(1970),
      pob: doc['pob'],
      position: doc['position'],
      address: doc['address'],
      joinDate: DateTime.tryParse(doc['joinDate'] ?? '') ?? DateTime(1970),
      phone: doc['phone'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: FutureBuilder<Employee?>(
        future: _fetchEmployeeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load data'));
          }
          final employee = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildInfoTile('Employee No', employee.no),
                _buildInfoTile('Name', employee.name),
                _buildInfoTile('NIK', employee.nik),
                _buildInfoTile('Email', employee.email),
                _buildInfoTile('Gender', employee.gender),
                _buildInfoTile('Date of Birth', employee.dob.toFormattedString()),
                _buildInfoTile('Place of Birth', employee.pob),
                _buildInfoTile('Position', employee.position),
                _buildInfoTile('Address', employee.address),
                _buildInfoTile('Join Date', employee.joinDate.toFormattedString()),
                _buildInfoTile('Phone', employee.phone),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String title, String? value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value ?? '-'),
    );
  }
}
