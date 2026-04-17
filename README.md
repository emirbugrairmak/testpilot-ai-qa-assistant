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

---

## 📡 API Endpoint'leri

| Method | Endpoint | Açıklama | Auth |
|--------|----------|----------|------|
| `GET` | `/health` | Servis sağlık kontrolü | ❌ |
| `GET` | `/docs` | Swagger API dokümantasyonu | ❌ |
| `POST` | `/api/v1/auth/validate` | API key doğrulama + plan bilgisi | ✅ Bearer |
| `POST` | `/api/v1/generate` | Test üretimi (Mod A / Mod B) | ✅ Bearer |

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
│       │   └── generate.py
│       ├── services/
│       │   ├── generation_service.py
│       │   └── llm_service.py
│       ├── prompts/
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
- [ ] Faz 1B — Backend LLM Entegrasyonu (Gemini)
- [ ] Faz 2 — Frontend Web UI
- [ ] Faz 3 — Flutter Mobil Uygulama
- [ ] Faz 4 — Premium Özellikler
- [ ] Faz 5 — Final Polish + Teslim

---

## 👤 Geliştirici

**Emir Buğra Irmak** — 21253061
