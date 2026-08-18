import { Platform } from 'react-native';
import { HealthReading } from '../types/models';
import { listReadings, saveReading } from '../storage/localDb';

let nativeModule: any = null;
let isNativeAvailable = false;

// Try to load native module, fall back to local DB/mock if not available
try {
  const NativeHealth = require('../../modules/native-health/src/NativeHealth');
  nativeModule = NativeHealth;
  isNativeAvailable = true;
} catch (error) {
  console.warn('Native health module not available, using saved local data:', error);
  isNativeAvailable = false;
}

export function isNativeHealthAvailable() {
  return isNativeAvailable;
}

export async function requestHealthPermissions() {
  if (isNativeAvailable && nativeModule?.requestPermissions) {
    return nativeModule.requestPermissions();
  }
  return true;
}

// Native HealthKit/Health Connect often emits partial updates (e.g. only
// heartRate changed since the last callback). Cache the last full reading
// so a partial update doesn't blank out the other metrics on screen.
let lastKnownReading: HealthReading | null = null;

async function getLastKnownReading(): Promise<HealthReading | null> {
  if (lastKnownReading) return lastKnownReading;
  const rows = await listReadings(1);
  lastKnownReading = rows[0] ?? null;
  return lastKnownReading;
}

export async function readLatestHealth(): Promise<HealthReading | null> {
  if (isNativeAvailable && nativeModule?.readLatest) {
    const reading = await nativeModule.readLatest();
    if (reading) {
      const previous = await getLastKnownReading();
      // Merge: only overwrite fields the native module actually sent this time.
      // Note: the native module sends 0 (not null/undefined) for metrics it
      // didn't refresh this tick, and 0 is never a real heartRate/spo2/steps/
      // battery value while a device is connected, so treat falsy as "no
      // update" (||) rather than only null/undefined (??).
      const merged: HealthReading = {
        deviceId: reading.deviceId || previous?.deviceId || 'NATIVE',
        heartRate: reading.heartRate || previous?.heartRate || 0,
        spo2: reading.spo2 || previous?.spo2 || 0,
        steps: reading.steps || previous?.steps || 0,
        battery: reading.battery || previous?.battery,
        timestamp: reading.timestamp || new Date().toISOString(),
        source: reading.source || (Platform.OS === 'ios' ? 'healthkit' : 'healthconnect'),
      };
      await saveReading(merged);
      lastKnownReading = merged;
      return merged;
    }
    return null;
  }

  const rows = await listReadings(1);
  return rows[0] ?? null;
}

export async function readHealthHistory(days = 7): Promise<HealthReading[]> {
  if (isNativeAvailable && nativeModule?.readHistory) {
    return nativeModule.readHistory(days);
  }

  return listReadings(200);
}

export const healthPlatform = Platform.OS;
