import NetInfo from '@react-native-community/netinfo';
import { api } from '../api/client';
import { pendingReadings, markSynced } from '../storage/localDb';
export async function syncPending() {
  const state = await NetInfo.fetch();
  if (!state.isConnected) return { synced: 0, offline: true };
  const pending = await pendingReadings(50);
  if (!pending.length) return { synced: 0, offline: false };
  try {
    await api.request('/health/readings', {
      method: 'POST',
      body: JSON.stringify({ readings: pending }),
    });
    await markSynced(pending.map((r) => r.id!));
    return { synced: pending.length, offline: false };
  } catch {
    return { synced: 0, offline: false };
  }
}
export function subscribeSync() {
  return NetInfo.addEventListener((s) => {
    if (s.isConnected) syncPending();
  });
}
