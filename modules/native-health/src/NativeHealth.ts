import { requireNativeModule } from 'expo-modules-core';

export type NativeReading = {
  deviceId: string;
  heartRate: number;
  spo2: number;
  steps: number;
  timestamp: string;
  source: 'healthkit' | 'healthconnect';
};

const NativeHealthModule = requireNativeModule<{
  requestPermissions: () => Promise<boolean>;
  readLatest: () => Promise<NativeReading | null>;
  readHistory: (days: number) => Promise<NativeReading[]>;
}>('NativeHealth');

export const requestPermissions = NativeHealthModule.requestPermissions;
export const readLatest = NativeHealthModule.readLatest;
export const readHistory = NativeHealthModule.readHistory;
