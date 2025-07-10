plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Der Flutter‑Gradle‑Plugin MUSS nach Android‑ & Kotlin‑Plugins kommen
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace  = "com.example.untitled1"          // ⇨ bei Bedarf anpassen
    compileSdk = 34
    ndkVersion = flutter.ndkVersion               // aus Flutter‑Tools

    defaultConfig {
        applicationId = "com.example.untitled1"   // ⇨ bei Bedarf anpassen
        minSdk       = flutter.minSdkVersion
        targetSdk    = 34
        versionCode  = flutter.versionCode
        versionName  = flutter.versionName
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
            // TODO: eigenes Keystore‑Config hinterlegen
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
