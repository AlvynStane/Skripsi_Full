import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GeofenceProvider extends ChangeNotifier {
  double? latitude;
  double? longitude;
  double? radius;
  bool isLoaded = false;
  Stream<DocumentSnapshot>? _subscription;

  GeofenceProvider() {
    _startListening();
  }

  void _startListening() {
    _subscription = FirebaseFirestore.instance.collection('geofence').doc('location').snapshots();

    _subscription!.listen((doc) {
      if (doc.exists) {
        latitude = (doc['latitude'] as num).toDouble();
        longitude = (doc['longitude'] as num).toDouble();
        radius = (doc['radius'] as num).toDouble();
        isLoaded = true;
        notifyListeners();
      }
    });
  }

  Future<bool> isInsideGeofence(BuildContext context) async {
    if (!isLoaded || latitude == null || longitude == null || radius == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geofence data not loaded. Please try again.')),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied.')),
      );
      return false;
    }

    final position = await Geolocator.getCurrentPosition();
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      latitude!,
      longitude!,
    );

    return distance <= radius!;
  }
}
