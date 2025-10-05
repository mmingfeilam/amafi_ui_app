#!/bin/bash

# Set your old and new package directory names
OLD_DIR="android/app/src/main/kotlin/com/example/amafi_ui_app"
NEW_DIR="android/app/src/main/kotlin/com/example/amafi_ui_app"

# 1. Rename the directory
if [ -d "$OLD_DIR" ]; then
  echo "🔁 Renaming Kotlin directory..."
  mv "$OLD_DIR" "$NEW_DIR"
else
  echo "❌ Directory $OLD_DIR does not exist. Skipping move."
fi

# 2. Update package name in MainActivity.kt
MAIN_KT="$NEW_DIR/MainActivity.kt"
if [ -f "$MAIN_KT" ]; then
  echo "✏️ Updating package name in MainActivity.kt..."
  sed -i '' 's/package com\.example\.amafi_ui_app/package com.example.amafi_ui_app/' "$MAIN_KT"
else
  echo "❌ MainActivity.kt not found at $MAIN_KT"
fi

# 3. Update AndroidManifest.xml
MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST_FILE" ]; then
  echo "✏️ Updating package name in AndroidManifest.xml..."
  sed -i '' 's/package="com\.example\.amafi_ui_app"/package="com.example.amafi_ui_app"/' "$MANIFEST_FILE"
else
  echo "❌ AndroidManifest.xml not found"
fi

# 4. Update applicationId in build.gradle.kts
BUILD_FILE="android/app/build.gradle.kts"
if [ -f "$BUILD_FILE" ]; then
  echo "✏️ Updating applicationId in build.gradle.kts..."
  sed -i '' 's/applicationId = "com\.example\.amafi_ui_app"/applicationId = "com.example.amafi_ui_app"/' "$BUILD_FILE"
else
  echo "❌ build.gradle.kts not found"
fi

# 5. Clean and rebuild
echo "🧹 Running flutter clean and pub get..."
flutter clean
flutter pub get

echo "✅ Done. You can now run: flutter run"
