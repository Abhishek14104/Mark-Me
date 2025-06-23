package com.example.mark_me

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.location.Location
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.auth.FirebaseAuth
import com.google.android.gms.location.LocationServices
import com.google.firebase.Timestamp
import java.time.LocalDate

class AttendanceService : Service() {

    override fun onCreate() {
        super.onCreate()
        val channelId = "attendance_channel"
        val channel = NotificationChannel(channelId, "Attendance Service", NotificationManager.IMPORTANCE_LOW)
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)

        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("📍 Marking Attendance")
            .setContentText("Checking your location for class attendance...")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()

        startForeground(1, notification)
        Log.d("KOTLIN_SERVICE", "🛠️ AttendanceService created and foreground started")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("KOTLIN_SERVICE", "🚀 AttendanceService triggered")

        val course = intent?.getStringExtra("course") ?: run {
            Log.e("KOTLIN_SERVICE", "❌ Missing 'course' in intent")
            return START_NOT_STICKY
        }

        val startTime = intent.getStringExtra("startTime") ?: "??:??"
        val endTime = intent.getStringExtra("endTime") ?: "??:??"
        val lat = intent.getDoubleExtra("lat", 0.0)
        val lng = intent.getDoubleExtra("lng", 0.0)
        val docId = intent.getStringExtra("docId") ?: return START_NOT_STICKY
        val uid = intent.getStringExtra("uid") ?: return START_NOT_STICKY

        Log.d("KOTLIN_SERVICE", "📚 Course: $course | Start: $startTime | End: $endTime")

        val client = LocationServices.getFusedLocationProviderClient(this)

        client.lastLocation.addOnSuccessListener { location: Location? ->
            if (location != null) {
                val distance = FloatArray(1)
                Location.distanceBetween(location.latitude, location.longitude, lat, lng, distance)

                val status = if (distance[0] <= 100) "Present" else "Absent"
                val today = LocalDate.now().toString()

                Log.d("KOTLIN_SERVICE", "📍 Distance from class: ${"%.2f".format(distance[0])} meters")
                Log.d("KOTLIN_SERVICE", "✅ Status: $status")

                FirebaseFirestore.getInstance()
                    .collection("users")
                    .document(uid)
                    .collection("schedules")
                    .document(docId)
                    .collection("attendance")
                    .document(today)
                    .set(
                        mapOf(
                            "status" to status,
                            "timestamp" to Timestamp.now()
                        )
                    )
                    .addOnSuccessListener {
                        Log.d("KOTLIN_SERVICE", "✅ Attendance saved successfully for $course")
                        stopSelf()
                    }
                    .addOnFailureListener {
                        Log.e("KOTLIN_SERVICE", "❌ Failed to save attendance", it)
                        stopSelf()
                    }
            } else {
                Log.e("KOTLIN_SERVICE", "⚠️ Location null — skipping attendance mark")
                stopSelf()
            }
        }

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
