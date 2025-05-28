# ============================
# Flutter and Dart rules
# ============================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ============================
# ML Kit + TensorFlow Lite
# ============================
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

-keep class org.tensorflow.lite.nnapi.** { *; }
-dontwarn org.tensorflow.lite.nnapi.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# ============================
# CameraX (if used)
# ============================
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# ============================
# WebView support (if needed)
# ============================
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ============================
# Prevent R8 from removing annotations and metadata
# ============================
-keepattributes *Annotation*, InnerClasses, EnclosingMethod

# ============================
# App-specific rules
# ============================
-keep class com.example.app_face_recognition.** { *; }

# ============================
# Optional: Keep log methods (for debugging)
# ============================
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}

# ============================
# Play Core Library (for deferred components)
# ============================
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**
