plugins {
    id("com.android.application")
    // BẮT ĐẦU: Cấu hình FlutterFire
    id("com.google.gms.google-services")
    // KẾT THÚC: Cấu hình FlutterFire
    id("kotlin-android")
    // Plugin Flutter Gradle phải được áp dụng sau plugin Android và Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tourn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }


    defaultConfig {
        // TODO: Chỉ định Application ID riêng cho bạn (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.tourn"
        // Bạn có thể cập nhật các giá trị sau cho phù hợp nhu cầu ứng dụng.
        // Để biết thêm thông tin, xem: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Thêm cấu hình ký riêng cho bản phát hành.
            // Hiện đang ký bằng khóa debug, để `flutter run --release` hoạt động.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}
