# Push Bildirim — Adım Adım Kurulum (Türkçe)

Bu rehber, **“Günaydın”**, **“Yeni özellik eklendi”** gibi mesajları uygulama yüklü tüm kullanıcılara göndermeniz içindir.

---

## Ben ne yaptım? (Kod tarafı — hazır)

- Uygulama FCM token’ını Supabase’e kaydeder
- Yayıncı panelinde **Toplu Bildirim Gönder** ekranı var
- Supabase’de `device_tokens` tablosu ve `send-push` fonksiyonu kurulu
- Kullanıcı ayarlardan duyuruları kapatabilir

**Sizin yapmanız gereken:** Firebase + Apple ayarları (15–30 dk, tek seferlik).

---

## ADIM 1 — Firebase projesi oluştur

1. Tarayıcıda aç: https://console.firebase.google.com  
2. Google hesabınızla giriş (AdMob ile aynı hesap olabilir)  
3. **Proje ekle** → İsim: `Hepsi Duzici` → Oluştur  
4. Google Analytics isteğe bağlı (kapatabilirsiniz)

> AdMob kullanıyorsanız: Firebase Console → Proje ayarları → **AdMob’u bağla** (aynı reklam hesabı).

---

## ADIM 2 — Android uygulamasını Firebase’e ekle

1. Firebase projesinde **Android simgesi**  
2. **Android paket adı:** `net.hepsiduzici.hepsi_duzici`  
3. Uygulama takma adı: `Hepsi Düziçi`  
4. **Uygulamayı kaydet**  
5. **google-services.json** dosyasını indir  
6. Dosyayı şuraya kopyala:

```
d:\hepsiduzici\android\app\google-services.json
```

7. Firebase’de “Sonraki” deyip bitirin (SDK adımlarını atlayabilirsiniz — kod hazır)

---

## ADIM 3 — iOS uygulamasını Firebase’e ekle

1. Firebase’de **iOS simgesi**  
2. **Apple bundle ID:** `net.hepsiduzici.hepsiDuzici`  
3. **GoogleService-Info.plist** indir  
4. Dosyayı kopyala:

```
d:\hepsiduzici\ios\Runner\GoogleService-Info.plist
```

5. Xcode ile açmak isterseniz: `ios/Runner.xcworkspace` → Runner → plist’i sürükle

---

## ADIM 4 — Apple Push (sadece iOS için)

1. https://developer.apple.com → **Certificates, Identifiers & Profiles**  
2. **Keys** → **+** → **Apple Push Notifications service (APNs)** işaretle  
3. Key indir (`.p8` dosyası — bir kez indirilir, saklayın)  
4. Firebase → Proje ayarları → **Cloud Messaging** sekmesi  
5. **Apple app configuration** → APNs Authentication Key yükle:
   - Key ID
   - Team ID (`7RJ993N2DP` — Codemagic’teki ile aynı)
   - `.p8` dosyası

6. Xcode’da (isteğe bağlı ama önerilir):
   - `ios/Runner.xcworkspace` aç
   - Runner target → **Signing & Capabilities**
   - **+ Capability** → **Push Notifications**
   - **Background Modes** → **Remote notifications** işaretle

---

## ADIM 5 — Firebase Service Account (gönderim için)

Push **göndermek** için sunucunun Firebase’e yetkisi olmalı:

1. Firebase → Dişli → **Proje ayarları**  
2. **Hizmet hesapları** sekmesi  
3. **Yeni özel anahtar oluştur** → JSON indir  
4. Bu JSON dosyasını **tek satır** yapın (Not Defteri’nde açıp satır sonlarını silmeyin — Supabase’e yapıştırırken tüm içerik tek parça olmalı)

---

## ADIM 6 — Supabase secret’ları (kritik)

1. Aç: https://supabase.com/dashboard/project/duehxbdlpwvbpqfjyjai  
2. **Project Settings** → **Edge Functions** → **Secrets**  
3. Şu iki secret’ı ekle:

| İsim | Değer |
|------|--------|
| `PUSH_ADMIN_TOKEN` | Yayıncı paneline girdiğiniz parola (Render’daki `ADMIN_TOKEN` ile **aynı** olmalı) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | ADIM 5’te indirdiğiniz JSON’un **tamamı** (tek satır) |

4. Kaydet. 1–2 dakika bekleyin.

> Yayıncı paneli parolanızı bilmiyorsanız: Render dashboard → `hdbackend` → Environment → `ADMIN_TOKEN` değerine bakın.

---

## ADIM 7 — Uygulamayı derle ve yayınla

### Android
```powershell
cd d:\hepsiduzici
flutter pub get
flutter build appbundle --release
```

### iOS (Codemagic)
- GitHub’a push edin
- Codemagic build alın
- `google-services.json` ve `GoogleService-Info.plist` repoda veya Codemagic **environment files** içinde olmalı

### Yerel test
```powershell
flutter run
```
- Bildirim izni verin  
- **Daha Fazla → Bildirim tercihleri → Yayıncı duyuruları** açık olsun  
- Uygulamayı bir kez açıp kapatın (token kaydı için)

---

## ADIM 8 — İlk bildirimi gönder

1. Uygulamada **Daha Fazla → Yayıncı Paneli**  
2. Parolanızı girin  
3. **Toplu Bildirim Gönder** bölümüne inin  
4. “Günaydın” şablonuna dokunun veya kendi metninizi yazın  
5. **Tüm kullanıcılara gönder**

Başarılı olursa: `Gönderildi: X başarılı` mesajı görürsünüz.

---

## Sorun giderme

| Sorun | Çözüm |
|--------|--------|
| Kayıtlı cihaz: 0 | Firebase dosyaları eksik veya uygulama hiç açılmadı |
| Yetkisiz | `PUSH_ADMIN_TOKEN` yanlış |
| FCM yapılandırılmamış | `FIREBASE_SERVICE_ACCOUNT_JSON` secret eksik/hatalı |
| iOS’ta bildirim yok | APNs key Firebase’e yüklenmemiş |
| Android’de yok | `google-services.json` yanlış klasörde |

---

## Kontrol listesi

- [ ] `android/app/google-services.json` var  
- [ ] `ios/Runner/GoogleService-Info.plist` var  
- [ ] APNs key Firebase’e yüklendi (iOS)  
- [ ] Supabase’de `PUSH_ADMIN_TOKEN` ayarlandı  
- [ ] Supabase’de `FIREBASE_SERVICE_ACCOUNT_JSON` ayarlandı  
- [ ] Yeni sürüm mağazaya / TestFlight’a yüklendi  
- [ ] En az 1 cihazda uygulama açıldı (token kaydı)
