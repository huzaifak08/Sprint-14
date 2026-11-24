import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.digitalmunshi.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent Play Store id: never change it, or updates stop reaching
        // existing users (the visible name is set in AndroidManifest.xml).
        applicationId = "com.digitalmunshi.app"
        // versionCode/versionName come from pubspec.yaml or --build-number /
        // --build-name (CI derives the code from the run number).
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    // Release signing (upload key). Sources, in order:
    //  1. android/key.properties (local machine; git-ignored), e.g.
    //       storeFile=upload-keystore.jks   (path relative to android/app)
    //       storePassword=...  keyAlias=upload  keyPassword=...
    //  2. Environment variables + android/app/upload-keystore.jks (GitHub
    //     Actions decodes the keystore from the KEYSTORE_BASE64 secret).
    // With neither, release builds fall back to the debug key so
    // `flutter run --release` works locally; Play rejects such uploads, so a
    // misconfigured CI can't publish a wrongly signed build.
    val ciKeystore = file("upload-keystore.jks")
    val hasLocalSigning = keystorePropertiesFile.exists()
    val hasCiSigning = ciKeystore.exists() && !System.getenv("KEY_ALIAS").isNullOrBlank()

    signingConfigs {
        create("release") {
            if (hasLocalSigning) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            } else if (hasCiSigning) {
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
                storeFile = ciKeystore
                storePassword = System.getenv("KEYSTORE_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            signingConfig =
                if (hasLocalSigning || hasCiSigning) {
                    signingConfigs.getByName("release")
                } else {
                    logger.warn("No upload key found: signing release with the DEBUG key.")
                    signingConfigs.getByName("debug")
                }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.activity:activity-ktx:1.9.0")
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))
}