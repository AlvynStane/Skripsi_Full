import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:skripsi/models/employee_model.dart';

class EmployeeService {
  static const _editEmailUrl = 'https://api-ryy35i7zhq-uc.a.run.app/edit-user';
  static const _createUserUrl = 'https://api-ryy35i7zhq-uc.a.run.app/create-user';
  static const _deleteUserUrl = 'https://api-ryy35i7zhq-uc.a.run.app/delete-user';

  static Future<List<Employee>> loadEmployees() async {
    final snapshot = await FirebaseFirestore.instance.collectionGroup("profile").get();

    List<Employee> employees = snapshot.docs.map((doc) {
      return Employee(
        uid: doc.id,
        no: doc["no"],
        name: doc["name"],
        nik: doc["nik"],
        email: doc["email"],
        gender: doc["gender"],
        dob: DateTime.tryParse(doc["dob"] ?? "") ?? DateTime(1970),
        pob: doc["pob"],
        position: doc["position"],
        address: doc["address"],
        joinDate: DateTime.tryParse(doc["joinDate"] ?? "") ?? DateTime(1970),
        phone: doc["phone"],
      );
    }).toList();

    employees.sort((a, b) => a.no.compareTo(b.no));
    return employees;
  }

  static Future<String> createOrUpdateEmployee(Map<String, dynamic> data, bool isEditing) async {
    final url = Uri.parse(_createUserUrl);
    final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    if (response.statusCode != 200) throw Exception('Error: ${response.body}');
    return jsonDecode(response.body)['uid'];
  }

  static Future<void> updateEmail(String uid, String newEmail) async {
    final response = await http.post(
      Uri.parse(_editEmailUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'newEmail': newEmail}),
    );
    if (response.statusCode != 200) throw Exception("Failed to update email: ${response.body}");
  }

  static Future<void> deleteEmployee(String uid) async {
    final response = await http.post(
      Uri.parse(_deleteUserUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    );
    if (response.statusCode != 200) throw Exception("Failed to delete user: ${response.body}");
  }

  static Future<void> updateEmployeeNo(String uid, String newNo) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('profile').doc(uid).update({'no': newNo});
  }
}
