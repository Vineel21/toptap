package com.fourtech.toptap

import android.util.Log
import io.flutter.app.FlutterApplication

class ShortzApplication : FlutterApplication() {
    
    companion object {
        private const val TAG = "ShortzApplication"
    }
    
    override fun onCreate() {
        super.onCreate()
        
        // Set up global exception handler for OnePlus provider errors
        setupGlobalExceptionHandler()
        
        Log.d(TAG, "✅ ShortzApplication initialized with OnePlus error handling")
    }
    
    private fun setupGlobalExceptionHandler() {
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            // Check if this is a OnePlus provider error
            if (isOnePlusProviderError(throwable)) {
                Log.w(TAG, "🔧 Caught OnePlus provider error - handled gracefully: ${throwable.message}")
                // Don't crash the app for OnePlus provider errors
                return@setDefaultUncaughtExceptionHandler
            }
            
            // For all other exceptions, use the default handler
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }
    
    private fun isOnePlusProviderError(throwable: Throwable): Boolean {
        val message = throwable.message ?: ""
        val stackTrace = throwable.stackTraceToString()
        
        // Check for OnePlus statistics provider errors
        return message.contains("oplus.statistics.provider") ||
               message.contains("OplusStatistics") ||
               message.contains("Failed to find provider info for com.oplus.statistics.provider") ||
               stackTrace.contains("OplusStatistics") ||
               stackTrace.contains("oplus.statistics.provider")
    }
}
