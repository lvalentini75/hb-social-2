package com.mycompany.CounterApp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("hb_calls", "Chiamate HB Social", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Notifiche per le chiamate in arrivo"
            channel.enableVibration(true)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
