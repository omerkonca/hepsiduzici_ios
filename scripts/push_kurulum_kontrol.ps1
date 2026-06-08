# Push bildirim kurulum kontrolu
# Kullanim: .\scripts\push_kurulum_kontrol.ps1

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Write-Host ""
Write-Host "=== Hepsi Duzici Push Kurulum Kontrolu ===" -ForegroundColor Cyan
Write-Host ""

$checks = @(
    @{
        Name = "Android google-services.json"
        Path = Join-Path $root "android\app\google-services.json"
        Fix  = "Firebase Console - Android app - indir - android\app\ klasorune koy"
    },
    @{
        Name = "iOS GoogleService-Info.plist"
        Path = Join-Path $root "ios\Runner\GoogleService-Info.plist"
        Fix  = "Firebase Console - iOS app - indir - ios\Runner\ klasorune koy"
    },
    @{
        Name = "Push servis kodu"
        Path = Join-Path $root "lib\core\push\push_notification_service.dart"
        Fix  = "git pull ile repoyu guncelleyin"
    },
    @{
        Name = "Kurulum rehberi"
        Path = Join-Path $root "docs\PUSH_KURULUM_ADIM_ADIM.md"
        Fix  = "docs klasorunu kontrol edin"
    }
)

$ok = 0
foreach ($c in $checks) {
    if (Test-Path $c.Path) {
        Write-Host "[OK]    $($c.Name)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "[EKSIK] $($c.Name)" -ForegroundColor Red
        Write-Host "        $($c.Fix)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "--- Manuel kontrol (siz yapmalisiniz) ---" -ForegroundColor Cyan
Write-Host "[?] Supabase secret: PUSH_ADMIN_TOKEN"
Write-Host "[?] Supabase secret: FIREBASE_SERVICE_ACCOUNT_JSON"
Write-Host "[?] Firebase Cloud Messaging - APNs key (iOS)"
Write-Host ""
Write-Host "Rehber: docs\PUSH_KURULUM_ADIM_ADIM.md"
Write-Host ""

if ($ok -eq $checks.Count) {
    Write-Host "Dosya kontrolleri tamam. Supabase secret ve build sonrasi push gonderebilirsiniz." -ForegroundColor Green
} else {
    Write-Host "Once eksik dosyalari tamamlayin, sonra flutter build alin." -ForegroundColor Yellow
}
Write-Host ""
