import { HealthReading } from '../types/models';
import { saveReading } from '../storage/localDb';
export class MockWearableService {
  connected = false;
  private timer?: ReturnType<typeof setInterval>;
  private listener?: (r: HealthReading) => void;
  connect(listener: (r: HealthReading) => void) {
    this.connected = true;
    this.listener = listener;
    this.emit();
    this.timer = setInterval(() => this.emit(), 5000);
  }
  disconnect() {
    this.connected = false;
    if (this.timer) clearInterval(this.timer);
    this.timer = undefined;
  }
  reconnect(listener: (r: HealthReading) => void) {
    this.disconnect();
    this.connect(listener);
  }
  private async emit() {
    if (!this.connected) return;
    const r: HealthReading = {
      deviceId: 'FITRING-001',
      heartRate: 65 + Math.round(Math.random() * 30),
      spo2: 96 + Math.round(Math.random() * 3),
      steps: 6000 + Math.round(Math.random() * 1500),
      battery: 55 + Math.round(Math.random() * 35),
      timestamp: new Date().toISOString(),
      source: 'mock',
    };
    await saveReading(r);
    this.listener?.(r);
  }
}
