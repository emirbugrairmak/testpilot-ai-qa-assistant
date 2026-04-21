# TestPilot – Mobile (Flutter)

Bu klasor Faz 3A icin Flutter foundation seviyesine getirildi.

## Durum

- Flutter uyumlu dosya yapisi ve temel uygulama iskeleti olusturuldu.
- Login, dashboard ve generate ekranlari eklendi.
- `http` ve `shared_preferences` tabanli basit servis katmani yazildi.
- Sonuc onizlemesi generate ekrani icinde gosteriliyor.

## Bu Ortamda Tespit Edilen Durum

Bu makinede Flutter SDK erisilebilir degil.

Calistirilan kontrol:

```bash
flutter --version
```

Alinan sonuc:

```bash
zsh:1: command not found: flutter
```

Bu nedenle bu turda asagidaki Flutter komutlarini burada gercekten calistiramadim:

- `flutter pub get`
- `flutter analyze`
- `flutter run`

## Dosya Yapisi

```text
mobile/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
└── lib/
    ├── main.dart
    ├── models/
    ├── screens/
    ├── services/
    ├── utils/
    └── widgets/
```

## Uygulama Akisi

1. Uygulama acildiginda kayitli API key `shared_preferences` icinden okunur.
2. Kayitli key varsa `/api/v1/auth/validate` ile restore denenir.
3. Basariliysa dashboard acilir.
4. Dashboard ekraninda:
   - plan bilgisi
   - usage summary
   - son history kayitlari
   - Mod A / Mod B / Bug Report hizli aksiyonlari
5. Generate ekraninda moda gore alanlar degisir ve `/api/v1/generate` cagrilir.
6. Basarili cevap ayni ekranda onizleme olarak gosterilir.

## Demo API Key

```text
tp_free_demo_key
tp_premium_demo_key
```

## API Base URL

Varsayilan API adresi:

```text
http://10.0.2.2:8000
```

Bu Android emulator icin uygundur. Gerekirse calistirirken override edebilirsin:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

Gercek cihazda genellikle gelistirme makinenin yerel IP adresi gerekir.

## Flutter SDK Oldugunda Calistirma

```bash
cd mobile
flutter pub get
flutter analyze
flutter run
```
