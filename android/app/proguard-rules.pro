# Proguard rules for Parse Server SDK
-keep class com.parse.** { *; }
-dontwarn com.parse.**

# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep models if they use reflection
-keep class com.impactly.app.models.** { *; }
-keep class * extends com.parse.ParseObject { *; }
-keep class * extends com.parse.ParseUser { *; }

# Suppress Play Store Split Install warnings (referenced by Flutter engine)
-dontwarn com.google.android.play.core.**

