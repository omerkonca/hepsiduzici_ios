#!/usr/bin/env bash
# Codemagic build öncesi GoogleService-Info.plist oluşturur.
# Codemagic → Environment variables → GOOGLE_SERVICE_INFO_PLIST_BASE64

set -euo pipefail

TARGET="ios/Runner/GoogleService-Info.plist"

if [ -f "$TARGET" ]; then
  echo "GoogleService-Info.plist zaten mevcut."
  exit 0
fi

if [ -z "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" ]; then
  echo "HATA: GOOGLE_SERVICE_INFO_PLIST_BASE64 Codemagic secret olarak tanimlanmali."
  exit 1
fi

echo "$GOOGLE_SERVICE_INFO_PLIST_BASE64" | base64 --decode > "$TARGET"
echo "GoogleService-Info.plist olusturuldu."
