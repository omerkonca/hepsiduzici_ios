# Apple — Push Dahil Yeni Profil Oluştur

Hata:
```
Provisioning profile doesn't include the Push Notifications capability
Provisioning profile doesn't include the aps-environment entitlement
```

**Sebep:** Eski profil, Push açılmadan önce oluşturulmuş. App ID'ye Push eklemek eski profili güncellemez; **yeni profil** gerekir.

---

## Adım 1 — Apple Developer'da eski profili sil

1. https://developer.apple.com/account/resources/profiles/list
2. **Hepsi Duzici App Store** (veya `net.hepsiduzici.hepsiDuzici` App Store profili) bul
3. Profile tıkla → **Delete** → onayla

## Adım 2 — Yeni profil oluştur

1. Aynı sayfada **+** (yeni profil) butonuna bas
2. **Distribution** → **App Store Connect** → Continue
3. **App ID:** `net.hepsiduzici.hepsiDuzici` seç → Continue  
   (Push Notifications bu App ID'de işaretli olmalı)
4. **Certificate:** **Hepsi Duzici Dist** seç → Continue
5. **Profile Name:** `Hepsi Duzici App Store` → **Generate**
6. İndirmek zorunlu değil; Codemagic Apple'dan çekecek

## Adım 3 — Codemagic kasasını güncelle

1. https://codemagic.io → **Teams** → **Code signing identities**
2. **iOS provisioning profiles** sekmesi
3. Eski **Hepsi Duzici App Store** varsa **sil**
4. **Fetch profiles** → yeni oluşturduğun App Store profilini seç
5. Reference name: `Hepsi Duzici App Store` → **Download selected**

> **Hepsi Duzici Dist** sertifikasını silme.

## Adım 4 — Build başlat

1. **Applications** → **hepsiduzici_ios** → **Start new build** → **main**

Yeni profil `aps-environment` içerir → build geçer → TestFlight'ta push çalışır.

> Build script'i Apple'dan profil indirmez (sertifika anahtarı gerekir). Profil **Fetch profiles** ile Codemagic kasasına alınmalıdır.

---

## Kontrol listesi

- [ ] Apple → Identifiers → `net.hepsiduzici.hepsiDuzici` → **Push Notifications** işaretli
- [ ] Apple → Profiles → eski App Store profili **silindi**
- [ ] Apple → Profiles → **yeni** App Store profili oluşturuldu
- [ ] Codemagic → eski profil silindi, **Fetch profiles** ile yeni indirildi
- [ ] Codemagic build yeşil
