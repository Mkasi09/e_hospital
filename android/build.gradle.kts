import java.nio.file.Files
import java.nio.file.StandardCopyOption


allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
subprojects {
    // Apply only to Android libraries
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            // Add namespace for flutter_keyboard_visibility
            if (name.contains("flutter_keyboard_visibility")) {
                namespace = "com.jrai.flutter_keyboard_visibility"

                // Path to the plugin's manifest
                val manifestFile = file("src/main/AndroidManifest.xml")

                if (manifestFile.exists()) {
                    // Remove package="..." line dynamically
                    val text = manifestFile.readText()
                    if (text.contains("package=\"com.jrai.flutter_keyboard_visibility\"")) {
                        val updatedText = text.replace("package=\"com.jrai.flutter_keyboard_visibility\"", "")
                        Files.write(manifestFile.toPath(), updatedText.toByteArray())
                        println("✅ Removed package attribute from $manifestFile")
                    }
                }
            }
        }
    }
}