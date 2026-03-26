# android/app/proguard-rules.pro

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Nearby Connections
-keep class com.google.android.gms.nearby.** { *; }

# Hive
-keep class com.hivedb.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Dart / Flutter engine
-keep class io.flutter.embedding.** { *; }

# Don't warn about missing classes in release
-dontwarn io.flutter.**
-dontwarn com.google.**
