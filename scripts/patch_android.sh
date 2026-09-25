#!/usr/bin/env bash
# Runs after `flutter create --platforms=android .` (re)generates the
# android/ folder. Does three things to the fresh scaffold:
#   1. Adds the camera permission mobile_scanner needs.
#   2. Wires up release keystore signing from android/key.properties
#      if that file exists (falls back to debug signing otherwise).
#   3. Disables R8 minification for the release build type. R8's full
#      mode strips the ML Kit classes mobile_scanner loads via
#      reflection, which crashes the camera at runtime in release
#      builds only (genericError / "getClass() on a null object
#      reference"). Since this is a small personal app, shrinking
#      isn't worth that fragility.
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

# 2) Signing (conditional at build time) + minify off (always) --------
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

is_kts = path.endswith(".kts")

def find_matching_brace(text, open_brace_idx):
    """Given the index of a '{', return the index of its matching '}'."""
    depth = 0
    i = open_brace_idx
    while i < len(text):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("Unbalanced braces")

def replace_release_block(text, new_block):
    """Find the buildTypes { ... release { ... } ... } sub-block for
    'release' specifically and replace just that inner block, leaving
    the rest of buildTypes (e.g. debug {}) untouched."""
    bt_idx = text.index("buildTypes {")
    # locate whichever header form is present after buildTypes {
    candidates = []
    for header in ('release {', 'getByName("release") {'):
        pos = text.find(header, bt_idx)
        if pos != -1:
            candidates.append((pos, header))
    if not candidates:
        # No release block found (unexpected) — just insert after buildTypes {
        idx = bt_idx + len("buildTypes {")
        return text[:idx] + "\n" + new_block + text[idx:]
    candidates.sort()
    start, header = candidates[0]
    brace_idx = text.index('{', start)
    end = find_matching_brace(text, brace_idx)
    return text[:start] + new_block.strip() + text[end + 1:]

if is_kts:
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
    new_release_block = '''getByName("release") {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }'''
    content = replace_release_block(content, new_release_block)
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
    new_release_block = '''release {
            signingConfig = keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug
            minifyEnabled false
            shrinkResources false
        }'''
    content = replace_release_block(content, new_release_block)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("Signing + minify-off wired into", path)
PY
fi

echo "patch_android.sh tamamlandı"
