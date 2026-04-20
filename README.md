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
| **LLM** | Google Gemini API (şu an mock modunda) |
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

---

## 📡 API Endpoint'leri

| Method | Endpoint | Açıklama | Auth |
|--------|----------|----------|------|
| `GET` | `/health` | Servis sağlık kontrolü | ❌ |
| `GET` | `/docs` | Swagger API dokümantasyonu | ❌ |
| `POST` | `/api/v1/auth/validate` | API key doğrulama + plan bilgisi | ✅ Bearer |
| `POST` | `/api/v1/generate` | Test üretimi (`mod_a`, `mod_b`) ve bug report üretimi (`bug_report`) | ✅ Bearer |
| `GET` | `/api/v1/history` | Generation geçmişi; `mode` ve `q` query desteği vardır | ✅ Bearer |
| `GET` | `/api/v1/history/{id}` | Tek generation detayı | ✅ Bearer |
| `DELETE` | `/api/v1/history/{id}` | Tek generation kaydını siler | ✅ Bearer |
| `GET` | `/api/v1/export/{id}/json` | JSON export | ✅ Bearer |
| `GET` | `/api/v1/export/{id}/markdown` | Markdown export | ✅ Bearer |
| `GET` | `/api/v1/export/{id}/csv` | CSV export | ✅ Bearer + Premium |
| `GET` | `/api/v1/export/{id}/jira` | Jira-friendly text export | ✅ Bearer + Premium |
| `GET` | `/api/v1/usage` | Plan, aylık limit, kullanım ve kalan hak bilgisi | ✅ Bearer |

### Free / Premium Kuralları

| Özellik | Free | Premium |
|---------|------|---------|
| History liste | Son 15 kayıt | Tüm kayıtlar |
| JSON export | ✅ | ✅ |
| Markdown export | ✅ | ✅ |
| CSV export | ❌ 403 | ✅ |
| Jira export | ❌ 403 | ✅ |
| Free watermark | ✅ | ❌ |

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
│       │   ├── generate.py
│       │   ├── history.py
│       │   └── usage.py
│       ├── services/
│       │   ├── export_service.py
│       │   ├── generation_service.py
│       │   ├── history_service.py
│       │   └── llm_service.py
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
- [ ] Faz 1C — Backend LLM Entegrasyonu (Gemini)
- [ ] Faz 2 — Frontend Web UI
- [ ] Faz 3 — Flutter Mobil Uygulama
- [ ] Faz 4 — Premium Özellikler
- [ ] Faz 5 — Final Polish + Teslim

---

## 👤 Geliştirici

**Emir Buğra Irmak** — 21253061
