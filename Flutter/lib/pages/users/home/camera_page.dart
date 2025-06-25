import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/pages/users/all_users_pages.dart';
import 'package:skripsi/widgets/face_painter.dart';
import 'package:skripsi/providers/attendance_provider.dart';
import 'package:skripsi/services/facenet_model_mobile.dart'
    if (dart.library.html) 'package:skripsi/services/facenet_model_web.dart';

class CameraPage extends StatefulWidget {
  final String activityType;

  const CameraPage({super.key, required this.activityType});

  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  CameraLensDirection cameraDirection = CameraLensDirection.front;
  Future<void>? _initializeControllerFuture;
  FaceNetModel faceNet = FaceNetModel();
  late FaceDetector _faceDetector;
  bool isDetecting = false;
  List<Face> detectedFaces = [];
  Timer? _debounceTimer;
  List<bool> livenessFrames = [];
  bool _hasBlinked = false;
  bool _hasSmiled = false;
  bool _hasMovedHead = false;
  DateTime? _lastActionTime;
  late bool isFrontCamera;
  Rect? _latestFaceBoundingBox;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
      enableClassification: true,
      enableContours: true,
      enableTracking: true,
    ));
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    bool granted = await requestCameraPermission();
    if (!granted) return;

    final cameras = await availableCameras();
    for (var camera in cameras) {
      if (camera.lensDirection == cameraDirection) {
        _controller = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        isFrontCamera = _controller!.description.lensDirection == cameraDirection;

        _initializeControllerFuture = _controller!.initialize().then((_) {
          if (mounted) {
            setState(() {});
            Future.delayed(const Duration(milliseconds: 500), () {
              _startFaceDetection();
            });
          }
        });
        break;
      }
    }
  }

  Future<void> _startFaceDetection() async {
    if (_controller == null || isDetecting) return;
    isDetecting = true;

    _controller!.startImageStream((CameraImage image) async {
      if (!mounted || _controller == null) return;

      if (_debounceTimer?.isActive ?? false) return;
      _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
        final WriteBuffer allBytes = WriteBuffer();
        for (Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final InputImage inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _rotationIntToImageRotation(_controller!.description.sensorOrientation),
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );

        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isNotEmpty) {
          final face = faces.first;
          _latestFaceBoundingBox = face.boundingBox;
        }

        if (mounted) {
          setState(() {
            detectedFaces = faces;
          });
          if (faces.isNotEmpty) {
            bool isLive = checkLiveness(faces);
            if (isLive && !isDetecting) {
              await _controller!.stopImageStream();
            }
          }
        }
      });
    });
  }

  bool checkLiveness(List<Face> faces) {
    if (faces.isEmpty) {
      _resetLiveness();
      return false;
    }

    final face = faces.first;

    if (detectFakeFace(face)) {
      _resetLiveness();
      return false;
    }

    if (!_hasBlinked && _checkBlink(face)) {
      _hasBlinked = true;
      _lastActionTime = DateTime.now();
    }

    if (!_hasSmiled && _checkSmile(face)) {
      _hasSmiled = true;
      _lastActionTime = DateTime.now();
    }

    if (!_hasMovedHead && _checkHeadMovement(face)) {
      _hasMovedHead = true;
      _lastActionTime = DateTime.now();
    }

    final actionsCompleted = [_hasBlinked, _hasSmiled, _hasMovedHead].where((x) => x).length;

    if (_lastActionTime != null && DateTime.now().difference(_lastActionTime!) > Duration(seconds: 5)) {
      _resetLiveness();
      return false;
    }

    return actionsCompleted >= 2;
  }

  void _resetLiveness() {
    _hasBlinked = false;
    _hasSmiled = false;
    _hasMovedHead = false;
    _lastActionTime = null;
  }

  bool _checkBlink(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;

    return leftEyeOpen < 0.3 && rightEyeOpen < 0.3;
  }

  bool _checkSmile(Face face) {
    final smileProb = face.smilingProbability ?? 0.0;
    return smileProb > 0.5;
  }

  bool _checkHeadMovement(Face face) {
    final headY = face.headEulerAngleY?.abs() ?? 0.0;
    final headZ = face.headEulerAngleZ?.abs() ?? 0.0;

    return headY > 15 || headZ > 15;
  }

  bool detectFakeFace(Face face) {
    final faceContour = face.contours[FaceContourType.face];
    if (faceContour == null || faceContour.points.length < 5) {
      return true;
    }
    return false;
  }

  void _captureAndDetectFace() async {
    if (detectedFaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No face detected. Try again!")),
      );
      return;
    }

    if (!(_hasBlinked && _hasSmiled) && !(_hasBlinked && _hasMovedHead) && !(_hasSmiled && _hasMovedHead)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Perform 2 of these: blink, smile, or move head"),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      setState(() {
        isDetecting = true;
      });

      await _initializeControllerFuture;
      await _controller!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 300));

      final image = await _controller!.takePicture();
      final imageFile = File(image.path);

      File? croppedFaceFile = await _cropDetectedFace(imageFile);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      if (widget.activityType == 'Face Register') {
        await saveFaceData(croppedFaceFile!, currentUser);
      } else {
        bool isVerified = await faceNet.verifyFace(croppedFaceFile!);
        if (isVerified) {
          await Provider.of<AttendanceProvider>(context, listen: false)
              .uploadImage(croppedFaceFile, widget.activityType);
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Face not recognized. Try again!")),
          );
          _restartFaceDetection();
        }
      }
    } catch (e) {
      debugPrint('Error capturing face: $e');
    } finally {
      setState(() {
        isDetecting = false;
      });
    }
  }

  void _restartFaceDetection() {
    setState(() {
      detectedFaces = [];
      isDetecting = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_controller != null) {
        _startFaceDetection();
      }
    });
  }

  Future<File?> _cropDetectedFace(File imageFile) async {
    try {
      img.Image? fullImage = img.decodeImage(await imageFile.readAsBytes());
      if (fullImage == null) return null;

      fullImage = img.bakeOrientation(fullImage);

      if (_latestFaceBoundingBox == null) {
        return null;
      }

      final Rect faceRect = _latestFaceBoundingBox!;
      final Size previewSize = _controller!.value.previewSize!;
      int sensorOrientation = _controller!.description.sensorOrientation;

      double scaleX, scaleY;

      if (sensorOrientation == 90 || sensorOrientation == 270) {
        scaleX = fullImage.width / previewSize.height;
        scaleY = fullImage.height / previewSize.width;
      } else {
        scaleX = fullImage.width / previewSize.width;
        scaleY = fullImage.height / previewSize.height;
      }

      double left = faceRect.left * scaleX;
      double top = faceRect.top * scaleY;
      double right = faceRect.right * scaleX;
      double bottom = faceRect.bottom * scaleY;

      if (isFrontCamera && sensorOrientation != 90) {
        final double tempLeft = left;
        left = fullImage.width - right;
        right = fullImage.width - tempLeft;
      }

      int x = left.toInt().clamp(0, fullImage.width - 1);
      int y = top.toInt().clamp(0, fullImage.height - 1);
      int width = (right - left).toInt().clamp(1, fullImage.width - x);
      int height = (bottom - top).toInt().clamp(1, fullImage.height - y);

      img.Image croppedFace = img.copyCrop(fullImage, x: x, y: y, width: width, height: height);

      if (isFrontCamera) {
        croppedFace = img.flipHorizontal(croppedFace);
      }

      final String croppedPath = '${imageFile.path}_cropped.jpg';
      File croppedFile = File(croppedPath)..writeAsBytesSync(img.encodeJpg(croppedFace));

      return croppedFile;
    } catch (e) {
      debugPrint("Error cropping face: $e");
      return null;
    }
  }

  Future<void> saveFaceData(File imageFile, User currentUser) async {
    setState(() {
      isDetecting = true;
    });

    List<double> embeddings = faceNet.runFaceNet(imageFile);
    final storageRef = FirebaseStorage.instance.ref().child('users/${currentUser.uid}/face/${currentUser.uid}.jpg');

    await storageRef.putFile(imageFile);
    final downloadUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
      'faceImage': downloadUrl,
      'faceEmbeddings': embeddings,
    }, SetOptions(merge: true));

    setState(() {
      isDetecting = false;
    });

    print("embeddings : $embeddings");

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AllPages()));
  }

  void processImage(File image) async {
    img.Image? fullImage = img.decodeImage(image.readAsBytesSync());
    if (fullImage == null || detectedFaces.isEmpty) return;

    final bool isFrontCamera = _controller!.description.lensDirection == cameraDirection;
    if (isFrontCamera) {
      fullImage = img.flipHorizontal(fullImage);
    }

    Face face = detectedFaces[0];
    img.Image croppedFace = img.copyCrop(
      fullImage,
      x: face.boundingBox.left.toInt(),
      y: face.boundingBox.top.toInt(),
      width: face.boundingBox.width.toInt(),
      height: face.boundingBox.height.toInt(),
    );

    File croppedFile = await faceNet.convertImageToFile(croppedFace, '${image.path}_cropped.jpg');

    List<double> embeddings = faceNet.runFaceNet(croppedFile);
    print("Cropped Face Embeddings: $embeddings");
  }

  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    isDetecting = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller!);
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          if (detectedFaces.isNotEmpty)
            Positioned.fill(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: CustomPaint(
                  painter: FacePainter(
                    detectedFaces,
                    Size(
                      _controller!.value.previewSize!.width,
                      _controller!.value.previewSize!.height,
                    ),
                    sensorOrientation: _controller!.description.sensorOrientation,
                    isFrontCamera: isFrontCamera,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _captureAndDetectFace,
                child: const Icon(Icons.camera),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionIndicator("Blink", _hasBlinked),
                SizedBox(width: 10),
                _buildActionIndicator("Smile", _hasSmiled),
                SizedBox(width: 10),
                _buildActionIndicator("Move", _hasMovedHead),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIndicator(String label, bool completed) {
    return Column(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: completed ? Colors.green : Colors.grey,
        ),
        Text(label),
      ],
    );
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }
}
