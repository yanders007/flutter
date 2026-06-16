# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# AndroidX
-keep class androidx.** { *; }

# Google Play Services / Firebase
-keep class com.google.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Preserve annotations
-keepattributes *Annotation*
-keepattributes Signature

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enum support
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Avoid warnings from optional libs
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn kotlin.jvm.**
