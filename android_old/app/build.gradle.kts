plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.punky"  // ⇨ anpassen wenn nötig
    compileSdk = 34
    ndkVersion = "25.1.8937393"  // ⇨ oder leer lassen, wenn du kein NDK nutzt

    defaultConfig {
        applicationId = "com.example.punky"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")  // ⚠️ für reale App bitte ändern!
        }
    }
}

// Wird nur von Flutter benötigt – ohne Auswirkungen bei ./gradlew
flutter {
    source = "../.."
}