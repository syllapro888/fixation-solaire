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

echo "android/ prêt."
