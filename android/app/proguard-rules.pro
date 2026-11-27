# R8 rules for release builds (minify + shrinkResources are on).

# flutter_local_notifications stores scheduled notifications with Gson;
# without these, scheduled reminders crash or vanish in release builds.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Flutter deferred components reference Play Core, which this app doesn't use.
-dontwarn com.google.android.play.core.**

# ML Kit text recognition: the plugin references every script's options,
# but only the Latin model is bundled (and used) for backup-code scanning.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep readable stack traces in Play Console crash reports
# (mapping.txt is uploaded by CI to de-obfuscate them).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
