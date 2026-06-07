# Hepsi Duzici - Google Play Store hazirlik scripti
# Kullanim: PowerShell'de proje kokunden calistir
#   .\scripts\playstore_setup.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$AndroidDir = Join-Path $Root "android"
$KeystorePath = Join-Path $AndroidDir "upload-keystore.jks"
$KeyPropsPath = Join-Path $AndroidDir "key.properties"
$KeyPropsExample = Join-Path $AndroidDir "key.properties.example"

Write-Host "=== Hepsi Duzici Play Store Kurulumu ===" -ForegroundColor Cyan

if (-not (Test-Path $KeystorePath)) {
    Write-Host ""
    Write-Host "1) Upload keystore olusturuluyor..." -ForegroundColor Yellow
    Write-Host "   Asagidaki sorularda guclu bir sifre belirle ve KAYDET (kaybedersen guncelleme yapamazsin)." -ForegroundColor DarkYellow

    $keytool = "keytool"
    if (Get-Command keytool -ErrorAction SilentlyContinue) {
        & $keytool -genkey -v `
            -keystore $KeystorePath `
            -keyalg RSA -keysize 2048 -validity 10000 `
            -alias upload `
            -dname "CN=Hepsi Duzici, OU=Mobile, O=Hepsi Duzici, L=Duzici, ST=Osmaniye, C=TR"
    } else {
        Write-Host "keytool bulunamadi. JDK kurulu oldugundan emin ol." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Keystore zaten var: $KeystorePath" -ForegroundColor Green
}

if (-not (Test-Path $KeyPropsPath)) {
    Write-Host ""
    Write-Host "2) key.properties olusturuluyor..." -ForegroundColor Yellow
    $storePass = Read-Host "Keystore sifresini gir (storePassword)"
    $keyPass = Read-Host "Key sifresini gir (genelde ayni)"
    @"
storePassword=$storePass
keyPassword=$keyPass
keyAlias=upload
storeFile=../upload-keystore.jks
"@ | Set-Content -Path $KeyPropsPath -Encoding UTF8
    Write-Host "key.properties kaydedildi." -ForegroundColor Green
} else {
    Write-Host "key.properties zaten var." -ForegroundColor Green
}

Write-Host ""
Write-Host "3) Android lisanslari kontrol ediliyor..." -ForegroundColor Yellow
Push-Location $Root
flutter doctor --android-licenses 2>$null
flutter pub get

Write-Host ""
Write-Host "4) Release App Bundle (AAB) derleniyor..." -ForegroundColor Yellow
flutter build appbundle --release

$bundle = Join-Path $Root "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $bundle) {
    Write-Host ""
    Write-Host "BASARILI!" -ForegroundColor Green
    Write-Host "Yuklenecek dosya:" -ForegroundColor Green
    Write-Host "  $bundle" -ForegroundColor White
    Write-Host ""
    Write-Host "Sonraki adim: Google Play Console -> Uygulama olustur -> Production -> Bu AAB dosyasini yukle" -ForegroundColor Cyan
} else {
    Write-Host "AAB olusturulamadi. Yukaridaki hatalari kontrol et." -ForegroundColor Red
    exit 1
}
Pop-Location
