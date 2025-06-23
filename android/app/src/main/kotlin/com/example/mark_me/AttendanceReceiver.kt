package com.example.mark_me

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.*

class AttendanceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val course = intent.getStringExtra("course") ?: "Class"
        val startTime = intent.getStringExtra("startTime") ?: "??:??"
        val endTime = intent.getStringExtra("endTime") ?: "??:??"

        val triggerTime = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())

        Log.d("KOTLIN_RECEIVER", "Reminder alarm triggered for $course at $triggerTime")
        Log.d("KOTLIN_RECEIVER", "Class: $course | Start: $startTime | End: $endTime")

        // Show 20-minute early notification
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "class_reminder_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Class Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifies 20 minutes before class"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.logo)
            .setContentTitle("⏰ Your class for $course")
            .setContentText("Class starts at $startTime")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(course.hashCode(), notification)
    }
}
