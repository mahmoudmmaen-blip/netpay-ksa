plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

android {
    namespace = "com.example.netgulf"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.netgulf"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── Release signing (Play Store) ─────────────────────────────────────────
    // IMPORTANT: `android/key.properties` + keystore file must NOT be committed.
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    val hasKeystoreFile = keystorePropertiesFile.exists()

    if (hasKeystoreFile) {
        keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    }

    fun prop(name: String): String =
        (keystoreProperties.getProperty(name) ?: "").trim()

    val hasReleaseSigning =
        hasKeystoreFile &&
            prop("storeFile").isNotEmpty() &&
            prop("storePassword").isNotEmpty() &&
            prop("keyAlias").isNotEmpty() &&
            prop("keyPassword").isNotEmpty() &&
            file(prop("storeFile")).exists()

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(prop("storeFile"))
                storePassword = prop("storePassword")
                keyAlias = prop("keyAlias")
                keyPassword = prop("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Use release keystore when available; fallback to debug to keep local builds working.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
