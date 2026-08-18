import * as SQLite from 'expo-sqlite';
import { HealthReading } from '../types/models';
let db: SQLite.SQLiteDatabase | null = null;
async function getDb() {
  if (!db) db = await SQLite.openDatabaseAsync('healthshop.db');
  await db.execAsync(
    `CREATE TABLE IF NOT EXISTS health_readings (id TEXT PRIMARY KEY, device_id TEXT NOT NULL, heart_rate REAL NOT NULL, spo2 REAL NOT NULL, steps INTEGER NOT NULL, battery REAL, timestamp TEXT NOT NULL, source TEXT NOT NULL, synced INTEGER NOT NULL DEFAULT 0); CREATE INDEX IF NOT EXISTS idx_health_timestamp ON health_readings(timestamp); CREATE TABLE IF NOT EXISTS sync_queue (reading_id TEXT PRIMARY KEY, attempts INTEGER NOT NULL DEFAULT 0, last_error TEXT);`,
  );
  return db;
}
export async function saveReading(r: HealthReading) {
  const d = await getDb();
  const id = r.id || `${r.deviceId}-${r.timestamp}`;
  await d.runAsync(
    `INSERT OR IGNORE INTO health_readings(id,device_id,heart_rate,spo2,steps,battery,timestamp,source,synced) VALUES(?,?,?,?,?,?,?,?,0)`,
    id,
    r.deviceId,
    r.heartRate,
    r.spo2,
    r.steps,
    r.battery ?? null,
    r.timestamp,
    r.source || 'mock',
  );
  await d.runAsync(`INSERT OR IGNORE INTO sync_queue(reading_id) VALUES(?)`, id);
}
export async function listReadings(limit = 200) {
  const d = await getDb();
  return d.getAllAsync<any>(
    `SELECT id,device_id as deviceId,heart_rate as heartRate,spo2,steps,battery,timestamp,source,synced FROM health_readings ORDER BY timestamp DESC LIMIT ?`,
    limit,
  ) as Promise<HealthReading[]>;
}
export async function pendingReadings(limit = 50) {
  const d = await getDb();
  return d.getAllAsync<any>(
    `SELECT h.* FROM health_readings h JOIN sync_queue q ON q.reading_id=h.id WHERE h.synced=0 ORDER BY h.timestamp ASC LIMIT ?`,
    limit,
  ) as Promise<HealthReading[]>;
}
export async function markSynced(ids: string[]) {
  if (!ids.length) return;
  const d = await getDb();
  for (const id of ids) {
    await d.runAsync(`UPDATE health_readings SET synced=1 WHERE id=?`, id);
    await d.runAsync(`DELETE FROM sync_queue WHERE reading_id=?`, id);
  }
}
