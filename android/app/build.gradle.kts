plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.punky.diabetes"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.punky.diabetes"
        minSdk = 24
        targetSdk = 34
        versionCode = 5
        versionName = "1.4.2"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // WorkManager für BackgroundInitWorker (BootReceiver)
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")


    // Weitere native Android-Module, falls benötigt
    // implementation("androidx.core:core-ktx:1.12.0")
    // implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.2")
}
