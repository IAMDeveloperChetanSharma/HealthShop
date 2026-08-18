import { Platform } from 'react-native';

export function resolveApiUrl(platform: 'ios' | 'android'): string {
  if (process.env.EXPO_PUBLIC_API_URL) return process.env.EXPO_PUBLIC_API_URL;
  if (platform === 'android') return 'http://10.0.2.2:4000';
  return 'http://localhost:4000';
}

const API_URL = resolveApiUrl(Platform.OS === 'ios' ? 'ios' : 'android');
let token: string | null = null;

export const api = {
  setToken(t: string | null) {
    token = t;
  },
  async request<T>(path: string, options: RequestInit = {}): Promise<T> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...((options.headers as Record<string, string>) || {}),
    };
    if (token) headers.Authorization = `Bearer ${token}`;
    const response = await fetch(`${API_URL}${path}`, { ...options, headers });
    if (!response.ok) {
      const text = await response.text();
      throw new Error(text || `HTTP ${response.status}`);
    }
    return response.json();
  },
};
