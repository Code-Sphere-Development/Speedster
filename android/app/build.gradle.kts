plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "de.codesphere.speedster"
    // permission_handler_android 14 and flutter_secure_storage 11 both require
    // compileSdk 37, which is ahead of the Flutter SDK default (36).
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications plant Mitteilungen ueber die
        // java.time-API. Auf aelteren Android-Fassungen gibt es die nicht;
        // das Desugaring uebersetzt sie zurueck. Ohne diese Zeile bricht
        // schon `assembleRelease` ab -- checkReleaseAarMetadata prueft es.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "de.codesphere.speedster"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Die Fassung, die flutter_local_notifications in seiner Anleitung
    // nennt -- Desugaring und Plugin muessen zueinander passen.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // Liefert den Verbindungsstatus zu Android Auto, ohne dass die App
    // selbst eine Auto-App sein muss.
    implementation("androidx.car.app:app:1.7.0")
}

flutter {
    source = "../.."
}
