import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

class AdminHolidayDialog extends StatefulWidget {
  const AdminHolidayDialog({super.key});

  @override
  State<AdminHolidayDialog> createState() => _AdminHolidayDialogState();
}

class _AdminHolidayDialogState extends State<AdminHolidayDialog> {
  final Set<DateTime> _selectedHolidays = {};

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    final doc = await FirebaseFirestore.instance.collection('admin').doc('holiday').get();

    final currentYear = DateTime.now().year;
    if (doc.exists) {
      final data = doc.data()!;
      if (data['holidays'] != null) {
        final List<dynamic> holidays = data['holidays'];
        _selectedHolidays.addAll(holidays.map((e) => DateTime.parse(e)));
      }

      final holidayImported = Map<String, dynamic>.from(data['holidayImported'] ?? {});
      if (holidayImported["$currentYear"] != true) {
        await _fetchAndCacheIndonesianHolidays(currentYear, holidayImported);
      }

      setState(() {});
    }
  }

  Future<void> _saveHolidays() async {
    final holidays = _selectedHolidays.map((d) => d.toIso8601String()).toList();
    await FirebaseFirestore.instance.collection('admin').doc('holiday').set({
      'holidays': holidays,
    }, SetOptions(merge: true));
  }

  Future<void> _fetchAndCacheIndonesianHolidays(int year, Map<String, dynamic> importedYears) async {
    try {
      final response = await http.get(
        Uri.parse("https://date.nager.at/api/v3/PublicHolidays/$year/ID"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> holidays = jsonDecode(response.body);
        final dates = holidays.map((h) => DateTime.parse(h['date'])).toSet();

        _selectedHolidays.addAll(dates);

        final formattedDates = _selectedHolidays.map((d) => d.toIso8601String()).toList();
        importedYears["$year"] = true;

        await FirebaseFirestore.instance.collection('admin').doc('holiday').set({
          'holidays': formattedDates,
          'holidayImported': importedYears,
        }, SetOptions(merge: true));

        setState(() {});
      }
    } catch (e) {
      debugPrint("Failed to fetch holidays: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        height: 500,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Set Holiday Dates", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            Expanded(
              child: TableCalendar(
                focusedDay: DateTime.now(),
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                selectedDayPredicate: (day) => _selectedHolidays.any((d) => isSameDay(d, day)),
                onDaySelected: (selectedDay, _) {
                  setState(() {
                    if (_selectedHolidays.any((d) => isSameDay(d, selectedDay))) {
                      _selectedHolidays.removeWhere((d) => isSameDay(d, selectedDay));
                    } else {
                      _selectedHolidays.add(selectedDay);
                    }
                  });
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextButton(
                onPressed: () async {
                  await _saveHolidays();
                  Navigator.pop(context);
                },
                child: const Text("Save", style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
