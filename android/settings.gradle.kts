// Block to manage plugin configurations
pluginManagement {
    // Read the flutter SDK path from the local.properties file
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    // Include the Flutter build tools from the flutter SDK
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    // Define repositories for Gradle to fetch dependencies from
    repositories {
        google()  // Google's repository for Flutter and Android dependencies
        mavenCentral()  // Central repository for various libraries
        gradlePluginPortal()  // Gradle's own plugin portal for Gradle-specific plugins
    }
}

// Plugin declarations for the project
plugins {
    // Flutter plugin loader for loading Flutter-specific Gradle tasks
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Android application plugin (but applied only in the app module)
    id("com.android.application") version "8.7.0" apply false

    // FlutterFire Google services plugin (for Firebase integration)
    id("com.google.gms.google-services") version("4.3.15") apply false

    // Kotlin Android plugin for Kotlin-based Android projects
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

// Include the main app module
include(":app")
