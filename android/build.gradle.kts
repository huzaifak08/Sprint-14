plugins {
  id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// AGP 9 workaround: firebase_storage skips applying the Kotlin plugin on
// AGP 9+ because it expects AGP's built-in Kotlin, but gradle.properties
// turns that off (android.builtInKotlin=false) since other plugins still
// apply KGP themselves. Without this its Kotlin sources aren't compiled and
// the app fails with "cannot find symbol FlutterFirebaseStoragePlugin".
// Remove once every plugin supports built-in Kotlin and that flag is gone.
val builtInKotlinDisabled =
    providers.gradleProperty("android.builtInKotlin").orNull == "false"
subprojects {
    if (builtInKotlinDisabled && name == "firebase_storage") {
        pluginManager.withPlugin("com.android.library") {
            pluginManager.apply("org.jetbrains.kotlin.android")
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>()
                .configureEach {
                    compilerOptions.jvmTarget.set(
                        org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17,
                    )
                }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
