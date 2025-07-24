// Root project build.gradle.kts file

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Add the classpath for the Firebase Google Services plugin
        classpath("com.google.gms:google-services:4.3.15") 
        
        
        
        
        
        
    }    
        
        
        
        
        
        // Firebase plugin
    











}

allprojects {
    repositories {
        google()
        mavenCentral()
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

