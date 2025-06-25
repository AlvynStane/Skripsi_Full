import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skripsi/constants/app_colors.dart';

class AdminRequestTimeOffPage extends StatefulWidget {
  const AdminRequestTimeOffPage({super.key});

  @override
  State<AdminRequestTimeOffPage> createState() => _AdminRequestTimeOffPageState();
}

class _AdminRequestTimeOffPageState extends State<AdminRequestTimeOffPage> {
  TextEditingController searchController = TextEditingController();
  String selectedStatus = "All";
  DateTimeRange? selectedDateRange;
  final Map<String, String> _employees = {};

  Future<String> _fetchEmployeeName(String userId) async {
    if (_employees.containsKey(userId)) {
      return _employees[userId]!;
    }

    DocumentSnapshot userProfile =
        await FirebaseFirestore.instance.collection('users').doc(userId).collection('profile').doc(userId).get();

    String name = userProfile.exists ? (userProfile["name"] ?? "Unknown") : "Unknown";
    _employees[userId] = name;
    return name;
  }

  Stream<QuerySnapshot> _fetchLeaveRequests() {
    return FirebaseFirestore.instance.collectionGroup('leave_requests').snapshots();
  }

  Future<List<Map<String, dynamic>>> _buildEnrichedRequestList(List<QueryDocumentSnapshot> docs) async {
    List<Map<String, dynamic>> enrichedList = [];

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      var userId = doc.reference.parent.parent!.id;
      String employeeName = await _fetchEmployeeName(userId);

      enrichedList.add({
        "doc": doc,
        "data": data,
        "employeeName": employeeName,
      });
    }
    return enrichedList;
  }

  void _updateStatus(DocumentReference requestRef, String newStatus) async {
    await requestRef.update({"status": newStatus});
  }

  bool _isRangeOverlap(DateTimeRange selected, DateTimeRange request) {
    return selected.start.isBefore(request.end) && selected.end.isAfter(request.start);
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilterSection(),
          const SizedBox(height: 10),
          Expanded(child: _buildDataTable()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search employee name...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: selectedStatus,
              items: ["All", "Approved", "Pending", "Rejected"]
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
              },
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(
                Icons.calendar_today,
                color: AppColors.background2,
              ),
              label: Text(
                selectedDateRange != null
                    ? "${_formatDate(selectedDateRange!.start)} - ${_formatDate(selectedDateRange!.end)}"
                    : "Select Date Range",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchLeaveRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No leave requests found"));
        }
        var docs = snapshot.data!.docs;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _buildEnrichedRequestList(docs),
          builder: (context, futureSnapshot) {
            if (!futureSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var enrichedRequests = futureSnapshot.data!;

            var filtered = enrichedRequests.where((request) {
              final name = request["employeeName"].toString().toLowerCase();
              final matchesName = name.contains(searchController.text.toLowerCase());

              final matchesStatus = selectedStatus == "All" || request["data"]["status"] == selectedStatus;

              final matchesDate = selectedDateRange == null ||
                  _isRangeOverlap(
                    selectedDateRange!,
                    DateTimeRange(
                      start: (request["data"]["startDate"] as Timestamp).toDate(),
                      end: (request["data"]["endDate"] as Timestamp).toDate(),
                    ),
                  );

              return matchesName && matchesStatus && matchesDate;
            }).toList();

            filtered.sort((a, b) {
              DateTime aStart = (a["data"]["startDate"] as Timestamp).toDate();
              DateTime bStart = (b["data"]["startDate"] as Timestamp).toDate();
              return bStart.compareTo(aStart);
            });

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text("No")),
                    DataColumn(label: Text("Name")),
                    DataColumn(label: Text("Leave Type")),
                    DataColumn(label: Text("Start Date")),
                    DataColumn(label: Text("End Date")),
                    DataColumn(label: Text("Reason")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Action")),
                  ],
                  rows: filtered.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    var data = entry.value["data"] as Map<String, dynamic>;
                    var docRef = entry.value["doc"].reference;
                    var name = entry.value["employeeName"];

                    return DataRow(cells: [
                      DataCell(Text(index.toString())),
                      DataCell(Text(name)),
                      DataCell(Text(data["leaveType"] ?? "-")),
                      DataCell(Text(_formatDate((data["startDate"] as Timestamp).toDate()))),
                      DataCell(Text(_formatDate((data["endDate"] as Timestamp).toDate()))),
                      DataCell(Text(data["reason"] ?? "-")),
                      DataCell(_buildStatusBadge(data["status"] ?? "Pending")),
                      DataCell(Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _updateStatus(docRef, "Approved")),
                          IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _updateStatus(docRef, "Rejected")),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    switch (status) {
      case "Approved":
        bgColor = Colors.green;
        break;
      case "Pending":
        bgColor = Colors.orange;
        break;
      case "Rejected":
        bgColor = Colors.red;
        break;
      default:
        bgColor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: const TextStyle(color: Colors.white)),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
