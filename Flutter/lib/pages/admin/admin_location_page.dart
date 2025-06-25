import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:skripsi/constants/app_colors.dart';

class AdminLocationPage extends StatefulWidget {
  const AdminLocationPage({super.key});

  @override
  State<AdminLocationPage> createState() => _AdminLocationPageState();
}

class _AdminLocationPageState extends State<AdminLocationPage> {
  final TextEditingController _radiusController = TextEditingController();
  LatLng? _selectedLocation;
  double radius = 50;
  bool isLoading = true;
  LatLng center = const LatLng(3.594629, 98.693063);
  double zoom = 20;

  @override
  void initState() {
    super.initState();
    _radiusController.text = radius.toString();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('geofence').doc('location').get();

      if (doc.exists) {
        setState(() {
          _selectedLocation = LatLng(doc['latitude'], doc['longitude']);
          radius = doc['radius'].toDouble();
          _radiusController.text = radius.toString();
          zoom = doc['zoom'].toDouble();
        });
      }
    } catch (e) {
      debugPrint("Error loading location: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location on the map.")),
      );
      return;
    }

    if (radius <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Radius must be a positive number.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('geofence').doc('location').set({
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'radius': radius,
      'zoom': zoom,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Location saved successfully!")),
    );
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PT. SURYA CEMERLANG LOGISTIK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: zoom,
                          onMapEvent: (event) {
                            setState(() {
                              zoom = event.camera.zoom;
                            });
                          },
                          onTap: (_, position) => _onMapTapped(position),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            tileProvider: CancellableNetworkTileProvider(),
                          ),
                          if (_selectedLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          if (_selectedLocation != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _selectedLocation!,
                                  radius: radius,
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  borderColor: Colors.blue,
                                  borderStrokeWidth: 1,
                                  useRadiusInMeter: true,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: radius.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Radius (meters)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          onChanged: (value) {
                            final parsed = double.tryParse(value);
                            if (parsed != null && parsed > 0) {
                              setState(() {
                                radius = parsed;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_selectedLocation != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Text('Latitude: ${_selectedLocation!.latitude}'),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Text('Longitude: ${_selectedLocation!.longitude}'),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Text('Zoom: ${zoom.toStringAsFixed(2)}'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 18, color: AppColors.text1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
