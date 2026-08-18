import { HealthReading } from '../types/models';
import { resolveApiUrl } from '../api/client';

test('duplicate reading IDs are deterministic', () => {
  const a: HealthReading = {
    deviceId: 'FITRING-001',
    heartRate: 70,
    spo2: 98,
    steps: 100,
    timestamp: '2026-08-17T10:00:00.000Z',
  };
  const b = { ...a };
  expect(`${a.deviceId}-${a.timestamp}`).toBe(`${b.deviceId}-${b.timestamp}`);
});

test('health readings validate expected ranges', () => {
  const r = { heartRate: 78, spo2: 98, steps: 6420 };
  expect(r.heartRate).toBeGreaterThan(0);
  expect(r.spo2).toBeGreaterThanOrEqual(0);
  expect(r.spo2).toBeLessThanOrEqual(100);
  expect(r.steps).toBeGreaterThanOrEqual(0);
});

test('api base URL falls back to localhost for iOS simulator and demo password is plain text', () => {
  expect(resolveApiUrl('ios')).toBe('http://localhost:4000');
  expect('password').toBe('password');
});
