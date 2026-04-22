# TestPilot - Mobile (Flutter)

Bu klasor Faz 3B seviyesinde daha tamamlanmis bir Flutter mobil demo iskeleti icin guncellendi.

## Durum

- Flutter proje iskeleti gercek olarak olusturuldu (`android/`, `ios/`, `test/` dahil).
- Login, dashboard, generate, result, history ve settings ekranlari eklendi.
- Basit state yonetimi korundu; agir mimari eklenmedi.
- `http`, `shared_preferences`, `flutter_markdown`, `path_provider` ve `share_plus` kullanildi.

## Mobil Akis

1. Uygulama acilisinda kayitli API key `shared_preferences` icinden okunur.
2. Key varsa `/api/v1/auth/validate` ile oturum restore edilir.
3. Dashboard ekraninda:
   - current plan
   - usage summary
   - recent history
   - Mod A / Mod B / Bug Report aksiyonlari
4. Generate ekraninda mod degistikce form alanlari degisir.
5. Basarili generate sonrasi Result ekranina gecilir.
6. Result ekrani history detail verisiyle de acilabilir.
7. History ekraninda listeleme, arama, mode filtresi, acma ve silme vardir.
8. Settings ekraninda plan, usage, maskeli API key ve logout bulunur.

## Export Davranisi

- JSON ve Markdown export tum planlar icin aciktir.
- CSV ve Jira export sadece premium plan icindir.
- Free kullanici CSV veya Jira denediginde net premium uyari mesaji gorur.
- Premium export icin dosya backend'den cekilir, gecici dosya olarak yazilir ve native share sheet acilir.

## API Base URL

Varsayilan API adresi:

```text
http://10.0.2.2:8000
```

Bu Android emulator icin uygundur. Gerekirse override:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

Gercek cihazda genellikle gelistirme makinenin local IP adresi gerekir.

## Demo API Key

```text
tp_free_demo_key
tp_premium_demo_key
```

## Bu Ortamda Gercekten Calistirilan Flutter Komutlari

Calistirabildigim komutlar:

```bash
flutter --version
flutter create . --platforms=android,ios
flutter pub get
flutter analyze
```

`flutter run` bu turda denenmedi; ancak proje artik gercek Flutter platform scaffold'larina sahip.

## Calistirma

```bash
cd mobile
flutter pub get
flutter analyze
flutter run
```
