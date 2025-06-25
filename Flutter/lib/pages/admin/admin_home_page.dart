import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  DateTime selectedDate = DateTime.now();
  int presentCount = 0;
  int absentCount = 0;
  int timeOffCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      QuerySnapshot usersSnapshot = await firestore.collection('users').get();
      int present = 0, absent = 0, timeOff = 0;

      for (var userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        AggregateQuerySnapshot attendanceCount = await firestore
            .collection('users')
            .doc(userId)
            .collection('attendance')
            .where('uploadedAt', isGreaterThanOrEqualTo: startOfDay)
            .where('uploadedAt', isLessThan: endOfDay)
            .count()
            .get();

        bool isPresent = attendanceCount.count! > 0;

        QuerySnapshot leaveSnapshot = await firestore
            .collection('users')
            .doc(userId)
            .collection('leave_requests')
            .where('status', isEqualTo: "Approved")
            .get();

        bool isOnLeave = leaveSnapshot.docs.any((doc) {
          DateTime startDate = (doc['startDate'] as Timestamp).toDate();
          DateTime endDate = (doc['endDate'] as Timestamp).toDate();
          return selectedDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              selectedDate.isBefore(endDate.add(const Duration(days: 1)));
        });

        if (isPresent) {
          present++;
        } else if (isOnLeave) {
          timeOff++;
        } else {
          absent++;
        }
      }

      if (!mounted) return;

      setState(() {
        presentCount = present;
        absentCount = absent;
        timeOffCount = timeOff;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              tileMode: TileMode.clamp,
            ),
          ),
        ),
        title: const Text(
          "Today's Attendance",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(selectedDate),
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.calendar_today, color: Colors.black, size: 22),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildDashboardCard(
                          title: "Present",
                          value: presentCount.toString(),
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDashboardCard(
                          title: "Absent",
                          value: absentCount.toString(),
                          color: Colors.red,
                          icon: Icons.cancel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDashboardCard(
                          title: "Time Off",
                          value: timeOffCount.toString(),
                          color: Colors.orange,
                          icon: Icons.beach_access,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: color.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
