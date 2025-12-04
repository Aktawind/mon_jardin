# Empêcher de renommer les classes du plugin de notification
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Empêcher de renommer Gson (l'outil qui lit les données JSON)
-keep class com.google.gson.** { *; }

# INDISPENSABLE : Garder les informations de "Type" (Génériques)
# C'est ça qui corrige l'erreur "Missing type parameter"
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Par sécurité, on garde les modèles standards d'Android
-keep class androidx.core.app.** { *; }
-keep class android.support.v4.app.** { *; }