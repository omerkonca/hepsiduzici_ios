# Hepsi Düziçi – Mobil Uygulama

Düziçi ilçesi için tek giriş noktası: nöbetçi eczane, hava durumu, namaz vakitleri ve haberler.

## Çalıştırma

```bash
flutter pub get
flutter run
```

- **Android / iOS:** Cihaz veya emülatör seçerek `flutter run`
- **Web:** `flutter run -d chrome`
- **Windows:** Visual Studio ile C++ desktop geliştirme araçları gerekir

## Yapı

- **lib/app** – Ana uygulama, navigasyon, Riverpod provider’lar
- **lib/core** – Tema (logoya uygun renkler), ortak widget’lar
- **lib/data** – Modeller (Pharmacy, WeatherInfo, PrayerTimes, NewsItem) ve servisler
- **lib/features** – Ekranlar: home, pharmacy, news, prayer

## Veri kaynakları

| Özellik    | Kaynak        | Not |
|-----------|---------------|-----|
| Hava      | Open-Meteo    | API key yok, Düziçi koordinatları kullanılıyor |
| Namaz     | Aladhan API   | Diyanet metodu (13), Duzici şehri |
| Eczane    | backend scraping | Kaynak: `https://www.eczaneler.gen.tr/nobetci-osmaniye-duzici` |
| Hizmetler/Keşfet içerikleri | Local JSON + Remote fallback | `CityContentService` önce remote dener, hata olursa local kullanır |
| Haberler  | Mock (memory) | İleride Supabase/Firestore veya kendi API’n eklenebilir |

### Nobetci eczane otomatik veri

- Backend endpoint: `GET /api/pharmacies/duty`
- Kaynak URL: `https://www.eczaneler.gen.tr/nobetci-osmaniye-duzici`
- Backend, veriyi cache'leyip periyodik yeniler.
- Flutter tarafinda `lib/core/config/app_config.dart` dosyasinda `pharmacyUrl` alanini doldur:

```dart
static const String pharmacyUrl = 'http://10.0.2.2:5050/api/pharmacies/duty';
```

## Logo

Logonu `assets/images/logo.png` olarak koy. Dosya yoksa ana sayfada “HD” placeholder görünür.

## City Content (JSON Şeması)

Hizmetler ve Keşfet ekranları tek bir içerik dosyasından beslenir:

- Local dosya: `assets/data/city_content.json`
- Model: `lib/data/models/city_content.dart`
- Service: `lib/data/services/city_content_service.dart`
- Provider: `cityContentProvider` (`lib/app/providers.dart`)

### Remote + Fallback mantığı

`lib/core/config/app_config.dart` içinde:

```dart
static const String cityContentUrl = '';
```

- URL boşsa: direkt local JSON (`assets/data/city_content.json`)
- URL doluysa: önce remote JSON
- Remote başarısızsa: otomatik local JSON fallback

### Local API sunucusu (senin için hazır)

Bu projede Flutter’dan ayrı küçük bir Node.js API sunucusu da var:

- Kod: `backend/src/server.js`
- Endpoint: `GET /api/city-content`
- Nobetci eczane endpoint: `GET /api/pharmacies/duty`
- Admin endpoint: `POST /api/city-content`
- Admin token kontrol: `GET /api/admin/check`
- Yedek listeleme: `GET /api/backups`
- Son yedekten geri alma: `POST /api/city-content/restore-last`
- Sağlık kontrolü: `GET /health`

Çalıştırmak için:

```bash
cd backend
npm install
npm start
```

İstersen admin token ile başlat:

```bash
# PowerShell
$env:ADMIN_TOKEN="cok-gizli-token"
npm start
```

Sonra tarayıcıda:

- `http://localhost:5050/health`
- `http://localhost:5050/api/city-content`
- `http://localhost:5050/admin` (gorsel admin panel)

### City content güncelleme (POST)

`POST /api/city-content` endpoint’i, `assets/data/city_content.json` dosyasını günceller.

Gerekli header:

- `x-admin-token: <ADMIN_TOKEN>`

PowerShell örneği:

```powershell
$token = "cok-gizli-token"
$json = Get-Content "..\assets\data\city_content.json" -Raw
Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:5050/api/city-content" `
  -Headers @{ "x-admin-token" = $token } `
  -ContentType "application/json" `
  -Body $json
```

### Gorsel admin panel kullanimi

1. `http://localhost:5050/admin` sayfasini ac.
2. `Admin token` alanina `ADMIN_TOKEN` degerini gir.
3. `Kilidi Ac` ile token dogrula.
4. `JSON Yukle` ile guncel icerigi cek.
5. Istersen `Form Tabanli Duzenleme` alaninda kart/kategori/sponsor ekle-sil yap, `Duzenle` ile acilan modalda satiri guncelle ve `↑/↓` ile sirayi degistir.
6. `Form -> JSON` ile form verisini editor alanina yaz.
7. Duzenle ve `Kaydet (POST)` ile aninda dosyaya yaz.
8. `Yedekleri Listele` ile olusan yedekleri gor.
9. Hata olursa `Son Yedege Don` ile geri al.

> Not: Her kaydetmede eski dosya otomatik olarak `backend/backups/` klasorune yedeklenir.

Flutter uygulamasının bu API’yi kullanması için:

- `lib/core/config/app_config.dart` içindeki `cityContentUrl` alanına
  `http://localhost:5050/api/city-content` yaz.
- Ayni dosyada `pharmacyUrl` alanina da:
  `http://localhost:5050/api/pharmacies/duty` yaz.

> Not: Android emülatörde `localhost` yerine genelde `10.0.2.2` gerekir.
> Örn: `http://10.0.2.2:5050/api/city-content`

### Beklenen temel JSON yapısı

```json
{
  "services": {
    "tiles": [
      {
        "id": "pharmacy",
        "icon": "local_pharmacy",
        "title": "Nobetci Eczane",
        "subtitle": "Bugunku nobetci eczane listesi, telefon ve rota",
        "target": "pharmacy"
      }
    ],
    "healthFacilities": [
      {
        "name": "Duzici Devlet Hastanesi",
        "type": "Devlet Hastanesi",
        "address": "Irfanli Mah. Hastane Cad. No: 12",
        "phone": "0328 876 10 10"
      }
    ],
    "emergencyContacts": [
      {
        "name": "Acil Saglik",
        "number": "112",
        "icon": "medical_services"
      }
    ],
    "municipalityUnits": [
      {
        "title": "Beyaz Masa",
        "subtitle": "Talep ve sikayet yonetimi",
        "phone": "0328 876 00 01"
      }
    ]
  },
  "explore": {
    "categories": [
      {
        "id": "places",
        "icon": "park",
        "title": "Gezilecek Yerler",
        "subtitle": "Doga, tarih ve fotograf noktalari",
        "badge": "12 Nokta",
        "places": [
          {
            "name": "Karacaoren Selalesi",
            "shortDescription": "Doga yuruyusu ve fotograf icin populer nokta.",
            "detail": "Uzun aciklama metni...",
            "address": "Duzici kirsali, Karacaoren yolu",
            "tag": "DOGA"
          }
        ]
      }
    ],
    "suggestions": [
      {
        "title": "Hafta Sonu Rotasi",
        "subtitle": "Kaplicadan seyir tepesine 1 gunluk gezi plani.",
        "icon": "route",
        "places": []
      }
    ]
  },
  "media": {
    "sponsors": [
      {
        "id": "yerel-firma-1",
        "title": "Yerel Firma Kampanya",
        "badge": "SPONSOR",
        "imageUrl": "https://.../gorsel.jpg",
        "targetUrl": "https://.../kampanya",
        "isActive": true
      }
    ]
  }
}
```

### Icon alanları

JSON içindeki `icon` stringleri `lib/core/utils/icon_mapper.dart` ile Flutter iconlarına çevrilir.
Yeni icon eklemek için bu dosyadaki `IconMapper.fromName()` içine yeni case ekle.

## Sonraki adımlar

- City content için bir CMS endpoint’i üret (`cityContentUrl` alanına bağla)
- Haberleri Supabase/Firestore veya kendi API’nden çek
- Istersen scraping yerine resmi bir eczane API'sine gec
