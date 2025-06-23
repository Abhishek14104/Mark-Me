package com.example.mark_me

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.android.gms.location.LocationServices
import java.text.SimpleDateFormat
import java.util.*

class MidClassReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val course = intent.getStringExtra("course") ?: return
        val docId = intent.getStringExtra("docId") ?: return
        val targetLat = intent.getDoubleExtra("lat", 0.0)
        val targetLng = intent.getDoubleExtra("lng", 0.0)
        val startTime = intent.getStringExtra("startTime") ?: "??"
        val endTime = intent.getStringExtra("endTime") ?: "??"

        val currentTime = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())

        Log.d("KOTLIN_MID", "MidClassReceiver triggered at $currentTime for $course")
        Log.d("KOTLIN_MID", "Class timing: $startTime --- $endTime")
        Log.d("KOTLIN_MID", "Expected location: [$targetLat, $targetLng]")

        val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)

        fusedLocationClient.lastLocation.addOnSuccessListener { location ->
            val currentLat = location?.latitude ?: 0.0
            val currentLng = location?.longitude ?: 0.0

            val distance = FloatArray(1)
            android.location.Location.distanceBetween(
                currentLat, currentLng,
                targetLat, targetLng,
                distance
            )

            val isPresent = distance[0] <= 100
            val status = if (isPresent) "Present" else "Absent"

            Log.d("KOTLIN_MID", "Current location: [$currentLat, $currentLng]")
            Log.d("KOTLIN_MID", "Distance to class: ${"%.2f".format(distance[0])} meters")
            Log.d("KOTLIN_MID", "Status determined: $status")

            val uid = FirebaseAuth.getInstance().currentUser?.uid ?: return@addOnSuccessListener
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

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
                        "timestamp" to System.currentTimeMillis()
                    )
                )
                .addOnSuccessListener {
                    Log.d("KOTLIN_MID", "Attendance saved in Firestore for $course")
                }
                .addOnFailureListener {
                    Log.e("KOTLIN_MID", "Failed to save attendance: ${it.localizedMessage}")
                }

            // Show result notification
            val channelId = "attendance_result_channel"
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    "Attendance Result",
                    NotificationManager.IMPORTANCE_HIGH
                )
                manager.createNotificationChannel(channel)
            }

            val notification = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.logo)
                .setContentTitle("📋 $course")
                .setContentText("Marked as: $status")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .build()

            manager.notify((course + today).hashCode(), notification)

        }.addOnFailureListener {
            Log.e("KOTLIN_MID", "Location fetch failed: ${it.localizedMessage}")
        }
    }
}
