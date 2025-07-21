#!/bin/bash

# Wechsle ins Projektverzeichnis
cd "$(dirname "$0")" || exit 1

# Flutter-Ordner erkennen oder abbrechen
if [ ! -d "flutter" ]; then
  echo "⚠️  Flutter-SDK nicht gefunden! Bitte zuerst Setup ausführen."
  exit 1
fi

# Flutter-Bin zu PATH hinzufügen
export PATH="$PATH:$(pwd)/flutter/bin"

# Pub-Abhängigkeiten holen
echo "📦 Hole Abhängigkeiten mit flutter pub get..."
flutter pub get

# Linter-Check (optional)
echo "🧪 Analysiere Codequalität..."
dart analyze || true

# Hinweis
echo "✅ Projekt bereit. Du kannst nun manuell z. B. build ausführen:"
echo "   flutter build web"
