package com.shortzz.deepar

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * MainActivity with DeepAR plugin registration (DISABLED - DeepAR SDK not configured)
 */
class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Register DeepAR plugin - DISABLED: DeepAR SDK not configured
        // flutterEngine
        //     .plugins
        //     .add(DeepARFlutterPlugin())
    }
}