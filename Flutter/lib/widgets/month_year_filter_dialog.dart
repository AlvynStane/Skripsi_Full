import 'package:flutter/material.dart';

class MonthYearFilterDialog extends StatelessWidget {
  final String selectedMonth;
  final String selectedYear;
  final List<String> months;
  final List<String> years;
  final void Function(String month) onMonthChanged;
  final void Function(String year) onYearChanged;

  const MonthYearFilterDialog({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.months,
    required this.years,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.date_range),
      label: Text("$selectedMonth $selectedYear"),
      onPressed: () async {
        String tempMonth = selectedMonth;
        String tempYear = selectedYear;

        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                title: const Text(
                  "Select Month and Year",
                  style: TextStyle(fontSize: 20),
                ),
                content: Row(
                  children: [
                    DropdownButton<String>(
                      value: tempMonth,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            tempMonth = value;
                          });
                        }
                      },
                      items: months.map((month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                    ),
                    SizedBox(width: 12),
                    DropdownButton<String>(
                      value: tempYear,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            tempYear = value;
                          });
                        }
                      },
                      items: years.map((year) {
                        return DropdownMenuItem<String>(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onMonthChanged(tempMonth);
                      onYearChanged(tempYear);
                      Navigator.pop(context);
                    },
                    child: const Text("OK"),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }
}
