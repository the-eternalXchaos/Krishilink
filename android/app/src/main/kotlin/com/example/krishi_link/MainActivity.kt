package com.example.krishi_link

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Facebook SDK only if available
        try {
            // Facebook SDK initialization - optional
            // If Facebook login is needed, uncomment these lines and ensure
            // proper Facebook SDK configuration is in place
            
            // val facebookSdk = Class.forName("com.facebook.FacebookSdk")
            // val appEventsLogger = Class.forName("com.facebook.appevents.AppEventsLogger")
            // facebookSdk.getMethod("sdkInitialize", android.content.Context::class.java).invoke(null, applicationContext)
            // appEventsLogger.getMethod("activateApp", android.app.Application::class.java).invoke(null, application)
            
        } catch (e: Exception) {
            // Facebook SDK not properly configured or not needed - continue without it
            android.util.Log.d("MainActivity", "Facebook SDK initialization skipped: ${e.message}")
        }
    }
}
