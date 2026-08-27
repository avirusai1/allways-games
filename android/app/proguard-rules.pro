# AdMob pulls in WorkManager, which builds its Room database by
# reflection: R8 sees no direct reference to WorkDatabase_Impl and strips
# it, so the app dies on launch in release with
#   "Failed to create an instance of androidx.work.impl.WorkDatabase".
# Keeping the generated Room implementations is what fixes it.
-keep class androidx.room.RoomDatabase { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-keep class androidx.startup.** { *; }
-dontwarn androidx.work.**

# Play Billing, likewise reached reflectively by the plugin.
-keep class com.android.vending.billing.** { *; }
