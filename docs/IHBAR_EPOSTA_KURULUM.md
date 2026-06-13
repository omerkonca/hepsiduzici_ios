# İhbar / Öneri — E-posta Bildirimi

Yeni ihbar gelince **hepsiduzici@gmail.com** adresine mail düşer.

## Tek önerilen yol: Gmail + Google Apps Script

- **Ücretsiz**
- **Yeni siteye kayıt yok** (zaten Gmail kullanıyorsun)
- **Render ücretsiz planda çalışır** (HTTPS, port 443)
- Mail **kendi Gmail hesabından** gider → gelen kutusuna düşer

Resend / Brevo / SMTP artık gerekmez. İstersen Render'dan `SMTP_*`, `RESEND_*`, `BREVO_*` değişkenlerini silebilirsin.

---

## Kurulum (5 dakika)

### 1. Google Apps Script

1. https://script.google.com → **Yeni proje**
2. `backend/scripts/gmail-apps-script.gs` dosyasındaki kodu yapıştır
3. `WEBHOOK_SECRET` satırına rastgele bir şifre yaz (ör. `hd2026GizliAnahtar42`)
4. **Dağıt** → **Yeni dağıtım** → Tür: **Web uygulaması**
   - Çalıştır: **Ben**
   - Erişim: **Herkes**
5. **Dağıt** → çıkan **Web uygulaması URL**'sini kopyala

### 2. Render → hdbackend → Environment

| Key | Value |
|-----|--------|
| `GMAIL_WEBHOOK_URL` | Apps Script web URL'si (`https://script.google.com/macros/s/.../exec`) |
| `GMAIL_WEBHOOK_SECRET` | Script'te yazdığın `WEBHOOK_SECRET` ile **aynı** |
| `NOTIFY_EMAIL` | `hepsiduzici@gmail.com` |

**Save Changes** → deploy bitsin.

### 3. Test

Uygulama → **İhbar ve Öneri** → test mesajı gönder → Gmail gelen kutusu.

---

## Neden önceki yöntemler işe yaramadı?

| Yöntem | Sorun |
|--------|--------|
| Gmail SMTP | Render ücretsiz planda port 587 kapalı |
| Resend | Test adresi spam'e düşebilir / sadece hesap mailine gider |
| Brevo | Ekstra kayıt + doğrulama |

Apps Script = kendi Gmail'in, ekstra servis yok.
