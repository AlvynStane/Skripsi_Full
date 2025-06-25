import 'package:flutter/material.dart';
import 'package:skripsi/utility/date_extensions.dart';
import 'package:skripsi/widgets/detail_row.dart';

class LeaveDetailsPage extends StatelessWidget {
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;

  const LeaveDetailsPage({
    super.key,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Details', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailRow(label: 'Leave Type', value: leaveType),
            DetailRow(label: 'Start Date', value: startDate.toFormattedString()),
            DetailRow(label: 'End Date', value: endDate.toFormattedString()),
            DetailRow(label: 'Reason', value: reason),
            DetailRow(label: 'Status', value: status),
          ],
        ),
      ),
    );
  }
}
