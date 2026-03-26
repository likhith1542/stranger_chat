import java.util.Properties
import java.io.FileInputStream

// 1. Load Local Properties (for dynamic SDK/Version values)
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val flutterRoot = localProperties.getProperty("flutter.sdk")
    ?: throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")


// Avoid hardcoding minSdk - pull from local.properties or default to 21

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Apply the Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
}

// 2. Load Key Properties (for signing)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.stranger_chat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.stranger_chat"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Define the release config dynamically
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: System.getenv("KEY_ALIAS")
            keyPassword = keystoreProperties["keyPassword"] as String? ?: System.getenv("KEY_PASSWORD")
            storeFile = if (keystoreProperties["storeFile"] != null) {
                file(keystoreProperties["storeFile"] as String)
            } else {
                file(System.getenv("KEYSTORE_PATH") ?: "stranger_release.jks")
            }
            storePassword = keystoreProperties["storePassword"] as String? ?: System.getenv("KEYSTORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // The Kotlin plugin automatically adds the stdlib. 
    // Only add this if you specifically need jdk7 and it's missing.
    implementation(platform("org.jetbrains.kotlin:kotlin-bom"))
}