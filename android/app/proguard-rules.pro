# Flutter proguard rules for release builds
# Keep Flutter and plugin classes used by reflection.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Keep classes that may be referenced by platform channels.
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.platform.** { *; }

# Keep public APIs used by AndroidX.
-keep class androidx.core.** { *; }
-keep class androidx.annotation.** { *; }

# Keep Google Mobile Ads classes.
-keep public class com.google.android.gms.** { *; }
-keep public class com.google.ads.** { *; }

# Keep Play Core deferred components classes used by Flutter.
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep support for JSON / reflection-based libraries.
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Allow resource shrinking.
-dontwarn androidx.**
-dontwarn com.google.android.gms.**
