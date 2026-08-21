plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.firebase-perf")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.com.dinosoft.vestipro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.dinosoft.vestipro"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appName"] = "VestiPro Dev"
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            manifestPlaceholders["appName"] = "VestiPro Staging"
        }
        create("prod") {
            dimension = "environment"
            manifestPlaceholders["appName"] = "VestiPro"
        }
    }

    buildTypes {
        release {
            // Release signing will be configured in the release pipeline task.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// ADR-0002: só existe projeto Firebase real para "prod"; dev/staging usam o Emulator Suite e não
// têm client correspondente em google-services.json. Sem este filtro, o Gradle plugin do Google
// Services falha o build de dev/staging por não achar `br.com.dinosoft.vestipro.dev`/`.staging`.
tasks.whenTaskAdded {
    if (name.startsWith("process") && name.endsWith("GoogleServices") && !name.contains("Prod")) {
        enabled = false
    }
}
