import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> markAttendance({
    required String scheduleId,
    required String status, // "Present" or "Absent"
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final today = DateTime.now();
    final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(scheduleId)
        .collection('attendance')
        .doc(dateKey)
        .set({
          'status': status,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  static Future<String?> getTodayAttendanceStatus(String scheduleId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final today = DateTime.now();
    final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(scheduleId)
        .collection('attendance')
        .doc(dateKey)
        .get();

    return doc.data()?['status'];
  }

  static Future<Map<String, dynamic>> getAttendanceHistory(String scheduleId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(scheduleId)
        .collection('attendance')
        .orderBy('timestamp', descending: true)
        .get();

    return {
      'total': snapshot.docs.length,
      'present': snapshot.docs.where((d) => d['status'] == 'Present').length,
      'absent': snapshot.docs.where((d) => d['status'] == 'Absent').length,
      'records': snapshot.docs.map((doc) => {
        'date': doc.id,
        'status': doc['status'],
      }).toList(),
    };
  }
}
