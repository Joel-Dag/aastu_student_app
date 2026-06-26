plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val MYAPP_UPLOAD_STORE_FILE: String by project
val MYAPP_UPLOAD_KEY_ALIAS: String by project
val MYAPP_UPLOAD_STORE_PASSWORD: String by project
val MYAPP_UPLOAD_KEY_PASSWORD: String by project

android {
    namespace = "com.example.aastu_student_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // ✅ NEW DSL (replaces kotlinOptions)
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    signingConfigs {
        create("release") {
            storeFile = file(MYAPP_UPLOAD_STORE_FILE)
            storePassword = MYAPP_UPLOAD_STORE_PASSWORD
            keyAlias = MYAPP_UPLOAD_KEY_ALIAS
            keyPassword = MYAPP_UPLOAD_KEY_PASSWORD
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}