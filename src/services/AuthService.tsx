import React, { createContext, useContext, useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { api } from '../api/client';
const KEY = 'healthshop_token';

type Ctx = {
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
};

const Context = createContext<Ctx>({
  token: null,
  login: async () => { },
  logout: async () => { },
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(null);

  useEffect(() => {
    AsyncStorage.getItem(KEY).then((t) => {
      if (t) {
        setToken(t);
        api.setToken(t);
      }
    });
  }, []);

  const login = async (e: string, p: string) => {
    console.log('login', e, p);
    const r = await api.request<{ token: string }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: e, password: p }),
    });
    console.log('login response', r);
    setToken(r.token);
    api.setToken(r.token);
    await AsyncStorage.setItem(KEY, r.token);
  };

  const logout = async () => {
    setToken(null);
    api.setToken(null);
    await AsyncStorage.removeItem(KEY);
  };
  return <Context.Provider value={{ token, login, logout }}>{children}</Context.Provider>;
}
export const useAuth = () => useContext(Context);
