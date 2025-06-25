import 'package:flutter/material.dart';

class LeaveSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const LeaveSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leave Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Total Requests: ${summary['total']}'),
            Text('Attendance Requests: ${summary['attendanceRequests']}'),
            Text('Approved: ${summary['approved']}'),
            Text('Pending: ${summary['pending']}'),
            Text('Rejected: ${summary['rejected']}'),
            Text('Annual Leave Quota Left: ${summary['quotaLeft']} days'),
          ],
        ),
      ),
    );
  }
}
