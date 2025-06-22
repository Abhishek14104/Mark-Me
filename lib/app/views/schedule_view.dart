import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mark_me/app/services/notification_service.dart';
import 'map_picker_view.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  final _formKey = GlobalKey<FormState>();
  final courseController = TextEditingController();

  final List<String> allDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final Map<String, Map<String, dynamic>> selectedDayTimeMap = {};
  final List<Map<String, dynamic>> scheduleList = [];

  LatLng? lastSelectedLocation;

  @override
  void initState() {
    super.initState();
    _loadSchedulesFromDB();
  }

  Future<void> _loadSchedulesFromDB() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .orderBy('timestamp', descending: true)
        .get();

    final List<Map<String, dynamic>> loadedSchedules = [];

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final rawSchedule = data['schedule'] as Map<String, dynamic>;

      final parsedSchedule = rawSchedule.map((day, entry) {
        final location = entry['location'];
        return MapEntry(day, {
          'start': entry['start'],
          'end': entry['end'],
          'location': LatLng(location['lat'], location['lng']),
        });
      });

      loadedSchedules.add({
        'id': doc.id,
        'course': data['course'],
        'schedule': parsedSchedule,
      });
    }

    setState(() {
      scheduleList.clear();
      scheduleList.addAll(loadedSchedules);
    });
  }

  Future<String?> _pickTime(String title) async {
    final time = await showTimePicker(
      context: context,
      helpText: title, // <- Adds a heading
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return null;
    return DateFormat.jm().format(DateTime(0, 1, 1, time.hour, time.minute));
  }

  Future<void> _selectTimeForDay(String day) async {
    final startTime = await _pickTime("Select Start Time for $day");
    if (startTime == null) return;
    final endTime = await _pickTime("Select End Time for $day");
    if (endTime == null) return;

    final location =
        await Navigator.push<LatLng>(
          context,
          MaterialPageRoute(builder: (_) => const MapPickerView()),
        ) ??
        lastSelectedLocation;

    if (location != null) {
      setState(() {
        selectedDayTimeMap[day] = {
          'start': startTime,
          'end': endTime,
          'location': location,
        };
        lastSelectedLocation = location;
      });
    }
  }

  void _addSchedule() async {
    if (_formKey.currentState!.validate() && selectedDayTimeMap.isNotEmpty) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        return;
      }

      final scheduleData = {
        'course': courseController.text.trim(),
        'schedule': selectedDayTimeMap.map((day, data) {
          final LatLng loc = data['location'];
          return MapEntry(day, {
            'start': data['start'],
            'end': data['end'],
            'location': {'lat': loc.latitude, 'lng': loc.longitude},
          });
        }),
        'timestamp': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('schedules')
          .add(scheduleData);

      int notificationIdCounter =
          DateTime.now().millisecondsSinceEpoch % 100000;
      TimeOfDay _parseTimeOfDay(String timeString) {
        final format = DateFormat.jm();
        final dt = format.parse(timeString);
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      }

      for (final entry in selectedDayTimeMap.entries) {
        final weekdayIndex = allDays.indexOf(entry.key) + 1;
        final startTimeString = entry.value['start'];
        final time = _parseTimeOfDay(startTimeString);

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationIdCounter++,
            channelKey: 'basic_channel',
            title: 'Upcoming class: ${courseController.text.trim()}',
            body: 'Starts at ${entry.value['start']} on ${entry.key}',
            notificationLayout: NotificationLayout.Default,
          ),
          schedule: NotificationCalendar(
            weekday: weekdayIndex,
            hour: time.hour,
            minute: time.minute,
            second: 0,
            millisecond: 0,
            repeats: true,
          ),
        );
      }

      final localData = {
        'id': docRef.id,
        'course': courseController.text.trim(),
        'schedule': selectedDayTimeMap.map(
          (day, data) => MapEntry(day, {
            'start': data['start'],
            'end': data['end'],
            'location': data['location'],
          }),
        ),
      };

      setState(() {
        scheduleList.add(localData);
        courseController.clear();
        selectedDayTimeMap.clear();
      });
    }
  }

  void _showDetailsModal(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final schedule = item['schedule'] as Map<String, dynamic>;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['course'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...schedule.entries.map((e) {
                  final loc = e.value['location'] as LatLng;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${e.key}: ${e.value['start']} - ${e.value['end']}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 150,
                        child: FlutterMap(
                          options: MapOptions(center: loc, zoom: 15),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: loc,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Class Schedule")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: courseController,
                    decoration: const InputDecoration(labelText: "Course Name"),
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: allDays.map((day) {
                      final selected = selectedDayTimeMap.containsKey(day);
                      return FilterChip(
                        label: Text(day),
                        selected: selected,
                        onSelected: (_) => _selectTimeForDay(day),
                        onDeleted: selected
                            ? () =>
                                  setState(() => selectedDayTimeMap.remove(day))
                            : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addSchedule,
                    child: const Text("Add Schedule"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Your Schedule",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: scheduleList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final item = scheduleList[i];
                  final schedule = item['schedule'] as Map<String, dynamic>;

                  final days = schedule.keys.join(", ");

                  return Dismissible(
                    key: Key("${item['id']}_${item['course']}_$i"),
                    background: Container(color: Colors.red),
                    onDismissed: (_) async {
                      final removedItem = scheduleList[i];
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      final docId = removedItem['id'];

                      setState(() => scheduleList.removeAt(i));

                      if (uid != null && docId != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('schedules')
                            .doc(docId)
                            .delete();
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${removedItem['course']}"'),
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () async {
                              final scheduleData = {
                                'course': removedItem['course'],
                                'schedule':
                                    (removedItem['schedule']
                                            as Map<String, dynamic>)
                                        .map((day, data) {
                                          final loc =
                                              data['location'] as LatLng;
                                          return MapEntry(day, {
                                            'start': data['start'],
                                            'end': data['end'],
                                            'location': {
                                              'lat': loc.latitude,
                                              'lng': loc.longitude,
                                            },
                                          });
                                        }),
                                'timestamp': FieldValue.serverTimestamp(),
                              };

                              final docRef = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('schedules')
                                  .add(scheduleData);

                              removedItem['id'] = docRef.id;

                              setState(() {
                                scheduleList.insert(i, removedItem);
                              });
                            },
                          ),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          item['course'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text("Days: $days"),
                        onTap: () => _showDetailsModal(item),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}