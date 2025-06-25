import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AttendanceProvider with ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<DateTime> getServerTime() async {
    final doc =
        await FirebaseFirestore.instance.collection('server_time').add({'timestamp': FieldValue.serverTimestamp()});
    final snapshot = await doc.get();
    await doc.delete();

    return (snapshot['timestamp'] as Timestamp).toDate();
  }

  Future<void> uploadImage(File image, String activityType) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No authenticated user found");
      }

      final String userId = currentUser.uid;
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage.ref().child('users/$userId/attendance/$fileName.jpg');

      await ref.putFile(image);
      final String downloadUrl = await ref.getDownloadURL();

      final now = await getServerTime();

      final shiftDoc = await _firestore.collection('admin').doc('shift').get();
      final shiftData = shiftDoc.data()!;
      final shiftTimes = Map<String, String>.from(shiftData['shiftTimes']);
      final shiftDays = Map<String, dynamic>.from(shiftData['shiftDays']);

      final today = now.weekday;
      final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][today - 1];

      String? currentShift;
      if (shiftDays['Shift 1']?.contains(weekday) == true) {
        currentShift = 'Shift 1';
      } else if (shiftDays['Shift 2']?.contains(weekday) == true) {
        currentShift = 'Shift 2';
      }

      if (currentShift == null) {
        throw Exception("No shift assigned for today.");
      }

      TimeOfDay parseTime(String str) {
        final parts = str.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      final lateTolerance = parseTime(shiftTimes['Late Tolerance']!);
      final noDailyTolerance = parseTime(shiftTimes['No Daily Wage Tolerance']!);

      bool isLate = false;
      bool noDaily = false;

      if (activityType == 'Clock In') {
        final nowMinutes = now.hour * 60 + now.minute;
        final lateMinutes = lateTolerance.hour * 60 + lateTolerance.minute;
        final noDailyMinutes = noDailyTolerance.hour * 60 + noDailyTolerance.minute;

        isLate = nowMinutes >= lateMinutes;
        noDaily = nowMinutes >= noDailyMinutes;
      }

      Map<String, dynamic> imageData = {
        'url': downloadUrl,
        'uploadedAt': Timestamp.fromDate(now),
        'userEmail': currentUser.email,
        'activityType': activityType,
        'late': isLate,
        'noDaily': noDaily,
      };

      await _firestore.collection('users').doc(userId).collection('attendance').add(imageData);
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> fetchActivities() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("User not authenticated");
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('attendance')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final Timestamp uploadedAt = doc['uploadedAt'];
              final DateTime dateTime = uploadedAt.toDate();
              final date =
                  '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
              final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
              final activityType = doc['activityType'];
              final bool late = doc.data().containsKey('late') ? doc['late'] : false;

              return {
                'url': doc['url'],
                'date': date,
                'time': time,
                'activityType': activityType,
                'late': late,
              };
            })
            .where((element) => element.isNotEmpty)
            .toList());
  }

  Map<String, List<Map<String, dynamic>>> groupActivitiesByDate(List<Map<String, dynamic>> activities) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var activity in activities) {
      final date = activity['date'];
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(activity);
    }
    return grouped;
  }

  int countMonthlyLates(List<Map<String, dynamic>> activities, DateTime selectedMonth) {
    return activities.where((activity) {
      if (activity['activityType'] != 'Clock In') return false;

      final dateParts = activity['date'].split('-');
      if (dateParts.length != 3) return false;

      final activityMonth = int.tryParse(dateParts[1]);
      final activityYear = int.tryParse(dateParts[2]);
      if (activityMonth != selectedMonth.month || activityYear != selectedMonth.year) return false;

      return activity['late'] == true;
    }).length;
  }

  Future<TimeOfDay?> getTodayShiftEndTime() async {
    final now = await getServerTime();

    final shiftDoc = await _firestore.collection('admin').doc('shift').get();
    final shiftData = shiftDoc.data();
    if (shiftData == null) return null;

    final shiftTimes = Map<String, String>.from(shiftData['shiftTimes']);
    final shiftDays = Map<String, dynamic>.from(shiftData['shiftDays']);

    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];

    String? currentShift;
    if (shiftDays['Shift 1']?.contains(weekday) == true) {
      currentShift = 'Shift 1';
    } else if (shiftDays['Shift 2']?.contains(weekday) == true) {
      currentShift = 'Shift 2';
    } else {
      return null;
    }

    final endStr = shiftTimes['$currentShift End'];
    if (endStr == null) return null;

    final parts = endStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
