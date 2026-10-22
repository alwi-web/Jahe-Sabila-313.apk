package com.sabila313.sabila313

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Kanal "pesanan" berprioritas tinggi: notifikasi muncul sebagai pop-up di layar,
        // bukan hanya masuk diam-diam ke laci notifikasi (kanal bawaan Firebase).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val kanal = NotificationChannel("pesanan", "Pesanan", NotificationManager.IMPORTANCE_HIGH)
            kanal.description = "Pesanan baru, status pesanan, dan nomor resi"
            kanal.enableVibration(true)
            getSystemService(NotificationManager::class.java).createNotificationChannel(kanal)
        }
    }
}
