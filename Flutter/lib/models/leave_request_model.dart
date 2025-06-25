import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequest {
  final String id;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;

  LeaveRequest({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
  });

  factory LeaveRequest.fromMap(String id, Map<String, dynamic> data) {
    return LeaveRequest(
      id: id,
      leaveType: data['leaveType'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'leaveType': leaveType,
      'startDate': startDate.toUtc(),
      'endDate': endDate.toUtc(),
      'reason': reason,
      'status': status,
    };
  }
}
