# Toplu Push Bildirim Kurulumu

## 1. Firebase projesi

1. [Firebase Console](https://console.firebase.google.com) → Yeni proje (veya mevcut AdMob projesi)
2. Android uygulaması ekle: `net.hepsiduzici.hepsi_duzici`
3. iOS uygulaması ekle: `net.hepsiduzici.hepsiDuzici`
4. `google-services.json` → `android/app/google-services.json`
5. `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist` (Xcode ile ekleyin)
6. Proje kökünde: `dart pub global activate flutterfire_cli && flutterfire configure`

## 2. Supabase Edge Function secrets

Supabase Dashboard → Project Settings → Edge Functions → Secrets:

| Secret | Değer |
|--------|-------|
| `PUSH_ADMIN_TOKEN` | Yayıncı paneli parolanız (admin token ile aynı) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase service account JSON (tek satır) |

`send-push` fonksiyonu deploy edildi. Yayıncı paneli önce bunu kullanır.

## 3. Render backend (isteğe bağlı yedek)

Render backend ortam değişkenleri:

`https://hdbackend-vo99.onrender.com` → Environment:

| Değişken | Açıklama |
|----------|----------|
| `ADMIN_TOKEN` | Yayıncı paneli parolası (zaten var) |
| `SUPABASE_URL` | `https://duehxbdlpwvbpqfjyjai.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase → Project settings → Service accounts → Generate key (tüm JSON tek satır) |

`backend/src/routes/push.js` dosyasını mevcut sunucunuza mount edin:

```js
import pushRouter from './routes/push.js';
app.use('/api/push', pushRouter);
```

## 4. Apple (iOS push)

1. Apple Developer → Keys → APNs key oluştur
2. Firebase → Project settings → Cloud Messaging → iOS → APNs key yükle

## 5. Kullanım

1. Uygulama açılınca FCM token Supabase `device_tokens` tablosuna kaydolur
2. **Daha Fazla → Yayıncı Paneli** → Toplu Bildirim Gönder
3. Hazır şablonlar: Günaydın, Yeni özellik, Duyuru

Kullanıcılar **Bildirim tercihleri → Yayıncı duyuruları** ile kapatabilir.
