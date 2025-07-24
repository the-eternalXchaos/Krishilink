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

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.krishi_link"
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
}
