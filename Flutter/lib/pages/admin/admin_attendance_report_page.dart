import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skripsi/services/attendance_report_service.dart';

class AdminAttendanceReportPage extends StatefulWidget {
  const AdminAttendanceReportPage({super.key});

  @override
  State<AdminAttendanceReportPage> createState() => _AdminAttendanceReportPageState();
}

class _AdminAttendanceReportPageState extends State<AdminAttendanceReportPage> {
  String selectedMonth = "All";
  String selectedYear = DateFormat('yyyy').format(DateTime.now());

  final List<String> months = [
    "All",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  final List<String> years = List.generate(20, (index) => (2020 + index).toString());

  final List<Map<String, String>> allReports = [];
  List<Map<String, String>> filteredReports = [];

  @override
  void initState() {
    super.initState();
    _generateReports();
    _filterReports();
  }

  void _generateReports() {
    int reportNumber = 1;
    for (String year in years) {
      for (String month in months.skip(1)) {
        allReports.add({
          "no": reportNumber.toString(),
          "report_name": "Monthly Attendance Report $month $year",
        });
        reportNumber++;
      }
    }
  }

  void _filterReports() {
    setState(() {
      List<Map<String, String>> tempFiltered = allReports.where((report) {
        if (selectedMonth == "All" && selectedYear == "All") return true;

        List<String> words = report["report_name"]!.split(" ");
        if (words.length < 5) return false;

        String reportMonth = words[3];
        String reportYear = words[4];

        bool monthMatches = (selectedMonth == "All" || reportMonth == selectedMonth);
        bool yearMatches = (selectedYear == "All" || reportYear == selectedYear);

        return monthMatches && yearMatches;
      }).toList();

      for (int i = 0; i < tempFiltered.length; i++) {
        tempFiltered[i]["no"] = (i + 1).toString();
      }

      filteredReports = tempFiltered;
    });
  }

  Future<void> exportToExcel(String title) async {
    List<String> parts = title.split(" ");
    if (parts.length < 5) return;

    String monthStr = parts[3];
    String yearStr = parts[4];

    int year = int.parse(yearStr);
    int month = months.indexOf(monthStr);

    List<int> allDates = [];
    List<String> dayNames = [];

    int lastDay = DateTime(year, month + 1, 0).day;
    for (int day = 1; day <= lastDay; day++) {
      DateTime date = DateTime(year, month, day);
      allDates.add(day);
      dayNames.add(DateFormat('EEE').format(date));
    }

    final AttendanceService service = AttendanceService();
    final data = await service.fetchAttendanceData(year, month, allDates);
    final holiday = await service.fetchHolidays();

    await service.exportToExcel(
      title,
      year,
      month,
      allDates,
      dayNames,
      data,
      holiday,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterSection(),
              const SizedBox(height: 20),
              _buildReportTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildDropdown(months, selectedMonth, (value) {
              setState(() {
                selectedMonth = value!;
                _filterReports();
              });
            }),
            const SizedBox(width: 12),
            _buildDropdown(years, selectedYear, (value) {
              setState(() {
                selectedYear = value!;
                _filterReports();
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String selectedValue, ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items.map((String item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
      ),
    );
  }

  Widget _buildReportTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columnSpacing: 30,
            headingRowColor: WidgetStateColor.resolveWith((states) => Colors.teal.shade100),
            columns: const [
              DataColumn(label: Text("No", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Report Name", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filteredReports
                .map((report) => DataRow(cells: [
                      DataCell(Text(report["no"]!)),
                      DataCell(Text(report["report_name"]!)),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.teal),
                          onPressed: () {
                            exportToExcel(report["report_name"]!);
                          },
                        ),
                      ),
                    ]))
                .toList(),
          ),
        ),
      ),
    );
  }
}
