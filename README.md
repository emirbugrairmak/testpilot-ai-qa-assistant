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
| **LLM** | Google Gemini API |
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

## 📁 Proje Yapısı

```
TestPilot – AI QA Assistant/
├── docker-compose.yml
├── backend/               ← Python / FastAPI
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
│       ├── main.py
│       └── config.py
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
- [ ] Faz 1 — Backend Core (Auth, DB, LLM, API)
- [ ] Faz 2 — Frontend Web UI
- [ ] Faz 3 — Flutter Mobil Uygulama
- [ ] Faz 4 — Premium Özellikler
- [ ] Faz 5 — Final Polish + Teslim

---

## 👤 Geliştirici

**Emir Buğra Irmak** — 21253061
