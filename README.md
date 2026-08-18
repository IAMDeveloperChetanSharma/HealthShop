# HealthShop — React Native + Expo Take-Home

This repository implements the attached ERBrains Senior Mobile Developer assignment in React Native/Expo instead of Flutter, while retaining the requested Node.js + PostgreSQL backend APIs and relational model. The assignment asks for authentication, a simulated wearable, local history, offline synchronization, backend APIs, PostgreSQL, shopping, error handling, tests and a technical README. fileciteturn0file0L13-L25

## Key implementation decisions

- Expo SDK 57 + React Native 0.83, TypeScript, New Architecture.
- The project is configured for `npx expo prebuild --clean`; the ZIP contains `android/` and `ios/` placeholders plus all native-module/config-plugin source. The build container could not execute Expo Prebuild because npm registry access timed out, so regenerate the two platform projects locally after `npm install`.
- Native health bridge: Android is Kotlin using AndroidX Health Connect directly; iOS is Swift using Apple HealthKit directly. No Android health wrapper is used.
- Mock wearable remains the fallback/demo device because the assignment explicitly asks for a vendor-SDK-independent mock layer and an architecture that can later swap in a real SDK. fileciteturn0file0L52-L79
- Local SQLite is bounded in UI reads; the sync queue uses deterministic IDs to prevent duplicate uploads.
- Backend uses Express + PostgreSQL + JWT. Required API surface is implemented. fileciteturn0file0L132-L158
- Shopping flow: Products → Details → Cart → Order → Order History. fileciteturn0file0L159-L167

## Important health-platform note

Android Health Connect permissions are user-controlled. The native bridge checks existing grants and reads `HeartRateRecord`, `OxygenSaturationRecord`, and `StepsRecord`. Android's current Health Connect documentation lists those read permissions and record types. citeturn1search4turn1search16

iOS HealthKit reads heart rate, oxygen saturation, and step count using Apple's native `HKQuantityTypeIdentifier` types. citeturn1search2turn1search1turn1search0

## Setup

### 1. Backend

```bash
cd backend
cp .env.example .env
npm install
# Create a PostgreSQL database named healthshop.
psql "$DATABASE_URL" -f sql/schema.sql
npm run seed
npm run dev
```

### 2. Mobile

```bash
npm install
# Set your API URL. Android emulator uses http://10.0.2.2:4000 by default.
# For a physical device set EXPO_PUBLIC_API_URL=http://YOUR_LAN_IP:4000
npx expo prebuild --clean
npx expo run:android
# macOS + Xcode:
npx expo run:ios
```

Expo's current documentation recommends prebuild for generating the native Android/iOS projects and supports local Expo modules written in Kotlin/Swift. citeturn0search3turn0search4

## Demo credentials

- Email: `demo@healthshop.dev`
- Password: `password`

## Offline synchronization

1. Every mock reading is immediately inserted into SQLite.
2. A sync queue row is inserted with the same deterministic reading ID.
3. If connectivity is unavailable, nothing is lost.
4. When connectivity returns, `POST /health/readings` uploads the pending batch.
5. PostgreSQL uses a uniqueness constraint and `ON CONFLICT DO NOTHING` to prevent duplicates.
6. UI history is bounded to 200 local records and renders at most 50 rows at once. This addresses the assignment's large-volume requirement. fileciteturn0file0L104-L131

## Reconnection strategy

The mock service exposes connect/disconnect/reconnect. Network reconnection is event-driven through NetInfo and triggers a sync attempt. Failed API syncs remain pending for the next connectivity event/manual sync. For a production wearable implementation, I would use exponential backoff with jitter and a maximum retry budget.

## Real wearable replacement

The JS application depends on a wearable/health service boundary rather than a vendor SDK. The current native health bridge is a separate module. A real ring SDK can be introduced behind the same service contract, with Android Kotlin and iOS Swift adapters. This is aligned with the assignment's requested separation between application, service/interface and implementation. fileciteturn0file0L71-L95

## API

- `POST /auth/login`
- `POST /devices`
- `GET /devices`
- `POST /health/readings`
- `GET /health/readings`
- `GET /health/summary`
- `GET /products`
- `GET /products/:id`
- `POST /cart`
- `GET /cart`
- `POST /orders`
- `GET /orders`

## Testing

Run `npm test`. Tests cover deterministic duplicate IDs and health reading validation. The assignment specifically asks for meaningful automated tests around health processing, synchronization/duplicate prevention, or cart/order logic. fileciteturn0file0L178-L181

## Build / walkthrough

Because native Health Connect and HealthKit require real platform SDKs and user permissions, the ZIP includes source native projects but does not include a fabricated APK/iOS archive. The assignment itself calls for APK and iOS build/TestFlight as submission deliverables. fileciteturn0file0L182-L195

On a Mac with Xcode, run `npx expo run:ios`; Android Studio/SDK is required for Android. Expo documents `npx expo run:android` and `npx expo run:ios` for local native compilation. citeturn0search2
