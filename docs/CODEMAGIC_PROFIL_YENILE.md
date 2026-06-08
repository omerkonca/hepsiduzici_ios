# Codemagic — Provisioning Profile Sil ve Yenile

Apple'da Push açtıktan sonra eski profil geçersiz kalır. Yeni profil build sırasında otomatik oluşur.

## Nasıl çalışıyor?

| Kaynak | Ne sağlar |
|--------|-----------|
| Codemagic kasası (`Hepsi Duzici Dist`) | Dağıtım sertifikası + keychain |
| Apple (`fetch-signing-files --create`) | Push dahil yeni App Store profili |

Profil sildikten sonra **sertifikayı silme** — sadece provisioning profile silinir.

## Adım 1 — Eski profili sil (isteğe bağlı)

1. https://codemagic.io/apps
2. **Teams** → **Code signing identities**
3. **iOS provisioning profiles** sekmesi
4. **Hepsi Duzici App Store** → çöp kutusu → sil

## Adım 2 — Yeni build başlat

1. **Applications** → **hepsiduzici_ios**
2. **Start new build** → branch **main**

Build logunda şu adımlar yeşil olmalı:

- `0. Push profili indir (Apple)`
- `3. Profilleri projeye bagla`
- `4. Final Build ve IPA Uretimi`

## Adım 3 — TestFlight

Başarılı build → TestFlight → uygulamayı aç → panelde **Kayıtlı cihaz: 1+**

## Sorun çıkarsa

| Hata | Çözüm |
|------|-------|
| No valid code signing certificates | Codemagic'te **Hepsi Duzici Dist** sertifikası var mı kontrol et |
| No matching profiles | Build'i tekrar başlat (`fetch-signing-files --create` yeni profil oluşturur) |
| Push entitlement uyuşmuyor | Apple'da App ID'de **Push Notifications** işaretli mi? |

- **GOOGLE_SERVICE_INFO_PLIST_BASE64** secret ekli mi?
- **app_store_credentials** grubu (App Store Connect API key) dolu mu?
