plugins {
    id("com.android.application")
    id("kotlin-android")
    // Tambahkan ini untuk Firebase:
    id("com.google.gms.google-services") 
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ekosaputra.kompress_app" // Pastikan namespace ini sesuai
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.ekosaputra.kompress_app" 
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true 
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("com.google.android.play:core:1.10.3")
    implementation("androidx.multidex:multidex:2.0.1")
    // Firebase BoM (Bill of Materials) untuk menjaga versi library tetap sinkron
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
