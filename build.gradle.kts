allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("build") // ✅ relativer Pfad zum Root bleibt im Root!

subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")

    // ✅ Wichtig: Passe den Modulnamen an, wie in settings.gradle.kts referenziert
    evaluationDependsOn(":android")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
