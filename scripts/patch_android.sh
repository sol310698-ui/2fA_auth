#!/usr/bin/env bash
# Runs after `flutter create --platforms=android .` (re)generates the
# android/ folder. Adds the camera permission mobile_scanner needs and
# wires up release keystore signing from android/key.properties if present.
set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"
GRADLE="android/app/build.gradle.kts"
GRADLE_GROOVY="android/app/build.gradle"

# 1) Camera permission -------------------------------------------------
if [ -f "$MANIFEST" ] && ! grep -q "android.permission.CAMERA" "$MANIFEST"; then
  python3 - "$MANIFEST" <<'PY'
import sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    content = f.read()
perm = '    <uses-permission android:name="android.permission.CAMERA"/>\n'
marker = "<manifest"
idx = content.index(">", content.index(marker)) + 1
content = content[:idx] + "\n" + perm + content[idx:]
with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("Camera permission added")
PY
fi

# 2) Release signing from android/key.properties -----------------------
KEY_PROPS="android/key.properties"
if [ -f "$KEY_PROPS" ]; then
  if [ -f "$GRADLE" ]; then
    TARGET="$GRADLE"
  else
    TARGET="$GRADLE_GROOVY"
  fi
  if [ -f "$TARGET" ] && ! grep -q "key.properties" "$TARGET"; then
    python3 - "$TARGET" <<'PY'
import sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

if path.endswith(".kts"):
    header = '''import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''
    content = header + content
    content = content.replace(
        "android {",
        '''android {
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }''',
        1,
    )
    content = content.replace(
        "buildTypes {",
        '''buildTypes {
        getByName("release") {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }''',
        1,
    )
else:
    header = '''def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

'''
    content = header + content
    content = content.replace(
        "android {",
        '''android {
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }''',
        1,
    )
    content = content.replace(
        "buildTypes {",
        '''buildTypes {
        release {
            signingConfig = keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug
        }''',
        1,
    )

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("Signing config wired into", path)
PY
  fi
fi

echo "patch_android.sh tamamlandı"
