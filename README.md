# DriftDater 💕

**A full-stack dating application built with Vue 3 + Flask**

## Team Members & Roles
| Name | Role |
|------|------|
| Bashir | Project Manager / Backend Lead |
| Samara | Frontend Lead |
| Jade | QA / Testing Lead |
| Sheldon | Database / Deployment Lead |

---

## Tech Stack
- **Frontend:** Vue 3, Vue Router 4, Pinia, Axios, Vite
- **Backend:** Flask, Flask-SQLAlchemy, Flask-Migrate, Flask-Login, Flask-CORS
- **Database:** PostgreSQL (SQLite fallback for development)
- **Auth:** Session-based with bcrypt password hashing

---

## Setup Instructions

### Prerequisites
- Python 3.10+
- Node.js 18+
- PostgreSQL (or use SQLite for dev)

### 1. Clone the repository
```bash
git clone https://github.com/your-username/driftdater.git
cd driftdater
```

### 2. Backend Setup
```bash
python -m venv venv
source venv/bin/activate          # Linux/Mac
# .\venv\Scripts\activate         # Windows

pip install -r requirements.txt

cp .env.sample .env
# Edit .env — set SECRET_KEY and DATABASE_URL
```

### 3. Database Setup
```bash
# For PostgreSQL: create the database first
psql -U postgres -c "CREATE DATABASE driftdater;"

flask --app app db init
flask --app app db migrate -m "initial"
flask --app app db upgrade
```

### 4. Start Backend
```bash
flask --app app --debug run --port 8080
# API runs at http://localhost:8080
```

### 5. Frontend Setup (new terminal)
```bash
npm install
npm run dev
# App runs at http://localhost:5173
```

---

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login |
| POST | `/api/v1/auth/logout` | Logout |
| GET  | `/api/v1/auth/me` | Get current user |

### Users & Profiles
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET  | `/api/v1/users/<id>` | Get user profile |
| PUT  | `/api/v1/users/<id>` | Update profile |
| POST | `/api/v1/users/<id>/photos` | Upload photo |
| GET  | `/api/v1/users/<id>/photos` | Get photos |
| DELETE | `/api/v1/users/<id>/photos/<photo_id>` | Delete photo |
| POST | `/api/v1/users/<id>/block` | Block user |
| POST | `/api/v1/users/<id>/report` | Report user |

### Discover & Match
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET  | `/api/v1/discover` | Browse profiles (filtered, scored) |
| POST | `/api/v1/swipe` | Like/Dislike/Pass a profile |
| GET  | `/api/v1/matches` | Get all matches |
| DELETE | `/api/v1/matches/<id>` | Unmatch |
| GET  | `/api/v1/search` | Search profiles |

### Messaging
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET  | `/api/v1/conversations` | List conversations |
| GET  | `/api/v1/conversations/<id>/messages` | Get messages |
| POST | `/api/v1/conversations/<id>/messages` | Send message |

### Other
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET  | `/api/v1/interests` | List all interests |
| GET  | `/api/v1/favorites` | Get saved profiles |
| POST | `/api/v1/favorites/<id>` | Save profile |
| DELETE | `/api/v1/favorites/<id>` | Remove saved |
| GET  | `/api/v1/notifications` | Get notifications |
| PUT  | `/api/v1/notifications/<id>/read` | Mark read |
| PUT  | `/api/v1/notifications/read-all` | Mark all read |

---

## Features

### Core (Mandatory)
- ✅ User registration & login (bcrypt hashed passwords)
- ✅ Detailed profile creation with photo uploads
- ✅ Smart matching algorithm (location, age, interests, relationship goal)
- ✅ Like / Dislike / Pass swipe system
- ✅ Mutual match detection & notifications
- ✅ Messaging between matched users (5s polling)
- ✅ Search & filter by city, age, gender, interests
- ✅ Save/favourite profiles

### Optional (Implemented)
- ✅ Notification system (in-app)
- ✅ Block & report users
- ✅ Profile visibility toggle (public/private)
- ✅ Distance-based discovery with Haversine formula
- ✅ Multi-photo galleries with primary photo selection

---

## Known Issues / Limitations
- Real-time messaging uses 5-second polling (not WebSockets)
- No email verification flow (token is stored but no email provider connected)
- Map integration not yet implemented

---

## Deployment
Recommended platforms: Render, Railway, Heroku
Set environment variables: `SECRET_KEY`, `DATABASE_URL`
