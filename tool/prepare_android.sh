#!/usr/bin/env bash
# Prépare le dossier android/ (généré par Flutter) avec les réglages de l'app.
# Utilisé par GitHub Actions, et utilisable sur votre ordinateur :  bash tool/prepare_android.sh
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="Fixation Solaire"

if [ ! -d android ]; then
  flutter create --org com.syllapro --project-name fixation_solaire --platforms=android .
fi

# Le test d'exemple généré par Flutter ne correspond pas à cette app.
if [ -f test/widget_test.dart ] && grep -q "MyApp" test/widget_test.dart; then
  rm test/widget_test.dart
fi

MANIFEST=android/app/src/main/AndroidManifest.xml
# Nom affiché sous l'icône.
sed -i.bak "s/android:label=\"[^\"]*\"/android:label=\"$NAME\"/" "$MANIFEST"
# Internet (vérification des mises à jour) aussi en version finale.
if ! grep -q 'android.permission.INTERNET' "$MANIFEST"; then
  sed -i.bak 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$MANIFEST"
fi
# Ouvrir les liens https (téléchargement des mises à jour, WhatsApp).
if ! grep -q 'android:scheme="https"' "$MANIFEST"; then
  if grep -q '<queries>' "$MANIFEST"; then
    sed -i.bak 's#<queries>#<queries>\n        <intent>\n            <action android:name="android.intent.action.VIEW" />\n            <data android:scheme="https" />\n        </intent>#' "$MANIFEST"
  else
    sed -i.bak 's#</manifest>#    <queries>\n        <intent>\n            <action android:name="android.intent.action.VIEW" />\n            <data android:scheme="https" />\n        </intent>\n    </queries>\n</manifest>#' "$MANIFEST"
  fi
fi
rm -f "$MANIFEST.bak"

# Le lint « vital » d'Android plante parfois sur certains plugins :
# il n'est pas utile pour produire l'APK.
for GRADLE in android/build.gradle.kts android/build.gradle; do
  if [ -f "$GRADLE" ] && ! grep -q 'lintVital' "$GRADLE"; then
    cat >> "$GRADLE" <<'GR'

subprojects {
    tasks.matching { it.name.startsWith("lintVital") }.configureEach { enabled = false }
}
GR
  fi
done

# Signature : toujours la même clé (fichier indiqué par FIXATION_KEYSTORE).
# Sans cette variable, Flutter signe avec la clé de debug de l'ordinateur.
APP_GRADLE=android/app/build.gradle.kts
if [ -f "$APP_GRADLE" ] && ! grep -q 'FIXATION_KEYSTORE' "$APP_GRADLE"; then
  python3 - "$APP_GRADLE" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
cfg = """    signingConfigs {
        create("fixe") {
            val ks = System.getenv("FIXATION_KEYSTORE")
            if (ks != null) {
                storeFile = file(ks)
                storePassword = System.getenv("FIXATION_KEYSTORE_PASS") ?: "android"
                keyAlias = System.getenv("FIXATION_KEY_ALIAS") ?: "androiddebugkey"
                keyPassword = System.getenv("FIXATION_KEY_PASS") ?: "android"
            }
        }
    }

    buildTypes {"""
s = s.replace("    buildTypes {", cfg, 1)
s = s.replace('signingConfig = signingConfigs.getByName("debug")',
  'signingConfig = if (System.getenv("FIXATION_KEYSTORE") != null) signingConfigs.getByName("fixe") else signingConfigs.getByName("debug")', 1)
assert 'signingConfigs.getByName("fixe")' in s, "signature non configurée"
open(p, "w").write(s)
PY
fi

echo "android/ prêt."
