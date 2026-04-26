# Flutter Proguard Rules

# Add rules for androidx.window as requested by R8
-keep class androidx.window.extensions.** { *; }
-dontwarn androidx.window.extensions.**
-keep class androidx.window.sidecar.** { *; }
-dontwarn androidx.window.sidecar.**

# Google Play Core rules to fix R8 missing class errors
-dontwarn com.google.android.play.core.**

# Common Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
