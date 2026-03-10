# 👗 Style Consultant AI

Un'app Flutter che funge da consulente di stile personale alimentato da AI. Ogni giorno suggerisce outfit in base al meteo, alla temperatura e all'occasione.

---

## 🏗️ Architettura

```
style-consultant/
├── docker-compose.yml          # Orchestrazione servizi
├── .env.example                # Template variabili d'ambiente
├── backend/                    # FastAPI + Python
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
│       ├── main.py             # Entry point FastAPI
│       ├── config.py           # Configurazione (env vars)
│       ├── database.py         # SQLAlchemy async + PostgreSQL
│       ├── models.py           # Modelli DB (clothing, outfit, events)
│       ├── schemas.py          # Pydantic schemas (request/response)
│       ├── routers/
│       │   ├── clothes.py      # Upload, lista, elimina capi
│       │   ├── outfits.py      # Genera, like/dislike, lista outfit
│       │   ├── weather.py      # Meteo via OpenWeatherMap
│       │   └── events.py       # Calendario in-app
│       └── services/
│           ├── ai_service.py   # Claude AI: analisi immagini + outfit
│           └── weather_service.py
└── flutter_app/
    └── lib/
        ├── main.dart           # Entry point + navigazione PageView
        ├── config/
        │   ├── api_config.dart # URL backend
        │   └── app_theme.dart  # Tema dark personalizzato
        ├── models/             # clothing.dart, outfit.dart, weather.dart
        ├── services/
        │   ├── api_service.dart    # Tutte le chiamate HTTP al backend
        │   ├── location_service.dart
        │   └── user_service.dart   # UUID locale utente
        ├── pages/
        │   ├── home_page.dart      # Meteo + outfit salvati + genera
        │   ├── wardrobe_page.dart  # Dashboard + griglia capi
        │   ├── account_page.dart   # Placeholder account
        │   └── add_event_sheet.dart # Calendario in-app
        └── widgets/
            ├── outfit_card.dart    # Card outfit con immagini stacked
            ├── clothing_card.dart  # Card capo con eliminazione
            └── weather_widget.dart # Widget meteo dettagliato
```

---

## 🚀 Setup Backend (Docker)

### 1. Prerequisiti
- Docker + Docker Compose
- API key Anthropic: https://console.anthropic.com
- API key OpenWeatherMap (gratuita): https://openweathermap.org/api

### 2. Configurazione
```bash
cd style-consultant
cp .env.example .env
# Modifica .env con le tue API key
```

### 3. Avvio
```bash
docker-compose up -d
```

Il backend sarà disponibile su `http://localhost:8000`

### 4. Verifica
```bash
curl http://localhost:8000/health
# {"status":"ok"}
```

### 5. Documentazione API
Apri `http://localhost:8000/docs` per Swagger UI.

---

## 📱 Setup Flutter App

### 1. Prerequisiti
```bash
flutter --version  # Richiede Flutter 3.19+
```

### 2. Installa dipendenze
```bash
cd flutter_app
flutter pub get
```

### 3. Configura l'URL del backend

Modifica `lib/config/api_config.dart`:

```dart
// Per emulatore Android:
static const String _host = '10.0.2.2';

// Per simulatore iOS:
static const String _host = 'localhost';

// Per dispositivo fisico (sostituisci con IP del tuo PC):
static const String _host = '192.168.1.100';
```

### 4. Avvio su emulatore/dispositivo
```bash
flutter run
```

---

## 📐 Funzionamento

### Navigazione
L'app usa un `PageView` con swipe orizzontale:
- **← Sinistra**: Armadio (gestione capi)
- **● Centro**: Home (meteo + outfit del giorno)
- **→ Destra**: Account (coming soon)

### Flusso principale

1. **Aggiunta capo**: Utente fotografa → Backend salva immagine → Claude analizza (categoria, colore, materiale, temp) → Salvato in DB

2. **Generazione outfit**: 
   - Recupera meteo attuale (GPS → OpenWeatherMap)
   - Legge occasione da calendario (o scelta manuale)
   - Invia armadio + contesto a Claude
   - Claude seleziona la combinazione ottimale (evitando i disliked)
   - Mostra outfit con immagini stacked + spiegazione AI

3. **Like/Dislike**:
   - ❤️ Like: outfit salvato, riproposto in condizioni simili
   - 👎 Dislike: combinazione esatta mai più proposta

---

## 🗃️ Schema Database

```
clothing_items     → capi dell'armadio
outfits            → outfit generati
outfit_items       → join table outfit ↔ capi (con layer_order)
calendar_events    → eventi/occasioni dell'utente
```

---

## 🔑 Variabili d'ambiente

| Variabile | Descrizione |
|-----------|-------------|
| `ANTHROPIC_API_KEY` | Key Claude API (analisi + generazione) |
| `OPENWEATHER_API_KEY` | Key OpenWeatherMap (gratuita) |
| `POSTGRES_USER` | Username PostgreSQL |
| `POSTGRES_PASSWORD` | Password PostgreSQL |
| `POSTGRES_DB` | Nome database |

---

## 🛠️ Comandi utili

```bash
# Logs backend
docker-compose logs -f backend

# Restart solo backend (dopo modifiche)
docker-compose restart backend

# Accesso al DB
docker-compose exec postgres psql -U style_user -d style_db

# Rebuild completo
docker-compose down && docker-compose up --build -d
```

---

## 🔮 Roadmap Account

La pagina account (TODO) prevederà:
- Registrazione/login con email
- Sincronizzazione armadio multi-dispositivo
- Preferenze di stile personali
- Statistiche outfit
- Condivisione outfit sui social
