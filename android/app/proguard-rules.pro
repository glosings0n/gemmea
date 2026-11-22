# Juamea (com.musantek.juamea) R8 / ProGuard rules for Google Play Store Release Builds

# Keep Flutter embedding & plugin bridge classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Juamea native Kotlin bridge and Nuru-Agri LiteRT Vision Interpreter
-keep class com.musantek.juamea.** { *; }

# Keep Google LiteRT 1.4.2 / LiteRT-LM / MediaPipe / TFLite JNI classes
-keep class com.google.ai.edge.** { *; }
-keep class com.google.mediapipe.** { *; }
-keep class org.tensorflow.** { *; }
-dontwarn com.google.ai.edge.**
-dontwarn com.google.mediapipe.**
-dontwarn org.tensorflow.**

# Preserve JNI native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
