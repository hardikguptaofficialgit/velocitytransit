# VelocityTransit Backend

Node.js + Firebase + Socket.io backend for real-time bus tracking.

## Quick Setup

### 1. Firebase Project Setup
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project (or use existing)
3. Enable **Authentication** → Email/Password + Google Sign-In
4. Enable **Firestore Database** (start in test mode for hackathon)
5. Go to **Project Settings** → **Service Accounts** → **Generate new private key**
6. Save the downloaded JSON file as `firebase-service-account.json` in this folder

### 2. Environment
The `.env` file is already created. Just ensure:
```
PORT=4000
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
CORS_ORIGIN=http://localhost:5173
```

### 3. Run
```bash
npm install
npm run dev    # with hot-reload (nodemon)
# or
npm start      # production
```

### 4. Test
```
GET http://localhost:4000/api/health
```

## API Endpoints

| Method | Path | Auth | Role | Description |
|--------|------|------|------|-------------|
| POST | `/api/auth/register` | Token | Any | Create user profile |
| GET | `/api/auth/me` | Token | Any | Get current user |
| GET | `/api/users` | Token | Admin | List users |
| PATCH | `/api/users/:uid/role` | Token | Admin | Change user role |
| GET | `/api/buses` | Token | Any | List buses |
| POST | `/api/buses` | Token | Admin | Create bus |
| GET | `/api/routes` | Token | Any | List routes |
| POST | `/api/routes` | Token | Admin | Create route |
| GET | `/api/assignments/active` | Token | Any | Active assignments |
| POST | `/api/assignments` | Token | Admin | Assign bus → driver |
| PATCH | `/api/assignments/:id/deactivate` | Token | Admin | Stop tracking |
| GET | `/api/tracking/live` | Token | Any | All live positions |

## Socket.io Events
- `driver:start` → Driver initiates tracking
- `driver:location` → `{ lat, lng, speed, heading }`
- `bus:position` → Broadcast to passengers
- `bus:offline` → Bus tracking stopped
- `get:live` → Request all live positions
