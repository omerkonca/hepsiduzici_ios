# iOS Build Hatası: Push Notifications / aps-environment

Hata:
```
Provisioning profile doesn't include the Push Notifications capability
Provisioning profile doesn't include the aps-environment entitlement
```

## 1. Apple Developer (2 dk — zorunlu)

1. https://developer.apple.com/account → **Identifiers**
2. **net.hepsiduzici.hepsiDuzici** seç
3. **Push Notifications** kutusunu işaretle → **Save**

## 2. Codemagic

Build script profili otomatik yeniler (`fetch-signing-files --create`).

Eski profil takılırsa:
- Codemagic → **Code signing identities** → **Provisioning profiles**
- **Hepsi Duzici App Store** profilini sil
- Yeni build başlat

## 3. Tekrar build

Push capability + yeni profil = build geçer, TestFlight'ta push çalışır.
