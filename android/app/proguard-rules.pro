# ============================
# Flutter and Dart rules
# ============================
# Keep classes used by Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ============================
# ML Kit + TensorFlow Lite
# ============================

# Keep ML Kit and related classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep TensorFlow Lite base
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Keep TensorFlow Lite GPU delegate
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Keep TensorFlow Lite NNAPI delegate
-keep class org.tensorflow.lite.nnapi.** { *; }
-dontwarn org.tensorflow.lite.nnapi.**

# Keep internal TFLite native functions
-keepclassmembers class * {
    native <methods>;
}

# ============================
# CameraX (if used)
# ============================
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# ============================
# Prevent R8 from removing annotations and metadata
# ============================
-keepattributes *Annotation*, InnerClasses, EnclosingMethod

# ============================
# General rules for common issues
# ============================
-keep class com.example.app_face_recognition.** { *; } 
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Optional: Prevent shrinking for all model files
-keepresources regex .*/.*\.tflite
-keepresources regex .*/.*\.lite

# Optional: Useful to keep logs during debugging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}
