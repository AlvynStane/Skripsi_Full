import 'dart:io';
import 'package:image/image.dart' as img;

class FaceNetModel {
  Future<bool> verifyFace(File capturedImage) async {
    return false;
  }

  List<double> runFaceNet(File imageFile) {
    return [];
  }

  Future<File> convertImageToFile(img.Image image, String filePath) async {
    return File(filePath);
  }
}
