plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Correct way to apply the plugin
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
}

android {
    namespace = "com.example.krishi_link"
    compileSdk = 35
    ndkVersion = "27.0.12077973"
    
    // Use Java 17 compatibility for Android development (recommended)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // Target Java 17 for best Android compatibility
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.krishi_link"
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex for large app
        multiDexEnabled = true
        
        // Add any additional configurations for SignalR/WebSocket support
        manifestPlaceholders["usesCleartextTraffic"] = "true"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    val kotlinVersion = "2.1.0"
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
    implementation("com.google.firebase:firebase-analytics-ktx:21.0.0") // Firebase Analytics
    implementation("com.google.firebase:firebase-auth-ktx:21.0.1") // Firebase Auth
    implementation("com.google.firebase:firebase-firestore-ktx:24.0.0") // Firestore
    implementation("com.google.firebase:firebase-messaging-ktx:23.1.0") // Firebase Messaging
    implementation("com.facebook.android:facebook-android-sdk:17.0.0") // Facebook SDK
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    
    // WebSocket and HTTP support for SignalR
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    
    // Multidex support for large apps
    implementation("androidx.multidex:multidex:2.0.1")
}
