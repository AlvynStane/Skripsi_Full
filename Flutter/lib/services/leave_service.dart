import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skripsi/models/leave_request_model.dart';
import 'package:skripsi/utility/holiday_utils.dart';

class LeaveService {
  static Future<Map<String, dynamic>> computeLeaveSummary(List<LeaveRequest> requests, DateTime joinDate) async {
    final holidayDoc = await FirebaseFirestore.instance.collection('admin').doc('holiday').get();
    final holidaysField = holidayDoc.data()?['holidays'] as List<dynamic>? ?? [];
    final holidays = holidaysField.map((dateStr) => DateTime.parse(dateStr as String)).toSet();
    HolidayUtils.setHolidays(holidays);

    final shiftDoc = await FirebaseFirestore.instance.collection('admin').doc('shift').get();
    final totalQuota = shiftDoc.data()?['leaveQuota'] as int? ?? 21;

    int total = 0;
    int approved = 0;
    int pending = 0;
    int rejected = 0;
    int attendanceRequests = 0;
    int annualLeaveUsedDays = 0;

    for (var request in requests) {
      final days = HolidayUtils.getWorkingDaysBetween(request.startDate, request.endDate);

      total++;

      if (request.leaveType == 'Attendance Request') {
        attendanceRequests++;
      }

      switch (request.status.toLowerCase()) {
        case 'approved':
          approved++;
          if (request.leaveType == 'Annual Leave') {
            annualLeaveUsedDays += days;
          }
          break;
        case 'pending':
          pending++;
          break;
        case 'rejected':
          rejected++;
          break;
      }
    }

    final quotaLeft = (totalQuota - annualLeaveUsedDays).clamp(0, totalQuota);

    return {
      'total': total,
      'attendanceRequests': attendanceRequests,
      'approved': approved,
      'pending': pending,
      'rejected': rejected,
      'quotaLeft': quotaLeft,
    };
  }
}
