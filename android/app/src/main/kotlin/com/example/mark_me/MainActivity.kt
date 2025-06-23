package com.example.mark_me

import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.mark_me/alarm")
            .setMethodCallHandler { call, result ->
                if (call.method == "setupAlarms") {
                    val uid = call.argument<String>("uid")
                    if (uid != null) {
                        ScheduleManager.setupAlarms(this, uid)
                        result.success(null)
                    } else {
                        result.error("NO_UID", "UID not passed from Dart", null)
                    }
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FirebaseApp.initializeApp(this)
        Log.d("KOTLIN", "MainActivity initialized")

        val auth = FirebaseAuth.getInstance()
        auth.addAuthStateListener {
            val user = it.currentUser
            if (user != null) {
                Log.d("KOTLIN", "User logged in: ${user.uid}")
                ScheduleManager.setupAlarms(this, user.uid)
            }
        }
    }
}
