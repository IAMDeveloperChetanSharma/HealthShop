# Basic Health + Shop RN Application

React Native + Expo application for the Senior Mobile Developer assignment.

## App Video

https://github.com/user-attachments/assets/b37fa369-a1be-4cc3-9f13-78cc445ea6fb

## Tech Stack

- React Native + Expo + TypeScript
- Expo Prebuild
- Android: Kotlin + Health Connect
- iOS: Swift + HealthKit
- Backend: Node.js + Express
- PostgreSQL
- SQLite
- JWT
- Jest

## Features

- Login / logout and authenticated session
- Health dashboard: Heart Rate, SpO₂, Steps, Battery, Connection Status
- Mock wearable with connect/disconnect/reconnect and periodic readings
- Native Android Health Connect integration
- Native iOS HealthKit integration
- Health history with daily/weekly summaries and charts
- Offline SQLite storage
- Sync queue with retry and duplicate prevention
- Product listing and product details
- Cart and quantity management
- Order placement and order history

## Architecture

```text
UI / Screens
    ↓
Services / Use Cases
    ↓
Repositories
    ↓
Local Storage / API
```

Wearable integration:

```text
Mobile App
    ↓
Wearable Service
    ↓
Mock Wearable

Future:
Mobile App → Wearable Service → Native Bridge → Android SDK / iOS SDK
```

The wearable layer is isolated so the mock implementation can be replaced by a real vendor SDK without changing the business/UI layer.

## Native Health Integration

- Android uses native Kotlin Health Connect APIs.
- iOS uses native Swift HealthKit APIs.
- No third-party AVL health library is used for Android.
- Native health functionality is exposed to React Native through the native bridge.

## Backend APIs

```text
POST /auth/login

POST /devices
GET  /devices

POST /health/readings
GET  /health/readings
GET  /health/summary

GET  /products
GET  /products/:id

POST /cart
GET  /cart

POST /orders
GET  /orders
```

## Database

Main tables:

```text
users
devices
health_readings
products
cart_items
orders
order_items
```

## Offline Synchronization

Health readings are stored locally when the device is offline.

```text
Local Data
    ↓
Sync Queue
    ↓
Backend API
```

The sync process supports:

- Pending records
- Automatic retry
- Connectivity-based synchronization
- Duplicate prevention
- Large batches of offline readings

The UI should use bounded/paginated queries and aggregated summaries rather than loading unlimited raw readings.

## Setup

### Mobile

```bash
bun install
bunx expo install --fix
bunx expo-doctor

bunx expo prebuild --clean
```

Run Android:

```bash
bunx expo run:android
```

Run iOS:

```bash
bunx expo run:ios
```

A native development build is required because the project contains Health Connect and HealthKit native code.

### Backend

```bash
cd backend
bun install
```

Configure the required values in `.env` using `.env.example`.

Run:

```bash
bun run dev
```

## Testing

```bash
bun test
bun run typecheck
```

## Important Design Decisions

- SQLite provides local persistence for offline health collection.
- Health records are queued for synchronization when offline.
- Synchronization is designed to be idempotent to prevent duplicate records.
- Native health APIs are isolated behind a service/bridge layer.
- The mock wearable can be replaced by a real wearable SDK with minimal changes.
- The implementation prioritizes architecture, reliability, offline handling, backend integration, and testable business logic over advanced UI polish.
