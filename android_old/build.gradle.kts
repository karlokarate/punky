buildscript {

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.4.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.21")
        // Optional – falls Firebase etc. gebraucht
        // classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("build") // ✅ relativer Pfad zum Flutter-Root

subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
