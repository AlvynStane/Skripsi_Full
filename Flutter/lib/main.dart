import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/pages/auth/splash_page.dart';
import 'package:skripsi/providers/auth_provider.dart';
import 'package:skripsi/providers/attendance_provider.dart';
import 'package:skripsi/providers/geofence_provider.dart';
import 'package:skripsi/providers/profile_provider.dart';
import 'package:skripsi/providers/request_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: "AIzaSyC49Z8bJ9rZi8E1wRq38fQo-_fq71ivBAE",
            authDomain: "amitofochat.firebaseapp.com",
            projectId: "amitofochat",
            storageBucket: "amitofochat.appspot.com",
            messagingSenderId: "420716583804",
            appId: "1:420716583804:web:4cedd74dce44df8404a2f9",
            measurementId: "G-8QGWCRNJWY",
          )
        : null,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => MyAuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => LeaveRequestProvider()),
        ChangeNotifierProvider(create: (_) => GeofenceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
