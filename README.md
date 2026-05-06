# TestPilot - AI QA Assistant

TestPilot, feature idea, user story/acceptance criteria veya bug bilgisi girilerek test planı, test case seti ve bug report taslağı üreten demo seviyesinde bir AI QA asistanıdır. Proje FastAPI backend, React web arayüzü, Flutter mobil uygulama iskeleti ve Docker Compose çalışma düzeninden oluşur.

Kimlik modeli access key tabanlıdır. Web uygulamasında kullanıcı mevcut access key ile dönebilir, yeni Free access key oluşturabilir veya gerçek ödeme almayan Premium satın alma simülasyonu sonrası Premium access key edinebilir. Email/password, signup/login hesabı veya JWT sistemi yoktur.

## Proje Özeti

- Backend, access key tabanlı auth, kullanım limiti, history, export, custom template ve batch generate akışlarını sağlar.
- Web uygulaması login, dashboard, generate, result, history, settings, templates ve batch generate ekranlarını içerir.
- Mobil uygulama Flutter ile login, dashboard, generate, result, history, settings ve export paylaşım akışlarını demo seviyesinde sunar.
- LLM katmanı varsayılan olarak deterministik mock generator ile çalışır; `gemini` provider seçilirse Google Gemini API kullanılabilir. Aktif AI motoru `/health` yanıtında ve web dashboard'daki küçük durum etiketinde görünür.

## Özellikler

| Özellik | Free | Premium |
| --- | --- | --- |
| Mod A: feature idea -> test çıktısı | Var | Var |
| Mod B: user story + AC -> test çıktısı | Var | Var |
| Bug report üretimi | Var | Var |
| Usage/limit takibi | 30/ay | 200/ay |
| History | Son 15 kayıt | Tüm kayıtlar |
| JSON export | Var | Var |
| Markdown export | Var | Var |
| CSV export | Yok | Var |
| Jira-friendly export | Yok | Var |
| Custom templates | Yok | Var |
| Template ile generate | Yok | Var |
| Batch generate | Yok | Var |
| Plan kaynak damgası | Var | Yok |

Free plan üretimlerinde damga bir koruma mekanizması değil, çıktının plan
kaynağını belirten provenance bilgisidir. Sonuç ekranında küçük meta bilgi
olarak görünür. Free JSON ve Markdown export dosyaları ayrıca HMAC-SHA256 ile
imzalanmış `export_id`, `generated_at`, `payload_sha256` ve `signature` alanları
taşır. Bu yapı metnin silinmesini teknik olarak engellemez; export'un orijinal
TestPilot Free çıktısı olup olmadığını ve payload'ın değiştirilip
değiştirilmediğini doğrulanabilir hale getirir. Premium çıktılarda Free plan
kaynak damgası yer almaz.

## Access Key ile Plan Edinme

TestPilot'ta çalışma alanı sahipliği `api_keys` tablosundaki access key üzerinden yürür. Hangi Bearer token ile giriş yapılırsa o key'in planı, usage sayacı, history kayıtları, custom template kayıtları ve batch generate sonuçları kullanılır. Aynı key ile tekrar girişte aynı çalışma alanı verisi geri gelir.

Web login ekranındaki ana akış:

- Mevcut erişim anahtarıyla giriş yap.
- Free erişim al: yeni, benzersiz ve kalıcı Free access key üretir; usage/history boş başlar.
- Premium al: gerçek ödeme almayan kısa satın alma simülasyonu sonrası yeni, benzersiz ve kalıcı Premium access key üretir.

Demo API key'leri backend ilk açıldığında seed edilir ve geliştirici kolaylığı için korunur:

```text
tp_free_demo_key
tp_premium_demo_key
```

Varsayılan demo davranışında bu iki erişim anahtarının usage ve history verisi backend başlangıcında temizlenir. Böylece Free ve Premium çalışma alanları ilk girişte `0` usage ve boş recent history ile öngörülebilir başlar. Restart sonrası local demo geçmişini korumak istersen `DEMO_RESET_ON_STARTUP=false` kullan.

## Teknolojiler

| Katman | Teknoloji |
| --- | --- |
| Backend | Python 3.12, FastAPI, SQLite, python-dotenv |
| LLM | Mock generator, Google Gemini API (`google-genai`) |
| Web | React, TypeScript, Vite, Tailwind CSS, React Query |
| Mobile | Flutter, Dart, http, shared_preferences, share_plus |
| DevOps | Docker, Docker Compose |

## Klasör Yapısı

```text
TestPilot - AI QA Assistant/
├── .env.example              # Docker Compose için env örneği
├── docker-compose.yml
├── README.md
├── backend/
│   ├── .env.example          # Local backend çalıştırma için env örneği
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
│       ├── main.py
│       ├── config.py
│       ├── database.py
│       ├── models/
│       ├── prompts/
│       ├── routers/
│       ├── services/
│       └── utils/
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   └── src/
│       ├── components/
│       ├── hooks/
│       ├── pages/
│       ├── services/
│       └── types/
└── mobile/
    ├── README.md
    ├── pubspec.yaml
    ├── lib/
    ├── android/
    ├── ios/
    └── test/
```

## Local Kurulum

Backend:

```bash
cd backend
cp .env.example .env
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Web:

```bash
cd frontend
npm install
npm run dev -- --host 0.0.0.0 --port 3000
```

Mobil:

```bash
cd mobile
flutter pub get
flutter analyze
flutter run
```

Android emulator varsayılan backend adresi `http://10.0.2.2:8000` olarak ayarlıdır. iOS simulator veya gerçek cihaz için gerekirse:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

Gerçek cihazda `localhost` yerine geliştirme makinesinin yerel ağ IP adresi gerekebilir.

## Docker ile Çalıştırma

Varsayılan mock LLM ile:

```bash
docker compose up --build
```

Eski Compose sürümü kullanıyorsan aynı komut `docker-compose up --build` olarak çalıştırılabilir.

Erişim adresleri:

| Servis | URL |
| --- | --- |
| Web | http://localhost:3000 |
| Backend API | http://localhost:8000 |
| Swagger | http://localhost:8000/docs |
| Health | http://localhost:8000/health |

Durdurma:

```bash
docker compose down
```

Docker ile Gemini kullanmak için repo kökünde `.env` oluştur:

```bash
cp .env.example .env
```

Ardından `.env` içinde:

```bash
LLM_PROVIDER=gemini
GEMINI_API_KEY=your_actual_api_key_here
GEMINI_MODEL=gemini-2.0-flash
GEMINI_TIMEOUT_MS=30000
LLM_FALLBACK_TO_MOCK=false
DEMO_RESET_ON_STARTUP=true
EXPORT_SIGNATURE_SECRET=change-this-export-signature-secret
```

Sonra servisleri yeniden başlat:

```bash
docker compose up --build
```

## Gemini Env Ayarı

Backend local çalıştırmada `backend/.env` okunur:

```bash
cd backend
cp .env.example .env
```

Temel davranış:

| `LLM_PROVIDER` | `GEMINI_API_KEY` | Davranış |
| --- | --- | --- |
| `mock` | Boş veya dolu | Deterministik mock çıktı üretir |
| `gemini` | Boş | Fallback kapalıysa `/health` içinde `unavailable` görünür ve üretim 503 döner |
| `gemini` | Dolu | Gemini API ile üretim dener |

`LLM_FALLBACK_TO_MOCK=false` varsayılandır. Bu ayarda Gemini hatası `503 Service Unavailable` olarak döner; böylece gerçek Gemini çıktısı ile mock çıktı sessizce karışmaz. `true` yapılırsa Gemini hatalarında üretim akışı mock ile devam eder ve web dashboard'da fallback açık görünür.

`GET /health` yanıtındaki `ai` alanı aktif motoru gösterir:

```json
{
  "ai": {
    "configured_provider": "gemini",
    "effective_provider": "gemini",
    "model": "gemini-2.0-flash",
    "fallback_to_mock": false,
    "gemini_key_configured": true
  }
}
```

## Backend Endpoint Özeti

| Method | Endpoint | Açıklama | Auth |
| --- | --- | --- | --- |
| `GET` | `/health` | Servis ve AI motoru sağlık/durum kontrolü | Yok |
| `GET` | `/docs` | Swagger UI | Yok |
| `POST` | `/api/v1/auth/access/free` | Yeni Free access key oluşturma | Yok |
| `POST` | `/api/v1/auth/access/premium` | Premium satın alma simülasyonu sonrası key oluşturma | Yok |
| `POST` | `/api/v1/auth/validate` | API key doğrulama | Bearer |
| `POST` | `/api/v1/generate` | Mod A, Mod B veya bug report üretimi | Bearer |
| `POST` | `/api/v1/generate/batch` | Toplu Mod A/Mod B üretimi | Premium |
| `GET` | `/api/v1/history` | History listeleme, `mode` ve `q` filtresi | Bearer |
| `GET` | `/api/v1/history/{id}` | Tek kayıt detayı | Bearer |
| `DELETE` | `/api/v1/history/{id}` | Tek kayıt silme | Bearer |
| `GET` | `/api/v1/export/{id}/json` | JSON export | Bearer |
| `GET` | `/api/v1/export/{id}/markdown` | Markdown export | Bearer |
| `GET` | `/api/v1/export/{id}/csv` | CSV export | Premium |
| `GET` | `/api/v1/export/{id}/jira` | Jira-friendly text export | Premium |
| `POST` | `/api/v1/export/verify` | Free export imzası ve payload hash doğrulama | Yok |
| `GET` | `/api/v1/usage` | Plan ve kullanım özeti | Bearer |
| `GET` | `/api/v1/templates` | Template listesi | Premium |
| `POST` | `/api/v1/templates` | Template oluşturma | Premium |
| `PUT` | `/api/v1/templates/{id}` | Template güncelleme | Premium |
| `DELETE` | `/api/v1/templates/{id}` | Template silme | Premium |

Jira export gerçek bir `.jira` dosya standardı üretmez. Premium kullanıcılar için
Jira ekranına yapıştırılabilir plain text çıktı indirir; dosya adı
`generation-{id}-jira.txt` biçimindedir. Mod A / Mod B çıktıları gerçek bug
değil, QA task / test preparation taslağı olarak formatlanır. Bug Report modu
ise bug ticket draft formatını korur.

Hızlı backend testleri:

```bash
curl http://localhost:8000/health

curl -X POST http://localhost:8000/api/v1/auth/access/free \
  -H "Content-Type: application/json" \
  -d '{"owner_name": "Free QA Workspace"}'

curl -X POST http://localhost:8000/api/v1/auth/access/premium \
  -H "Content-Type: application/json" \
  -d '{
    "owner_name": "Atlas QA Team",
    "plan_summary": "Premium monthly simulation - 200 generations/month"
  }'

curl -X POST http://localhost:8000/api/v1/auth/validate \
  -H "Authorization: Bearer tp_free_demo_key"

curl -X POST http://localhost:8000/api/v1/generate \
  -H "Authorization: Bearer tp_free_demo_key" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "mod_a",
    "feature_idea": "User can reset password by email"
  }'

curl http://localhost:8000/api/v1/history \
  -H "Authorization: Bearer tp_free_demo_key"

curl http://localhost:8000/api/v1/usage \
  -H "Authorization: Bearer tp_free_demo_key"
```

Premium batch/template kontrolü:

```bash
curl -X POST http://localhost:8000/api/v1/templates \
  -H "Authorization: Bearer tp_premium_demo_key" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Security Focus",
    "prompt_text": "Include authentication and authorization test coverage."
  }'

curl -X POST http://localhost:8000/api/v1/generate/batch \
  -H "Authorization: Bearer tp_premium_demo_key" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "mod_a",
    "items": [
      {"feature_idea": "Password reset via email"},
      {"feature_idea": "Two-factor authentication setup"}
    ]
  }'
```

## Web Kullanım Akışı

1. Backend ve web servislerini başlat.
2. `http://localhost:3000` adresini aç.
3. `tp_free_demo_key` veya `tp_premium_demo_key` ile giriş yap.
4. Dashboard'da plan, usage ve son history kayıtlarını kontrol et.
5. Generate ekranında Mod A, Mod B veya Bug Report seçip üretim yap.
6. Result ekranında çıktıyı incele ve export seçeneklerini dene.
7. History ekranında arama, mode filtresi, detay açma ve silme akışını kontrol et.
8. Premium key ile Templates ve Batch Generate ekranlarını dene.
9. Settings ekranında maskeli API key, kullanım özeti ve logout akışını kontrol et.

## Mobile Kullanım Akışı

1. Backend'i local veya Docker ile çalıştır.
2. `cd mobile && flutter run` komutunu çalıştır.
3. Emulator/simulator için doğru `API_BASE_URL` değerini kullan.
4. Demo API key ile login ol.
5. Dashboard, generate, result, history ve settings ekranlarını sırayla kontrol et.
6. JSON/Markdown export paylaşım akışını dene.
7. Premium key ile CSV/Jira export davranışını doğrula.

## Son Kullanıcı Kontrol Listesi

Backend:

```bash
cd backend
python -m compileall app
uvicorn app.main:app --host 0.0.0.0 --port 8000
curl http://localhost:8000/health
```

Web:

```bash
cd frontend
npm run build
npm run dev -- --host 0.0.0.0 --port 3000
```

Mobile:

```bash
cd mobile
flutter pub get
flutter analyze
flutter run
```

Gemini:

```bash
# Backend local için backend/.env, Docker için repo kökündeki .env dosyasında:
LLM_PROVIDER=gemini
GEMINI_API_KEY=your_actual_api_key_here
LLM_FALLBACK_TO_MOCK=false
EXPORT_SIGNATURE_SECRET=change-this-export-signature-secret
```

Sonra bir `POST /api/v1/generate` isteği çalıştır. Geçerli key ve network varsa Gemini çıktısı döner; key veya API tarafı hatalıysa fallback kapalıyken `503` beklenir.

Docker:

```bash
docker compose up --build
curl http://localhost:8000/health
docker compose down
```

## Proje Durumu

Tam çalışan alanlar:

- Backend auth, usage, generate, history, export, template ve batch endpoint'leri.
- Gemini ile gerçek AI üretimi; mock yalnızca açıkça seçilen lokal deterministik geliştirme modu.
- Web uygulamasında free/premium ayrımı, generate, history, export, templates ve batch UI akışları.
- Flutter mobil uygulamasında temel login, dashboard, generate, result, history, settings ve export paylaşım akışları.
- Docker Compose ile backend + web servislerinin birlikte ayağa kalkması.

Demo seviyesinde olan alanlar:

- API key sistemi gerçek kullanıcı yönetimi yerine seed edilmiş demo key'lere dayanır.
- SQLite local/demo kullanım için uygundur; production DB migrasyon/backup stratejisi yoktur.
- Gemini entegrasyonu demo/release akışının varsayılanıdır; mock fallback varsayılan kapalıdır ve Gemini hatası kullanıcıyı yanıltmadan `503` döner.
- Mobil uygulama temel ürün akışını gösterir; store release, cihaz matrisi ve geniş kapsamlı UI testleri yapılmamıştır.

Opsiyonel veya sınırlı alanlar:

- Ödeme sistemi, admin panel, advanced analytics ve landing page yoktur.
- Rate limit, audit log, role management ve multi-tenant yönetim production seviyesinde değildir.
- Batch generate sequential çalışır; büyük ölçekli queue/worker mimarisi yoktur.

## Bilinen Sınırlamalar

- Free ve premium planlar demo API key üzerinden ayrılır.
- Export dosyaları backend'de kalıcı dosya olarak saklanmaz; response olarak üretilir.
- Docker Compose development server'ları çalıştırır; production image optimizasyonu hedeflenmemiştir.
- Mobile varsayılan API adresi Android emulator içindir; iOS/gerçek cihazda override gerekebilir.
- Gemini kullanımı için internet erişimi ve geçerli Google API key gerekir.

## Faz 5A Notu

Bu tur final teslim öncesi polish/readiness kapsamındadır. Yeni büyük özellik, ödeme sistemi, admin panel, landing page, advanced analytics veya yeni AI mimarisi eklenmemiştir.

## Geliştirici

Emir Buğra Irmak - 21253061
