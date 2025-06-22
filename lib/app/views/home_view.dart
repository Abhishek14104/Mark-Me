import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mark_me/app/routes/app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final today = DateTime.now();
    final dateString = today.toIso8601String().substring(0, 10);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
  await FirebaseAuth.instance.signOut();
  Get.offAllNamed(AppRoutes.login);
},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.schedule),
        icon: const Icon(Icons.add),
        label: const Text("Edit Schedule"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('schedules')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final scheduleDocs = snapshot.data!.docs;

          if (scheduleDocs.isEmpty) {
            return const Center(child: Text("No classes scheduled."));
          }

          return ListView.builder(
            itemCount: scheduleDocs.length,
            itemBuilder: (_, i) {
              final doc = scheduleDocs[i];
              final course = doc['course'];
              final scheduleId = doc.id;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('schedules')
                    .doc(scheduleId)
                    .collection('attendance')
                    .doc(dateString)
                    .snapshots(),
                builder: (context, attendanceSnapshot) {
                  String status = "Not Marked";
                  if (attendanceSnapshot.hasData &&
                      attendanceSnapshot.data!.exists) {
                    final data =
                        attendanceSnapshot.data!.data() as Map<String, dynamic>;
                    status = data['status'] ?? "Not Marked";
                  }

                  return Card(
                    child: ListTile(
                      title: Text(course),
                      subtitle: Text("Today's Attendance: $status"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditDialog(
                              context, uid, scheduleId, dateString, status);
                        },
                      ),
                      onTap: () => Get.toNamed(
                        AppRoutes.attendanceDetail,
                        arguments: {
                          'scheduleId': scheduleId,
                          'course': course,
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, String uid, String scheduleId,
      String date, String currentStatus) {
    final controller = TextEditingController(text: currentStatus);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Attendance"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
              labelText: "Attendance Status",
              hintText: "e.g. Present, Teacher absent, Rainy day"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStatus = controller.text.trim();
              if (newStatus.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .collection("schedules")
                    .doc(scheduleId)
                    .collection("attendance")
                    .doc(date)
                    .set({
                  "status": newStatus,
                  "timestamp": FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
