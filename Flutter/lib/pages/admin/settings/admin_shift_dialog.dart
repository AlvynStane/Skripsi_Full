import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminShiftDialog extends StatefulWidget {
  const AdminShiftDialog({super.key});

  @override
  State<AdminShiftDialog> createState() => _AdminShiftDialogState();
}

class _AdminShiftDialogState extends State<AdminShiftDialog> {
  Map<String, TimeOfDay> shiftTimes = {
    'Shift 1 Start': const TimeOfDay(hour: 7, minute: 0),
    'Shift 1 End': const TimeOfDay(hour: 15, minute: 0),
    'Shift 2 Start': const TimeOfDay(hour: 15, minute: 0),
    'Shift 2 End': const TimeOfDay(hour: 23, minute: 0),
    'Late Tolerance': const TimeOfDay(hour: 0, minute: 15),
    'No Daily Wage Tolerance': const TimeOfDay(hour: 0, minute: 30),
  };

  Map<String, List<String>> shiftDays = {
    'Shift 1': [],
    'Shift 2': [],
  };

  int leaveQuota = 21;

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    final doc = await FirebaseFirestore.instance.collection('admin').doc('shift').get();
    if (doc.exists) {
      final data = doc.data()!;
      if (data['shiftTimes'] != null) {
        setState(() {
          shiftTimes = Map<String, dynamic>.from(data['shiftTimes']).map((key, value) {
            final parts = value.split(":");
            final time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
            return MapEntry(key, time);
          });
        });
      }
      if (data['shiftDays'] != null) {
        setState(() {
          shiftDays = Map<String, dynamic>.from(data['shiftDays']).map((key, value) {
            return MapEntry(key, List<String>.from(value));
          });
        });
      }
      if (data['leaveQuota'] != null) {
        setState(() {
          leaveQuota = data['leaveQuota'];
        });
      }
    }
  }

  Future<void> _saveShifts() async {
    final shiftTimeStr =
        shiftTimes.map((key, value) => MapEntry(key, "${value.hour}:${value.minute.toString().padLeft(2, '0')}"));

    await FirebaseFirestore.instance.collection('admin').doc('shift').set({
      'shiftTimes': shiftTimeStr,
      'shiftDays': shiftDays,
      'leaveQuota': leaveQuota,
    }, SetOptions(merge: true));
  }

  Future<void> _editLeaveQuota() async {
    final controller = TextEditingController(text: leaveQuota.toString());
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Leave Quota"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
            decoration: const InputDecoration(labelText: "Leave Quota"),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Leave quota is required';
              }
              if (int.tryParse(value) == null) {
                return 'Please input valid number.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final parsed = int.tryParse(controller.text);
                  Navigator.pop(context, parsed);
                }
              },
              child: const Text("Save")),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        leaveQuota = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Shift Configuration", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            for (var key in [
              'Shift 1 Start',
              'Shift 1 End',
              'Shift 2 Start',
              'Shift 2 End',
              'Late Tolerance',
              'No Daily Wage Tolerance',
            ])
              ListTile(
                title: Text(key),
                trailing: Text(shiftTimes[key]!.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: shiftTimes[key]!,
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      );
                    },
                    initialEntryMode: TimePickerEntryMode.input,
                  );

                  if (picked != null) {
                    setState(() {
                      shiftTimes[key] = picked;
                    });
                  }
                },
              ),
            ListTile(
              title: const Text("Leave Quota"),
              trailing: Text("$leaveQuota"),
              onTap: _editLeaveQuota,
            ),
            const Divider(),
            for (var shift in ['Shift 1', 'Shift 2'])
              Builder(
                builder: (_) {
                  final entry = MapEntry(shift, shiftDays[shift]!);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${entry.key} Days"),
                      Wrap(
                        spacing: 4,
                        children: [
                          for (var day in [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday'
                          ])
                            FilterChip(
                              label: Text(day),
                              selected: entry.value.contains(day),
                              onSelected: (selected) {
                                setState(() {
                                  final currentShift = entry.key;
                                  final otherShift = currentShift == 'Shift 1' ? 'Shift 2' : 'Shift 1';

                                  // Remove from both first
                                  shiftDays[currentShift]!.remove(day);
                                  shiftDays[otherShift]!.remove(day);

                                  // Add if selected
                                  if (selected) {
                                    shiftDays[currentShift]!.add(day);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                  );
                },
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await _saveShifts();
                Navigator.pop(context);
              },
              child: const Text("Save Settings", style: TextStyle(fontSize: 20)),
            )
          ],
        ),
      ),
    );
  }
}
