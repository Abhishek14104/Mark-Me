package com.example.mark_me

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import java.text.SimpleDateFormat
import java.util.*

object ScheduleManager {

    fun setupAlarms(context: Context, uid: String) {
        val firestore = FirebaseFirestore.getInstance()

        val daysMap = mapOf(
            "Mon" to Calendar.MONDAY,
            "Tue" to Calendar.TUESDAY,
            "Wed" to Calendar.WEDNESDAY,
            "Thu" to Calendar.THURSDAY,
            "Fri" to Calendar.FRIDAY,
            "Sat" to Calendar.SATURDAY,
            "Sun" to Calendar.SUNDAY
        )

        firestore.collection("users").document(uid)
            .collection("schedules")
            .get()
            .addOnSuccessListener { result ->
                for (doc in result) {
                    val course = doc.getString("course") ?: continue
                    val schedule = doc.get("schedule") as? Map<*, *> ?: continue

                    for ((day, value) in schedule) {
                        val entry = value as? Map<*, *> ?: continue
                        val start = entry["start"] as? String ?: continue
                        val end = entry["end"] as? String ?: continue
                        val location = entry["location"] as? Map<*, *> ?: continue

                        val sdf = SimpleDateFormat("h:mm a", Locale.ENGLISH)
                        val cleanStart = start.replace('\u202F', ' ').replace('\u00A0', ' ')
                        val cleanEnd = end.replace('\u202F', ' ').replace('\u00A0', ' ')
                        val parsedStart = sdf.parse(cleanStart) ?: continue
                        val parsedEnd = sdf.parse(cleanEnd) ?: continue

                        val now = Calendar.getInstance()
                        val dayOfWeek = daysMap[day] ?: continue

                        val classCal = Calendar.getInstance().apply {
                            timeInMillis = now.timeInMillis
                            set(Calendar.DAY_OF_WEEK, dayOfWeek)
                            set(Calendar.HOUR_OF_DAY, parsedStart.hours)
                            set(Calendar.MINUTE, parsedStart.minutes)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)

                            if (timeInMillis <= now.timeInMillis) {
                                add(Calendar.WEEK_OF_YEAR, 1)
                            }
                        }

                        val formattedStart = sdf.format(parsedStart)
                        val formattedEnd = sdf.format(parsedEnd)

                        // 20-min Reminder
                        scheduleAlarm(
                            context,
                            (classCal.clone() as Calendar).apply { add(Calendar.MINUTE, -20) },
                            AttendanceReceiver::class.java,
                            doc.id + day + "_REMINDER",
                            course,
                            location,
                            doc.id,
                            uid,
                            formattedStart,
                            formattedEnd
                        )

                        // Midpoint Attendance - calculated correctly using total minutes
                        val startMinutes = parsedStart.hours * 60 + parsedStart.minutes
                        val endMinutes = parsedEnd.hours * 60 + parsedEnd.minutes
                        val midMinutes = (startMinutes + endMinutes) / 2
                        val midHour = midMinutes / 60
                        val midMinute = midMinutes % 60

                        val midCal = Calendar.getInstance().apply {
                            timeInMillis = now.timeInMillis
                            set(Calendar.DAY_OF_WEEK, dayOfWeek)
                            set(Calendar.HOUR_OF_DAY, midHour)
                            set(Calendar.MINUTE, midMinute)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)

                            if (timeInMillis <= now.timeInMillis) {
                                add(Calendar.WEEK_OF_YEAR, 1)
                            }
                        }

                        scheduleAlarm(
                            context,
                            midCal,
                            MidClassReceiver::class.java,
                            doc.id + day + "_ATTENDANCE",
                            course,
                            location,
                            doc.id,
                            uid,
                            formattedStart,
                            formattedEnd
                        )
                    }
                }
            }
    }

    private fun scheduleAlarm(
        context: Context,
        cal: Calendar,
        receiverClass: Class<*>,
        requestKey: String,
        course: String,
        location: Map<*, *>,
        docId: String,
        uid: String,
        startTime: String,
        endTime: String
    ) {
        val intent = Intent(context, receiverClass).apply {
            putExtra("course", course)
            putExtra("lat", location["lat"].toString().toDouble())
            putExtra("lng", location["lng"].toString().toDouble())
            putExtra("docId", docId)
            putExtra("uid", uid)
            putExtra("startTime", startTime)
            putExtra("endTime", endTime)
        }

        val alarmIntent = PendingIntent.getBroadcast(
            context,
            requestKey.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            cal.timeInMillis,
            alarmIntent
        )

        val timeStr = SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss", Locale.getDefault()).format(cal.time)
        val type = if (receiverClass == AttendanceReceiver::class.java) "🔔 Reminder" else "🛰️ Attendance"
        Log.d("KOTLIN_ALARM", "$type alarm set for $course at $timeStr")
    }
}
