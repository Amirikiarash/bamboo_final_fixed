
# ========================
# TensorFlow Lite GPU Support
# ========================
-keep class org.tensorflow.** { *; }
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }

# Prevent warnings
-dontwarn org.tensorflow.**
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.**

# Optional: Keep JNI methods
-keepclasseswithmembernames class * {
    native <methods>;
}
