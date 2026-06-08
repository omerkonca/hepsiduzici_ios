# Codemagic — Provisioning Profile Sil ve Yenile

Apple'da Push açtıktan sonra eski profil geçersiz kalır. Yeni profil build sırasında otomatik oluşur.

## Adım 1 — Eski profili sil

1. https://codemagic.io/apps adresine git
2. **hepsiduzici_ios** uygulamasına tıkla
3. Üst menüden **Teams** → kendi takımına gir  
   (veya sol alttan **Team settings**)
4. **codemagic.yaml settings** → **Code signing identities**
5. **iOS provisioning profiles** sekmesi
6. **Hepsi Duzici App Store** satırını bul
7. Sağdaki **çöp kutusu (Delete)** ikonuna tıkla → onayla

> Sertifikayı (certificate) silme, sadece **provisioning profile** sil.

## Adım 2 — Yeni build başlat

1. **Applications** → **hepsiduzici_ios**
2. **Start new build** → branch **main** → **Start build**

Build script'i (`fetch-signing-files --create`) Apple'dan Push dahil **yeni profil** indirir.

## Adım 3 — Kontrol

Build logunda **"2. Push profili yenile ve bagla"** adımı yeşil olmalı.

Başarılı build → TestFlight → uygulamayı aç → panelde **Kayıtlı cihaz: 1+**

## Sorun çıkarsa

- Apple'da App ID'de **Push Notifications** işaretli mi?
- Codemagic'te **GOOGLE_SERVICE_INFO_PLIST_BASE64** secret var mı?
- **app_store_credentials** grubu (App Store Connect API key) dolu mu?
