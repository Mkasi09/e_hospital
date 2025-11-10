import java.nio.file.Files
import java.nio.file.StandardCopyOption

// All project repositories
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://developer.huawei.com/repo/") }
    }
}

// Buildscript dependencies
buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://developer.huawei.com/repo/") }
    }
    dependencies {
        // Android Gradle Plugin (required)
        classpath("com.android.tools.build:gradle:8.2.1")

        // Huawei AGConnect Plugin
        classpath("com.huawei.agconnect:agcp:1.5.2.300")
    }
}

// Optional: redirect build output to Flutter build folder
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    project.evaluationDependsOn(":app")

    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Apply only to Android libraries
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            // Fix namespace for flutter_keyboard_visibility plugin
            if (name.contains("flutter_keyboard_visibility")) {
                namespace = "com.jrai.flutter_keyboard_visibility"

                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val text = manifestFile.readText()
                    if (text.contains("package=\"com.jrai.flutter_keyboard_visibility\"")) {
                        val updatedText = text.replace("package=\"com.jrai.flutter_keyboard_visibility\"", "")
                        Files.write(manifestFile.toPath(), updatedText.toByteArray())
                        println("Removed package attribute from $manifestFile")
                    }
                }
            }
        }
    }
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
