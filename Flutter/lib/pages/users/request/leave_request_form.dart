import 'package:flutter/material.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/constants/app_lists.dart';
import 'package:skripsi/constants/app_strings.dart';
import 'package:skripsi/models/leave_request_model.dart';

class LeaveRequestForm extends StatefulWidget {
  final Function(LeaveRequest) onSubmit;

  const LeaveRequestForm({super.key, required this.onSubmit});

  @override
  State<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<LeaveRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String _selectedLeaveType = 'Sick Leave';
  DateTime? _startDate;
  DateTime? _endDate;

  void _pickDate(bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  void _onsubmit() {
    if (_formKey.currentState!.validate()) {
      DateTime finalEndDate = _selectedLeaveType == "Attendance Request" ? _startDate! : (_endDate ?? _startDate!);

      widget.onSubmit(
        LeaveRequest(
          id: '',
          leaveType: _selectedLeaveType,
          startDate: _startDate!,
          endDate: finalEndDate,
          reason: _reasonController.text,
          status: AppStrings.leaveStatusPending,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Request'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDropdown('Request Type', _selectedLeaveType, (value) {
                setState(() {
                  _selectedLeaveType = value!;
                });
              }),
              const SizedBox(height: 16),
              _buildDateField('Start Date', _startDate, () => _pickDate(true), isStartDate: true),
              if (_selectedLeaveType != "Attendance Request") ...[
                const SizedBox(height: 16),
                _buildDateField('End Date', _endDate, () => _pickDate(false)),
              ],
              const SizedBox(height: 16),
              _buildTextField('Reason for Request', _reasonController, maxLines: 3),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _onsubmit,
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required.';
            }
            return null;
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          items: AppLists.leaveTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap, {bool isStartDate = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        FormField<DateTime>(
          validator: (value) {
            if (date == null) {
              return 'Please select a date.';
            }
            if (!isStartDate && _startDate != null && _startDate!.isAfter(date)) {
              return 'End date must be after start date.';
            }
            return null;
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          date != null
                              ? '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}'
                              : 'Select Date',
                          style: TextStyle(
                            color: date == null ? Colors.black54 : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.errorText ?? '',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
