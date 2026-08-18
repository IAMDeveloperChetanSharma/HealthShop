import React, { useEffect, useRef, useState } from 'react';
import { View, Text, Button, StyleSheet, Alert, ScrollView } from 'react-native';
import { useAuth } from '../services/AuthService';
import { MockWearableService } from '../services/MockWearableService';
import { HealthReading } from '../types/models';
import {
  requestHealthPermissions,
  readLatestHealth,
  healthPlatform,
  isNativeHealthAvailable,
} from '../services/NativeHealthService';
import { syncPending } from '../services/SyncService';
import { api } from '../api/client';

const defaultReading: HealthReading = {
  deviceId: 'FITRING-001',
  heartRate: 0,
  spo2: 0,
  steps: 0,
  battery: 0,
  timestamp: new Date().toISOString(),
  source: 'mock',
};

const NATIVE_POLL_MS = 5000;

export default function DashboardScreen() {
  const { logout } = useAuth();
  const [r, setR] = useState<HealthReading>(defaultReading);
  const [connected, setConnected] = useState(true);
  const svc = useRef(new MockWearableService()).current;

  const loadLatestReading = async () => {
    try {
      const latest = await readLatestHealth();
      if (latest) setR(latest);
    } catch (error) {
      console.warn('Unable to load latest reading:', error);
    }
  };

  useEffect(() => {
    let pollTimer: ReturnType<typeof setInterval> | undefined;

    const start = async () => {
      if (isNativeHealthAvailable()) {
        // Real device available: pull actual HealthKit/Health Connect data
        // instead of the mock generator, then keep it fresh + synced.
        await requestHealthPermissions();
        await loadLatestReading();
        await syncPending();
        pollTimer = setInterval(async () => {
          await loadLatestReading();
          await syncPending();
        }, NATIVE_POLL_MS);
      } else {
        // No native module (e.g. Expo Go / simulator without health APIs):
        // fall back to the mock wearable so the app remains usable.
        void loadLatestReading();
        svc.connect(setR);
        void syncPending();
      }
    };

    void start();

    return () => {
      if (pollTimer) clearInterval(pollTimer);
      svc.disconnect();
    };
  }, []);

  const importHealth = async () => {
    try {
      const ok = await requestHealthPermissions();
      if (!ok) {
        Alert.alert(
          'Health permission',
          'Please grant HealthKit/Health Connect permissions in system settings.',
        );
        return;
      }
      const latest = await readLatestHealth();
      if (latest) setR(latest);
      await syncPending();
    } catch (e: any) {
      Alert.alert('Health API', e.message);
    }
  };

  const sync = async () => {
    const x = await syncPending();
    Alert.alert('Sync', x.offline ? 'Offline - queued locally' : `${x.synced} readings synced`);
  };

  return (
    <ScrollView contentContainerStyle={s.wrap}>
      <View style={s.row}>
        <Text style={s.title}>Dashboard</Text>
        <Button title="Logout" onPress={logout} />
      </View>
      <Text style={s.source}>
        Source: {r.source} · {healthPlatform}
      </Text>
      <View style={s.grid}>
        {[
          ['Heart Rate', r.heartRate ? `${Math.round(r.heartRate)} BPM` : '—'],
          ['SpO₂', r.spo2 ? `${Math.round(r.spo2)}%` : '—'],
          ['Steps', r.steps ? String(r.steps) : '—'],
          ['Battery', r.battery !== undefined ? `${Math.round(r.battery)}%` : '—'],
          ['Device', connected ? 'Connected' : 'Disconnected'],
          ['Sync', 'Offline-safe'],
        ].map(([a, b]) => (
          <View style={s.card} key={a}>
            <Text style={s.label}>{a}</Text>
            <Text style={s.value}>{b}</Text>
          </View>
        ))}
      </View>
      <View style={s.actions}>
        <Button
          title={connected ? 'Disconnect' : 'Reconnect'}
          onPress={() => {
            if (connected) {
              svc.disconnect();
              setConnected(false);
            } else {
              svc.reconnect(setR);
              setConnected(true);
            }
          }}
        />
        <Button title="Read HealthKit / Health Connect" onPress={importHealth} />
        <Button title="Sync pending readings" onPress={sync} />

      </View>
    </ScrollView>
  );
}
const s = StyleSheet.create({
  wrap: { padding: 16, gap: 16 },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  title: { fontSize: 28, fontWeight: '800' },
  source: { color: '#666' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  card: {
    width: '47%',
    padding: 16,
    borderRadius: 14,
    backgroundColor: '#f5f5f5',
  },
  label: { color: '#666' },
  value: { fontSize: 22, fontWeight: '700', marginTop: 8 },
  actions: { gap: 12 },
});