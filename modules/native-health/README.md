# NativeHealth local Expo module

- Android: Kotlin + AndroidX Health Connect, no third-party health wrapper. Reads HeartRateRecord, OxygenSaturationRecord and StepsRecord.
- iOS: Swift + Apple HealthKit. Reads heart rate, oxygen saturation and step count.
- JS uses `requireNativeModule('NativeHealth')` so the application is insulated from platform details.

Health Connect permission UI is platform-owned. The current module checks grants; when permissions are missing, grant them from the Health Connect app before reading data. The official Android API uses PermissionController for the user consent screen.
