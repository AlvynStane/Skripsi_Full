import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfileProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _name = '';
  String _position = '';
  String _profileImage = '';
  String _email = '';
  String _faceImage = '';
  bool isAdmin = false;

  String get name => _name;
  String get position => _position;
  String get profileImage => _profileImage;
  String get email => _email;
  String get faceImage => _faceImage;

  Future<void> loadProfile() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User  not authenticated");

      final adminDoc = await _firestore.collection('admin').doc(currentUser.uid).get();
      isAdmin = kIsWeb && adminDoc.exists;

      final doc = await _firestore
          .collection(isAdmin ? 'admin' : 'users')
          .doc(isAdmin ? currentUser.uid : '${currentUser.uid}/profile/${currentUser.uid}')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        _name = data['name'] ?? "User";
        _position = data['position'] ?? "-";
        _profileImage = data['profileImage'] ?? "";
        _email = data['email'] ?? currentUser.email ?? "";
      } else {
        _name = "User";
        _position = "-";
        _profileImage = '';
        _email = currentUser.email ?? "";
      }

      if (!isAdmin) {
        final faceDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (faceDoc.exists && faceDoc.data() != null) {
          final faceData = faceDoc.data() as Map<String, dynamic>;
          _faceImage = faceData['faceImage'] ?? "";
        } else {
          _faceImage = "";
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profile: $e');
      throw Exception('Failed to load profile');
    }
  }

  Future<void> updateProfile(String name, String position, String email,
      {File? profileImage, Uint8List? adminImage}) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User  not authenticated");

      _name = name;
      _position = position;
      _email = email;

      String fileName =
          isAdmin ? 'admin/${currentUser.uid}.jpg' : 'users/${currentUser.uid}/profile/${currentUser.uid}.jpg';
      Reference ref = _storage.ref().child(fileName);

      if (profileImage != null && profileImage.existsSync()) {
        await ref.putFile(profileImage);
        _profileImage = await ref.getDownloadURL();
      } else if (adminImage != null) {
        await ref.putData(adminImage, SettableMetadata(contentType: "image/jpeg"));
        _profileImage = await ref.getDownloadURL();
      }

      await _firestore
          .collection(isAdmin ? 'admin' : 'users')
          .doc(isAdmin ? currentUser.uid : '${currentUser.uid}/profile/${currentUser.uid}')
          .set({
        'name': _name,
        'position': _position,
        'email': _email,
        'profileImage': _profileImage,
      }, SetOptions(merge: true));

      await loadProfile();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  Future selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List imageBytes = await image.readAsBytes();
      return imageBytes;
    }
    return null;
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      if (currentPassword == newPassword) {
        throw Exception("New password must be different from the current password!");
      }

      await user.updatePassword(newPassword);
      debugPrint("Password updated successfully!");
    } on FirebaseAuthException {
      throw Exception("Current password is incorrect!");
    }
  }

  Future<void> removeProfileImage() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not authenticated");

      String fileName =
          isAdmin ? 'admin/${currentUser.uid}.jpg' : 'users/${currentUser.uid}/profile/${currentUser.uid}.jpg';
      Reference ref = _storage.ref().child(fileName);

      await ref.delete();

      await _firestore
          .collection(isAdmin ? 'admin' : 'users')
          .doc(isAdmin ? currentUser.uid : '${currentUser.uid}/profile/${currentUser.uid}')
          .update({
        'profileImage': "",
      });

      _profileImage = "";
      notifyListeners();

      debugPrint("Profile image removed successfully!");
    } catch (e) {
      debugPrint("Failed to remove profile image: $e");
      throw Exception("Failed to remove profile image");
    }
  }
}
