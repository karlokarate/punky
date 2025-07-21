rootProject.name = "Punky"

pluginManagement {
    val flutterSdkPath = run {
        val props = java.util.Properties()
        file("local.properties").inputStream().use { props.load(it) }

        val fixedPath = props.getProperty("flutter.sdk")?.replace("\\:", ":")
            ?: error("flutter.sdk not set or invalid")

        File(fixedPath).toURI().toString()
    }

    includeBuild("${flutterSdkPath}packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

include(":app")