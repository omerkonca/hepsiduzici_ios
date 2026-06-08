# iOS Push — İleride açılacak

Build'in geçmesi için `aps-environment` entitlement geçici kaldırıldı.
iOS push TestFlight'ta şu an çalışmaz; Android push çalışır.

## Push'u iOS'ta açmak için (boş zamanında)

1. developer.apple.com → Identifiers → **net.hepsiduzici.hepsiDuzici** → **Push Notifications** aç
2. Codemagic → Code signing → **Hepsi Duzici App Store** profilini sil
3. `ios/Runner/Runner.entitlements` dosyasını projeye geri bağla (CODE_SIGN_ENTITLEMENTS)
4. Yeni build al
