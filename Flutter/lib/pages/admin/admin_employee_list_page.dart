import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/models/employee_model.dart';
import 'package:skripsi/models/leave_request_model.dart';
import 'package:skripsi/services/employee_service.dart';
import 'package:skripsi/services/leave_service.dart';
import 'package:skripsi/utility/date_extensions.dart';
import 'package:skripsi/widgets/confirmation_dialog.dart';
import 'package:skripsi/widgets/employee_detail_item.dart';
import 'package:skripsi/widgets/leave_summary_card.dart';

class AdminEmployeeListPage extends StatefulWidget {
  const AdminEmployeeListPage({super.key});

  @override
  State<AdminEmployeeListPage> createState() => _AdminEmployeeListPageState();
}

class _AdminEmployeeListPageState extends State<AdminEmployeeListPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Employee> employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final loadedEmployees = await EmployeeService.loadEmployees();
      setState(() {
        employees
          ..clear()
          ..addAll(loadedEmployees);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load employees")),
      );
    }
  }

  void _showEmployeeFaceImage(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final faceImageUrl = doc.data()?['faceImage'];

      if (faceImageUrl == null || faceImageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Face image not available.")),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Face Image"),
          content: SizedBox(
              width: 200,
              height: 200,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    faceImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Close",
                style: TextStyle(color: AppColors.text2),
              ),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load face image: $e")),
      );
    }
  }

  void _showEmployeeDialog({Employee? employee}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = employee != null;
    final controllers = {
      "name": TextEditingController(text: employee?.name ?? ""),
      "nik": TextEditingController(text: employee?.nik ?? ""),
      "email": TextEditingController(text: employee?.email ?? ""),
      "gender": TextEditingController(text: employee?.gender ?? ""),
      "dob": TextEditingController(
        text: employee != null ? employee.dob.toFormattedString() : "",
      ),
      "pob": TextEditingController(text: employee?.pob ?? ""),
      "position": TextEditingController(text: employee?.position ?? ""),
      "address": TextEditingController(text: employee?.address ?? ""),
      "joinDate": TextEditingController(
        text: employee != null ? employee.joinDate.toFormattedString() : "",
      ),
      "phone": TextEditingController(text: employee?.phone ?? ""),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? "Edit Employee" : "Add Employee"),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  _buildField(controllers["name"]!, "Name"),
                  _buildField(controllers["nik"]!, "NIK", isNik: true, isNumeric: true),
                  _buildField(controllers["email"]!, "Email"),
                  _buildGenderField(controllers["gender"]!, "Gender"),
                  _buildField(controllers["dob"]!, "Date of Birth", isDate: true),
                  _buildField(controllers["pob"]!, "Place of Birth"),
                  _buildField(controllers["position"]!, "Position"),
                  _buildField(controllers["address"]!, "Address"),
                  _buildField(controllers["joinDate"]!, "Join Date", isDate: true),
                  _buildField(controllers["phone"]!, "Phone", isNumeric: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.text2),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _saveEmployee(controllers, isEditing, employee);
              }
            },
            child: const Text(
              "Save",
              style: TextStyle(color: AppColors.text1),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEmployee(Map<String, TextEditingController> controllers, bool isEditing, Employee? employee) async {
    final newEmail = controllers["email"]!.text.toLowerCase();

    final nextNo = (employees.isEmpty ? 1 : employees.map((e) => int.parse(e.no)).reduce((a, b) => a > b ? a : b) + 1)
        .toString()
        .padLeft(4, '0');

    final employeeData = {
      "uid": isEditing ? employee!.uid : null,
      "isEditing": isEditing,
      "no": isEditing ? employee!.no : nextNo,
      "name": controllers["name"]!.text,
      "nik": controllers["nik"]!.text,
      "email": newEmail,
      "gender": controllers["gender"]!.text,
      "dob": DateFormat("yyyy-MM-dd").format(DateFormat("dd-MM-yyyy").parse(controllers["dob"]!.text)),
      "pob": controllers["pob"]!.text,
      "position": controllers["position"]!.text,
      "address": controllers["address"]!.text,
      "joinDate": DateFormat("yyyy-MM-dd").format(DateFormat("dd-MM-yyyy").parse(controllers["joinDate"]!.text)),
      "phone": controllers["phone"]!.text,
    };

    try {
      if (isEditing && employee!.email != newEmail) {
        await EmployeeService.updateEmail(employee.uid, newEmail);
      }

      final uid = await EmployeeService.createOrUpdateEmployee(employeeData, isEditing);

      final newEmployee = Employee(
        uid: uid,
        no: employeeData["no"]! as String,
        name: employeeData["name"]! as String,
        nik: employeeData["nik"]! as String,
        email: newEmail,
        gender: employeeData["gender"]! as String,
        dob: DateTime.parse(employeeData["dob"]! as String),
        pob: employeeData["pob"]! as String,
        position: employeeData["position"]! as String,
        address: employeeData["address"]! as String,
        joinDate: DateTime.parse(employeeData["joinDate"]! as String),
        phone: employeeData["phone"]! as String,
      );

      setState(() {
        if (isEditing) {
          final index = employees.indexWhere((e) => e.uid == uid);
          if (index != -1) employees[index] = newEmployee;
        } else {
          employees.add(newEmployee);
        }
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _showEmployeeDetails(Employee employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Employee Details",
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmployeeDetailItem(icon: Icons.badge, label: "No", value: employee.no),
                  EmployeeDetailItem(icon: Icons.person, label: "Name", value: employee.name),
                  EmployeeDetailItem(icon: Icons.email, label: "Email", value: employee.email),
                  EmployeeDetailItem(icon: Icons.credit_card, label: "NIK", value: employee.nik),
                  EmployeeDetailItem(
                    icon: employee.gender.toLowerCase() == "female" ? Icons.female : Icons.male,
                    label: "Gender",
                    value: employee.gender,
                  ),
                  EmployeeDetailItem(icon: Icons.cake, label: "Date of Birth", value: employee.dob.toFormattedString()),
                  EmployeeDetailItem(icon: Icons.location_on, label: "Place of Birth", value: employee.pob),
                  EmployeeDetailItem(icon: Icons.work, label: "Position", value: employee.position),
                  EmployeeDetailItem(icon: Icons.location_city, label: "Address", value: employee.address),
                  EmployeeDetailItem(
                      icon: Icons.date_range, label: "Join Date", value: employee.joinDate.toFormattedString()),
                  EmployeeDetailItem(icon: Icons.phone, label: "Phone", value: employee.phone),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Close",
                style: TextStyle(color: AppColors.text2),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Employee employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: "Delete Employee",
          content: "Are you sure you want to delete ${employee.name}?",
          confirmText: "Delete",
          confirmTextColor: AppColors.text1,
          onConfirm: () async {
            await _deleteEmployee(employee.uid);
          },
        );
      },
    );
  }

  Future<void> _deleteEmployee(String uid) async {
    try {
      await EmployeeService.deleteEmployee(uid);

      final deletedEmployee = employees.firstWhere((e) => e.uid == uid);
      final deletedNo = int.parse(deletedEmployee.no);

      setState(() {
        employees.removeWhere((e) => e.uid == uid);
      });

      for (int i = 0; i < employees.length; i++) {
        int currentNo = int.parse(employees[i].no);
        if (currentNo > deletedNo) {
          int newNo = currentNo - 1;
          final updatedEmployee = employees[i].copyWith(no: newNo.toString().padLeft(4, '0'));

          setState(() {
            employees[i] = updatedEmployee;
          });

          await EmployeeService.updateEmployeeNo(updatedEmployee.uid, updatedEmployee.no);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Employee deleted successfully")),
      );
    } catch (e) {
      debugPrint("Error deleting user: $e");
    }
  }

  void _showLeaveSummary(Employee employee) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(employee.uid).collection('leave_requests').get();
      final leaveRequests = snapshot.docs.map((doc) => LeaveRequest.fromMap(doc.id, doc.data())).toList();
      final summary = await LeaveService.computeLeaveSummary(leaveRequests, employee.joinDate);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("${employee.name}'s Leave Summary"),
          content: SizedBox(
            width: 300,
            height: 200,
            child: LeaveSummaryCard(summary: summary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Close",
                style: TextStyle(color: AppColors.text2),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load leave summary")),
      );
    }
  }

  List<Employee> get _filteredEmployees {
    final query = _searchController.text.toLowerCase();
    return employees.where((e) => e.name.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: "Search employee",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showEmployeeDialog(),
                  icon: const Icon(Icons.person_add, color: AppColors.text1),
                  label: const Text("Add employee", style: TextStyle(color: AppColors.text1)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("NO")),
                      DataColumn(label: Text("NAME")),
                      DataColumn(label: Text("NIK")),
                      DataColumn(label: Text("EMAIL")),
                      DataColumn(label: Text("ACTIONS")),
                    ],
                    showBottomBorder: true,
                    rows: _filteredEmployees
                        .map((employee) => DataRow(cells: [
                              DataCell(Text(employee.no)),
                              DataCell(Text(employee.name)),
                              DataCell(Text(employee.nik)),
                              DataCell(Text(employee.email)),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.image, color: Colors.teal),
                                    tooltip: "Face Registered",
                                    onPressed: () => _showEmployeeFaceImage(employee.uid),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.assignment, color: Colors.pinkAccent),
                                    tooltip: "Leave Summary",
                                    onPressed: () => _showLeaveSummary(employee),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.orange),
                                    tooltip: "Employee Details",
                                    onPressed: () => _showEmployeeDetails(employee),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: "Edit Employee",
                                    onPressed: () => _showEmployeeDialog(employee: employee),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: "Delete Employee",
                                    onPressed: () => _confirmDelete(employee),
                                  ),
                                ],
                              )),
                            ]))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {bool isNik = false, bool isDate = false, isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        maxLength: isNik ? 16 : null,
        readOnly: isDate,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: isDate ? const Icon(Icons.calendar_today) : null,
        ),
        keyboardType: isNumeric ? TextInputType.numberWithOptions(decimal: true, signed: false) : null,
        inputFormatters: isNumeric ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))] : null,
        validator: (value) {
          if (label == "Email" && !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value!)) {
            return "The email address is badly formatted";
          }
          if (value == null || value.isEmpty) {
            return "$label is required";
          }
          if (isNik && value.length != 16) {
            return "NIK must be exactly 16 digits.";
          }
          return null;
        },
        onTap: isDate
            ? () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  controller.text = pickedDate.toFormattedString();
                }
              }
            : null,
      ),
    );
  }

  Widget _buildGenderField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : null,
        items: const [
          DropdownMenuItem(value: "Male", child: Text("Male")),
          DropdownMenuItem(value: "Female", child: Text("Female")),
        ],
        onChanged: (value) {
          controller.text = value!;
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? "Gender is required" : null,
      ),
    );
  }
}
