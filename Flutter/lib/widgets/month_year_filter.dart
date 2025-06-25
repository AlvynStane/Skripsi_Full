import 'package:flutter/material.dart';

class MonthYearFilter extends StatelessWidget {
  final List<String> months;
  final List<String> years;
  final String selectedMonth;
  final String selectedYear;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<String> onYearChanged;

  const MonthYearFilter({
    required this.months,
    required this.years,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedMonth,
            onChanged: (val) => onMonthChanged(val!),
            items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedYear,
            onChanged: (val) => onYearChanged(val!),
            items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
          ),
        ),
      ],
    );
  }
}