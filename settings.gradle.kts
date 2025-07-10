rootProject.name = "Punky"
pluginManagement {
    val flutterSdkPath = run {
        val props = java.util.Properties()
        file("local.properties").inputStream().use { props.load(it) }

        // 👇 Jetzt wird explizit nur \: ersetzt – sonst nichts
        val fixedPath = props.getProperty("flutter.sdk")?.replace("\\:", ":")
            ?: error("flutter.sdk not set or invalid")

        // 👇 URI-Umwandlung sicher & plattformneutral
        File(fixedPath).toURI().toString()
    }

    includeBuild("${flutterSdkPath}packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":android")

