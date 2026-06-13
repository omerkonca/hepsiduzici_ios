# Google Play — Haberler ve Dergiler Politikası

Red sebebi: iletişim bilgileri kolay bulunamıyor.

## Uygulamada yapılanlar

- **Haberler** sekmesinin üstünde **Bize Ulaşın** şeridi (e-posta)
- Her haber detayında **Bize Ulaşın** butonu + yayıncı/kaynak bilgisi
- **Daha Fazla → Bize Ulaşın** tam iletişim sayfası
- **Daha Fazla → Haber Kaynakları** RSS yayıncı listesi
- Web: https://hdbackend-vo99.onrender.com/iletisim.html
- Haberler 90 günden eski içerik göstermez (backend filtresi)

## Play Console'da yapmanız gerekenler

### 1) Mağaza girişi iletişim bilgileri

1. [Google Play Console](https://play.google.com/console) → uygulamanız
2. **Büyüme** → **Mağaza varlığı** → **Mağaza girişi**
3. **İletişim bilgileri** bölümünde:
   - **E-posta:** `hepsiduzici@gmail.com`
   - **Web sitesi:** `https://hdbackend-vo99.onrender.com/iletisim.html`

### 2) Haberler beyanı

1. **Politika** → **Uygulama içeriği** → **Haber uygulamaları**
2. Beyanı güncelleyin
3. **İletişim bilgileri URL'si:** `https://hdbackend-vo99.onrender.com/iletisim.html`

### 3) Kategori

Uygulama haber toplayıcı ise **Haberler ve Dergiler** doğru kategoridir. Beyan formu ile uyumlu olmalı.

### 4) Backend deploy

`iletisim.html` değişiklikleri için Render'da backend'i yeniden deploy edin.

### 5) Yeni sürüm

1. Yeni APK/AAB yükleyin
2. **Politika durumu** → reddi **Çözüldü olarak işaretle** / yeniden gönderin
