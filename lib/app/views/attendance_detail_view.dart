import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AttendanceDetailView extends StatelessWidget {
  const AttendanceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final scheduleId = args['scheduleId'];
    final course = args['course'];
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Attendance - $course")),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('schedules')
            .doc(scheduleId)
            .collection('attendance')
            .orderBy(FieldPath.documentId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final present = <String>[];
          final absent = <String>[];
          final others = <Map<String, String>>[];

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final rawStatus = data['status'] ?? "Not Marked";
            final status = rawStatus.toString().trim().toLowerCase();
            final date = doc.id;

            if (status == 'present') {
              present.add(date);
            } else if (status == 'absent') {
              absent.add(date);
            } else {
              others.add({
                'date': date,
                'status': rawStatus,
              });
            }
          }

          final total = present.length + absent.length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Classes (counted): $total", style: const TextStyle(fontSize: 16)),
                Text("Total Present: ${present.length}", style: const TextStyle(fontSize: 16)),
                Text("Total Absent: ${absent.length}", style: const TextStyle(fontSize: 16)),
                const Divider(height: 30),
                const Text("History", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      ...present.map((d) => ListTile(
                            leading: const Icon(Icons.check, color: Colors.green),
                            title: Text("Present - ${DateFormat.yMMMMd().format(DateTime.parse(d))}"),
                          )),
                      ...absent.map((d) => ListTile(
                            leading: const Icon(Icons.close, color: Colors.red),
                            title: Text("Absent - ${DateFormat.yMMMMd().format(DateTime.parse(d))}"),
                          )),
                      ...others.map((entry) => ListTile(
                            leading: const Icon(Icons.info_outline, color: Colors.orange),
                            title: Text("${entry['status']} - ${DateFormat.yMMMMd().format(DateTime.parse(entry['date']!))}"),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
