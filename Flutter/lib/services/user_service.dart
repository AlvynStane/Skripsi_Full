import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static Future<DateTime> getJoinDate(String uid) async {
    final snapshot = await FirebaseFirestore.instance.doc('/users/$uid/profile/$uid').get();
    final joinDateString = snapshot.data()?['joinDate'];
    if (joinDateString == null) {
      throw Exception("Join date not found.");
    }
    return DateTime.tryParse(joinDateString) ?? DateTime(1970);
  }
}
