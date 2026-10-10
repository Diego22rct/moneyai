package com.github.diego22rct.moneyai

import com.github.diego22rct.moneyai.capture.NotificationCapturePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NotificationCapturePlugin.register(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
