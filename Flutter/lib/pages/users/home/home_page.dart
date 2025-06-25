import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/pages/users/home/camera_page.dart';
import 'package:skripsi/widgets/home_header_profile.dart';
import 'package:skripsi/widgets/image_dialog.dart';
import 'package:skripsi/widgets/month_year_filter_dialog.dart';
import 'package:skripsi/widgets/today_attendance_section.dart';
import 'package:skripsi/providers/attendance_provider.dart';
import 'package:skripsi/providers/geofence_provider.dart';
import 'package:skripsi/providers/profile_provider.dart';
import 'package:skripsi/utility/date_extensions.dart';
import 'package:skripsi/widgets/activity_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? selectedMonth;
  late GeofenceProvider geofenceProvider;
  bool _isGeofenceInitialized = false;
  String? nowDate;

  @override
  void initState() {
    super.initState();
    _checkUserFaceData();
    _loadServerDate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isGeofenceInitialized) {
      geofenceProvider = Provider.of<GeofenceProvider>(context, listen: false);
      _isGeofenceInitialized = true;
    }
  }

  Future<void> _loadServerDate() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final serverTime = await attendanceProvider.getServerTime();
    if (!mounted) return;
    setState(() {
      nowDate = serverTime.toFormattedString();
      selectedMonth = DateTime(serverTime.year, serverTime.month);
    });
  }

  void _checkUserFaceData() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await profileProvider.loadProfile();

    if (profileProvider.faceImage.isEmpty) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CameraPage(activityType: 'Face Register'),
          ),
        );
      });
    }
  }

  void _attemptClock(String activityType) async {
    bool insideGeofence = await geofenceProvider.isInsideGeofence(context);

    if (insideGeofence) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPage(activityType: activityType),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are outside the designated area!')),
      );
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => ImageDialog(imageUrl: imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final activitiesStream = attendanceProvider.fetchActivities();
    
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 75,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.background2,
          title: HomeHeaderProfile()),
      body: (selectedMonth == null || nowDate == null)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: activitiesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('An error occurred: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final activities = snapshot.data ?? [];

                  final clockInActivity = activities.firstWhere(
                    (activity) => activity['activityType'] == 'Clock In' && activity['date'] == nowDate,
                    orElse: () => {'time': '-', 'late': false},
                  );
                  final clockOutActivity = activities.firstWhere(
                    (activity) => activity['activityType'] == 'Clock Out' && activity['date'] == nowDate,
                    orElse: () => {'time': '-'},
                  );

                  final clockInTime = clockInActivity['time'] ?? '-';
                  final clockOutTime = clockOutActivity['time'] ?? '-';
                  final isLateClockIn = clockInActivity['late'] == true;

                  final hasClockIn = activities.any((a) => a['activityType'] == 'Clock In' && a['date'] == nowDate);
                  final hasClockOut = activities.any((a) => a['activityType'] == 'Clock Out' && a['date'] == nowDate);

                  final lateCount = attendanceProvider.countMonthlyLates(activities, selectedMonth!);

                  final selectedMonthActivities = activities.where((activity) {
                    try {
                      final date = DateFormat('dd-MM-yyyy').parseStrict(activity['date']);
                      return date.month == selectedMonth!.month && date.year == selectedMonth!.year;
                    } catch (e) {
                      return false;
                    }
                  }).toList();

                  final groupedActivities = attendanceProvider.groupActivitiesByDate(selectedMonthActivities);
                  final sortedKeys = groupedActivities.keys.toList()
                    ..sort((a, b) {
                      final aDate = DateTime.parse('${a.split('-')[2]}-${a.split('-')[1]}-${a.split('-')[0]}');
                      final bDate = DateTime.parse('${b.split('-')[2]}-${b.split('-')[1]}-${b.split('-')[0]}');
                      return bDate.compareTo(aDate);
                    });

                  return FutureBuilder<TimeOfDay?>(
                    future: attendanceProvider.getTodayShiftEndTime(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final shiftEnd = snapshot.data;
                      if (shiftEnd == null) {
                        return const Center(child: Text('No shift end time available for today.'));
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TodayAttendanceSection(
                            clockInTime: clockInTime,
                            clockOutTime: clockOutTime,
                            hasClockIn: hasClockIn,
                            hasClockOut: hasClockOut,
                            onClockPressed: _attemptClock,
                            isLateClockIn: isLateClockIn,
                            shiftEnd: shiftEnd,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Your Activity",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              MonthYearFilterDialog(
                                months: List.generate(12, (i) => DateFormat.MMMM().format(DateTime(0, i + 1))),
                                years: List.generate(10, (i) => (DateTime.now().year - i).toString()),
                                selectedMonth: DateFormat.MMMM().format(selectedMonth!),
                                selectedYear: selectedMonth!.year.toString(),
                                onMonthChanged: (month) {
                                  final newMonth = DateFormat.MMMM().parse(month).month;
                                  setState(() {
                                    selectedMonth = DateTime(selectedMonth!.year, newMonth);
                                  });
                                },
                                onYearChanged: (year) {
                                  setState(() {
                                    selectedMonth = DateTime(int.parse(year), selectedMonth!.month);
                                  });
                                },
                              ),
                            ],
                          ),
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: AppColors.cancel),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "This Month Late",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "$lateCount times",
                                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: sortedKeys.length,
                                  itemBuilder: (context, index) {
                                    final date = sortedKeys[index];
                                    final items = groupedActivities[date]!;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          date,
                                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                        ),
                                        const Divider(thickness: 1),
                                        ...items.map((activity) {
                                          final imageUrl = activity['url'];
                                          return ActivityTile(
                                            title: activity['activityType'] ?? 'Unknown',
                                            time: activity['time'],
                                            date: activity['date'],
                                            onTap: () {
                                              if (imageUrl != null && imageUrl.isNotEmpty) {
                                                _showImageDialog(context, imageUrl);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('No image available for this activity')),
                                                );
                                              }
                                            },
                                          );
                                        }),
                                        const SizedBox(height: 12),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
