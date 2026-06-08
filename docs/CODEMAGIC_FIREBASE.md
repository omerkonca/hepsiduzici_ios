# Codemagic — Firebase plist (gizli)

`GoogleService-Info.plist` repoda **tutulmaz** (API key sızıntısı önlenir).

## Kurulum (bir kez)

1. Codemagic → **hepsiduzici_ios** uygulaması
2. **Environment variables** (grup gerekmez)
3. Yeni değişken:
   - **Name:** `GOOGLE_SERVICE_INFO_PLIST_BASE64`
   - **Secure:** ✅
   - **Value:** plist dosyasının base64 hali

PowerShell ile base64 üret:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("d:\hepsiduzici\ios\Runner\GoogleService-Info.plist")) | Set-Clipboard
```

4. Kaydet → build başlat

Yerel geliştirmede `ios/Runner/GoogleService-Info.plist` dosyası diskte kalır (gitignore).
