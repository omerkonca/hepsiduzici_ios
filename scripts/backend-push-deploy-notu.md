# Backend'den Push Gönderme

## Panel adresi
https://hdbackend-vo99.onrender.com/admin

1. Admin şifrenizle giriş yapın
2. Sol menü → **Sistem** → **Toplu Bildirim**
3. Şablon seçin veya metin yazın → **Tüm kullanıcılara gönder**

## Render'da bir kez yapılacak
Render Dashboard → `hdbackend` → **Environment** → şu değişkeni ekleyin:

- **Key:** `FIREBASE_SERVICE_ACCOUNT_JSON`
- **Value:** `secrets/firebase-service-account.json` dosyasının tamamı (tek satır JSON)

Kaydedince servis yeniden başlar. Panelde **FCM hazır** yazısını görmelisiniz.

## Deploy
Backend değişikliklerini Render'a göndermek için `backend` klasöründeki repoyu push edin.
