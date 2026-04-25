# TestPilot – AI QA Assistant

> **From idea to test cases, in minutes.**

TestPilot, yazılım geliştirme sürecinde test hazırlama işini hızlandıran bir AI QA asistanıdır. Kullanıcı bir özellik fikri ya da hazır user story/AC girerek otomatik test planı, test senaryoları ve bug report taslağı üretebilir.

---

## 🏗️ Teknoloji Stack

| Katman | Teknoloji |
|--------|-----------|
| **Backend** | Python · FastAPI · SQLite |
| **Frontend** | TypeScript · React · Tailwind CSS · React Query |
| **Mobil** | Flutter (iOS + Android) |
| **LLM** | Google Gemini API (`gemini-2.0-flash`) · Mock fallback |
| **DevOps** | Docker · Docker Compose · Git · GitHub |

---

## 🚀 Hızlı Başlangıç

### Gereksinimler

- [Docker](https://docs.docker.com/get-docker/) ve [Docker Compose](https://docs.docker.com/compose/install/) yüklü olmalı.

### Kurulum ve Çalıştırma

```bash
# 1. Repoyu klonla
git clone <REPO_URL>
cd "TestPilot – AI QA Assistant"

# 2. Tüm servisleri başlat
docker-compose up --build
```

### Erişim

| Servis | URL |
|--------|-----|
| **Frontend (React)** | [http://localhost:3000](http://localhost:3000) |
| **Backend API** | [http://localhost:8000](http://localhost:8000) |
| **API Docs (Swagger)** | [http://localhost:8000/docs](http://localhost:8000/docs) |
| **Health Check** | [http://localhost:8000/health](http://localhost:8000/health) |

### Durdurma

```bash
docker-compose down
```

### Frontend Kullanım Akışı

1. `docker-compose up --build` komutuyla servisleri başlat.
2. Tarayıcıdan [http://localhost:3000](http://localhost:3000) adresine git.
3. Login ekranında `tp_free_demo_key` veya `tp_premium_demo_key` gir.
4. Dashboard üzerinden plan, usage ve son history kayıtlarını kontrol et.
5. `New Mod A`, `New Mod B` veya `New Bug Report` ile generate ekranına geç.
6. Premium hesapla Templates sayfasında custom template oluştur, düzenle veya sil.
7. Generate ekranında Premium hesapla custom template seçerek single generate çalıştır; Free hesapta template alanında premium uyarısı görünür.
8. Premium hesapla Batch Generate sayfasında Mod A veya Mod B için birden fazla item girip toplu üretim yap; Free hesapta premium uyarısı görünür.
9. Formu doldurup submit et; başarılı single üretim sonrası Result sayfasına yönlen.
10. Batch sonuçlarında başarılı item'ların `generation_id` bilgilerini ve Result linklerini kontrol et.
11. Result sayfasından JSON / Markdown export al; Premium hesapla CSV / Jira export da indir.
12. History sayfasında filtreleme, arama, result açma ve silme akışını dene.
13. Settings sayfasında plan, usage özeti, maskeli API key ve logout akışını kontrol et.

### Web Premium Özellik Akışı

- **Custom templates:** `tp_premium_demo_key` ile giriş yaptıktan sonra `Templates` menüsünden template listesi görüntülenir. Aynı ekranda yeni template oluşturma, mevcut template'i düzenleme ve silme işlemleri yapılır.
- **Template ile single generate:** `Generate` ekranında Premium kullanıcılar kendi template'lerini seçebilir. Seçilen template backend'e `template_id` olarak gönderilir. Free kullanıcı aynı alanda Premium uyarısı görür ve template gönderemez.
- **Batch generate:** `Batch Generate` ekranı Premium kullanıcılar için Mod A ve Mod B destekler. Birden fazla item eklenebilir, isteğe bağlı ortak template seçilebilir ve submit sonrası batch response içinde her item'ın başarı/hata durumu ile başarılı kayıtların `generation_id` bilgisi görünür.
- **Premium-only davranış:** Free kullanıcı `Templates` ve `Batch Generate` sayfalarında net Premium uyarısı görür; frontend backend yetki kurallarını gevşetmez.

---

## 🤖 Gemini LLM Kurulumu

TestPilot, varsayılan olarak **mock generator** ile çalışır (API key gerektirmez).
Gerçek AI çıktısı için Google Gemini API'ye bağlanabilirsin.

### Adım 1 — API Key Al

[https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey) adresinden **ücretsiz** API key alabilirsin.
`gemini-2.0-flash` modeli free tier'da kullanılabilir.

### Adım 2 — .env Dosyasını Oluştur

```bash
cd backend
cp .env.example .env
# .env içinde GEMINI_API_KEY= satırını doldur
```

### Adım 3 — Gemini'yi Etkinleştir

`.env` veya `docker-compose.yml` içinde:

```bash
LLM_PROVIDER=gemini
GEMINI_API_KEY=your_actual_api_key_here
GEMINI_MODEL=gemini-2.0-flash        # varsayılan
LLM_FALLBACK_TO_MOCK=true            # Gemini hata verirse mock'a düş
```

### Mock ↔ Gemini Geçişi

| `LLM_PROVIDER` | `GEMINI_API_KEY` | Davranış |
|----------------|------------------|----------|
| `mock` | herhangi | Deterministik mock generator |
| `gemini` | boş | Uyarı log'u → mock'a düş |
| `gemini` | dolu | Gerçek Gemini API çağrısı |

### Kullanılabilir Modeller

| Model | Hız | Kalite | Free Tier |
|-------|-----|--------|-----------|
| `gemini-2.0-flash` | ⚡⚡⚡ | ★★★★ | ✅ |
| `gemini-2.5-flash` | ⚡⚡ | ★★★★★ | ✅ |
| `gemini-1.5-pro` | ⚡ | ★★★★★ | Sınırlı |

### Fallback Davranışı

- `LLM_FALLBACK_TO_MOCK=true` (varsayılan): Gemini API hatası → mock generator devreye girer, istek başarıyla tamamlanır, `WARNING` log yazılır.
- `LLM_FALLBACK_TO_MOCK=false`: Gemini hatası → `503 Service Unavailable` döner.

---

## 🔑 Demo API Key'leri

Backend ilk başlatıldığında iki test API key'i otomatik oluşturulur:

| Key | Plan | Aylık Limit |
|-----|------|-------------|
| `tp_free_demo_key` | Free | 30 üretim |
| `tp_premium_demo_key` | Premium | 200 üretim |

### Test Curl Komutları

**Auth Doğrulama (Free Anahtar):**
```bash
curl -X POST http://localhost:8000/api/v1/auth/validate \
  -H "Authorization: Bearer tp_free_demo_key"
```

**Mod A — Feature Idea'dan Test Üretimi:**
```bash
curl -X POST http://localhost:8000/api/v1/generate \
  -H "Authorization: Bearer tp_premium_demo_key" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "mod_a",
    "feature_idea": "User login with email and password"
  }'
```

**Mod B — User Story + AC'den Test Üretimi:**
```bash
curl -X POST http://localhost:8000/api/v1/generate \
  -H "Authorization: Bearer tp_premium_demo_key" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "mod_b",
    "user_story": "As a user, I want to reset my password so that I can regain access to my account",
    "acceptance_criteria": "Given a registered user, when they click Forgot Password and enter their email, then they receive a reset link within 5 minutes"
  }'
```

**Bug Report Üretimi:**
```bash
curl -X POST http://localhost:8000/api/v1/generate \
  -H "Authorization: Bearer tp_free_demo_key" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "bug_report",
    "title": "Login button stays disabled",
    "steps_to_reproduce": [
      "Open the login page",
      "Enter a valid email and password",
      "Try to click Login"
    ],
    "actual_result": "The Login button remains disabled.",
    "expected_result": "The user can submit the login form.",
    "environment": "Chrome 123, macOS",
    "severity": "High"
  }'
```

**History Listeleme:**
```bash
curl http://localhost:8000/api/v1/history \
  -H "Authorization: Bearer tp_free_demo_key"
```

**History Arama / Mode Filtresi:**
```bash
curl "http://localhost:8000/api/v1/history?mode=bug_report&q=Login" \
  -H "Authorization: Bearer tp_free_demo_key"
```

**Usage Bilgisi:**
```bash
curl http://localhost:8000/api/v1/usage \
  -H "Authorization: Bearer tp_free_demo_key"
```

**Export Örnekleri:**
```bash
# JSON ve Markdown: Free + Premium
curl http://localhost:8000/api/v1/export/1/json \
  -H "Authorization: Bearer tp_free_demo_key" \
  -OJ

curl http://localhost:8000/api/v1/export/1/markdown \
  -H "Authorization: Bearer tp_free_demo_key" \
  -OJ

# CSV ve Jira: sadece Premium
curl http://localhost:8000/api/v1/export/1/csv \
  -H "Authorization: Bearer tp_premium_demo_key" \
  -OJ

curl http://localhost:8000/api/v1/export/1/jira \
  -H "Authorization: Bearer tp_premium_demo_key" \
  -OJ
```

**Batch Mod A — Toplu Feature Testi (Premium):**
```bash
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

**Batch Mod B — Toplu Story Testi (Premium):**
```bash
curl -X POST http://localhost:8000/api/v1/generate/batch \
  -H "Authorization: Bearer tp_premium_demo_key" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "mod_b",
    "items": [
      {
        "user_story": "As a user I want to update my profile",
        "acceptance_criteria": "Given auth user, When they submit form, Then profile updates"
      }
    ]
  }'
```

**Custom Template Oluştur (Premium):**
```bash
curl -X POST http://localhost:8000/api/v1/templates \
  -H "Authorization: Bearer tp_premium_demo_key" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Security Focus",
    "prompt_text": "Always include at least 2 security test cases: authentication and authorization."
  }'
```

**Template Listesi (Premium):**
```bash
curl http://localhost:8000/api/v1/templates \
  -H "Authorization: Bearer tp_premium_demo_key"
```

**Template Güncelle (Premium):**
```bash
curl -X PUT http://localhost:8000/api/v1/templates/1 \
  -H "Authorization: Bearer tp_premium_demo_key" \
  -H "Content-Type: application/json" \
  -d '{"name": "Security Focus v2", "prompt_text": "Include XSS and SQLi test cases."}'
```

**Template Sil (Premium):**
```bash
curl -X DELETE http://localhost:8000/api/v1/templates/1 \
  -H "Authorization: Bearer tp_premium_demo_key"
```

**Template ile Generate (Premium):**
```bash
curl -X POST http://localhost:8000/api/v1/generate \
  -H "Authorization: Bearer tp_premium_demo_key" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "mod_a",
    "feature_idea": "User profile settings",
    "template_id": 1
  }'
```

---



| Method | Endpoint | Açıklama | Auth |
|--------|----------|----------|------|
| `GET` | `/health` | Servis sağlık kontrolü | ❌ |
| `GET` | `/docs` | Swagger API dokümantasyonu | ❌ |
| `POST` | `/api/v1/auth/validate` | API key doğrulama + plan bilgisi | ✅ Bearer |
| `POST` | `/api/v1/generate` | Test üretimi (mod_a, mod_b, bug_report); opsiyonel `template_id` | ✅ Bearer |
| `POST` | `/api/v1/generate/batch` | Batch test üretimi (mod_a, mod_b) — **Premium only** | ✅ Bearer |
| `GET` | `/api/v1/history` | Generation geçmişi; `mode` ve `q` query desteği | ✅ Bearer |
| `GET` | `/api/v1/history/{id}` | Tek generation detayı | ✅ Bearer |
| `DELETE` | `/api/v1/history/{id}` | Tek generation kaydını siler | ✅ Bearer |
| `GET` | `/api/v1/export/{id}/json` | JSON export | ✅ Bearer |
| `GET` | `/api/v1/export/{id}/markdown` | Markdown export | ✅ Bearer |
| `GET` | `/api/v1/export/{id}/csv` | CSV export — **Premium only** | ✅ Bearer |
| `GET` | `/api/v1/export/{id}/jira` | Jira-friendly text export — **Premium only** | ✅ Bearer |
| `GET` | `/api/v1/usage` | Plan, aylık limit, kullanım ve kalan hak bilgisi | ✅ Bearer |
| `GET` | `/api/v1/templates` | Custom template listesi — **Premium only** | ✅ Bearer |
| `POST` | `/api/v1/templates` | Yeni template oluştur — **Premium only** | ✅ Bearer |
| `PUT` | `/api/v1/templates/{id}` | Template güncelle — **Premium only** | ✅ Bearer |
| `DELETE` | `/api/v1/templates/{id}` | Template sil — **Premium only** | ✅ Bearer |

### Free / Premium Kuralları

| Özellik | Free | Premium |
|---------|------|---------|
| History liste | Son 15 kayıt | Tüm kayıtlar |
| JSON export | ✅ | ✅ |
| Markdown export | ✅ | ✅ |
| CSV export | ❌ 403 | ✅ |
| Jira export | ❌ 403 | ✅ |
| Custom templates | ❌ 403 | ✅ |
| Template ile generate | ❌ 403 | ✅ |
| Batch generate | ❌ 403 | ✅ |
| Free watermark | ✅ | ❌ |

Frontend tarafında free kullanıcı CSV veya Jira export butonuna basarsa net bir premium uyarısı gösterilir; backend kuralı frontend tarafından gevşetilmez.

### Usage Yanıtı

`GET /api/v1/usage` aşağıdaki alanları döndürür:

```json
{
  "plan": "free",
  "monthly_limit": 30,
  "usage_count": 4,
  "remaining": 26,
  "usage_reset_at": "2026-05-01T00:00:00"
}
```

---

## 📁 Proje Yapısı

```
TestPilot – AI QA Assistant/
├── docker-compose.yml
├── backend/               ← Python / FastAPI
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── data/              ← SQLite veritabanı (gitignore)
│   └── app/
│       ├── main.py
│       ├── config.py
│       ├── database.py
│       ├── models/
│       │   ├── db_models.py
│       │   └── schemas.py
│       ├── routers/
│       │   ├── auth.py
│       │   ├── export.py
│       │   ├── generate.py      ← single + batch
│       │   ├── history.py
│       │   ├── templates.py     ← YENİ
│       │   └── usage.py
│       ├── services/
│       │   ├── export_service.py
│       │   ├── generation_service.py
│       │   ├── history_service.py
│       │   ├── llm_service.py
│       │   └── template_service.py  ← YENİ
│       ├── prompts/
│       │   ├── bug_report_prompt.py
│       │   ├── mod_a_prompt.py
│       │   └── mod_b_prompt.py
│       └── utils/
│           └── auth.py
├── frontend/              ← React / TypeScript / Tailwind
│   ├── Dockerfile
│   ├── package.json
│   └── src/
│       ├── assets/
│       ├── components/
│       ├── hooks/
│       ├── pages/
│       ├── services/
│       ├── types/
│       ├── main.tsx
│       └── App.tsx
├── mobile/                ← Flutter (iOS + Android)
├── logo/                  ← Logo dosyaları
├── stories/               ← Instagram story görselleri
├── proje.md               ← Fikir onay dokümanı
└── README.md
```

---

## 📋 Proje Durumu

- [x] Faz 0 — Proje İskeleti + Docker
- [x] Faz 1A — Backend Core (DB, Auth, Generate API, Mock LLM)
- [x] Faz 1B — Backend Surface Completion (History, Export, Usage, Bug Report)
- [x] Faz 2A — Frontend Foundation (Login, Dashboard, Generate)
- [x] Faz 2B — Frontend Completion (History, Result, Settings, Export UI)
- [x] Faz 4A — Real Gemini Integration (google-genai SDK, mock fallback)
- [x] Faz 4B — Premium Backend Features (Batch, Custom Templates, Template+Generate)
- [x] Faz 4C — Premium Web UI (Templates, Batch Generate, Template+Generate UI)
- [ ] Faz 3 — Flutter Mobil Uygulama
- [ ] Faz 5 — Final Polish + Teslim

---

## 👤 Geliştirici

**Emir Buğra Irmak** — 21253061
