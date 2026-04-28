# TestPilot Mobile

Flutter ile hazırlanmış TestPilot mobil demo uygulamasıdır. Backend API ile demo API key üzerinden konuşur ve web uygulamasındaki ana QA akışlarının mobil karşılığını sunar.

## Durum

- Login, dashboard, generate, result, history ve settings ekranları vardır.
- Mod A, Mod B ve Bug Report için generate akışı desteklenir.
- History listeleme, arama, mode filtresi, detay açma ve silme akışları bulunur.
- JSON ve Markdown export tüm planlarda açıktır.
- CSV ve Jira export premium planda native share sheet üzerinden paylaşılır.
- Store release, geniş cihaz matrisi ve kapsamlı UI testleri bu demo kapsamına dahil değildir.

## API Base URL

Varsayılan adres Android emulator için uygundur:

```text
http://10.0.2.2:8000
```

iOS simulator veya farklı ortam için override:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

Gerçek cihazda genellikle geliştirme makinesinin yerel ağ IP adresi gerekir.

## Demo API Key

```text
tp_free_demo_key
tp_premium_demo_key
```

## Çalıştırma

```bash
flutter pub get
flutter analyze
flutter run
```

Backend'in local veya Docker ile çalışıyor olması gerekir.
