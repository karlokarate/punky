pluginManagement {
    val flutterSdkPath = run {
        val props = java.util.Properties()
        file("local.properties").inputStream().use { props.load(it) }
        val raw = props.getProperty("flutter.sdk") ?: error("flutter.sdk not set in local.properties")
        File(raw).canonicalFile.toURI().toString().removePrefix("file:/").replace("%20", " ")
    }

    includeBuild(File(flutterSdkPath, "packages/flutter_tools/gradle"))

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application")          version "8.7.3" apply false
    id("org.jetbrains.kotlin.android")     version "2.1.0" apply false
}

include(":android")
