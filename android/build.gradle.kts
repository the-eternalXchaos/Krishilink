// Root project build.gradle.kts file
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Add the classpath for the Firebase Google Services plugin
        classpath("com.google.gms:google-services:4.3.15") 
    }    
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Force all modules to use consistent Java configuration
    tasks.withType<JavaCompile> {
        sourceCompatibility = "17"
        targetCompatibility = "17"
        // Remove --add-opens flags that cause issues with Java 8 plugins
    }
    
    // Configure Kotlin to use Java 17
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        kotlinOptions {
            jvmTarget = "17"
            allWarningsAsErrors = false
        }
    }
}

// Custom build directory configuration
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app") // Make sure the subprojects depend on :app
}

// Clean task to delete build directories
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

