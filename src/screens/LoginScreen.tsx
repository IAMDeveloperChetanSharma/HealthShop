import React, { useState } from 'react';
import { View, Text, TextInput, Button, StyleSheet, Alert, ActivityIndicator } from 'react-native';
import { useAuth } from '../services/AuthService';

export default function LoginScreen() {
  const [email, setEmail] = useState('demo@healthshop.dev');
  const [password, setPassword] = useState('password');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();

  async function onPress() {
    try {
      setLoading(true);
      await login(email, password);
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Unknown error';
      Alert.alert('Login failed', message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <View style={s.container}>
      <ActivityIndicator size="large" color="#0000ff" animating={loading} />
      <Text style={s.title}>HealthShop</Text>
      <Text style={s.subtitle}>Wearable health + shopping assignment</Text>
      <TextInput
        value={email}
        onChangeText={setEmail}
        autoCapitalize="none"
        placeholder="Email"
        style={s.input}
      />
      <TextInput
        value={password}
        onChangeText={setPassword}
        secureTextEntry
        placeholder="Password"
        style={s.input}
      />
      <Button title="Login" disabled={loading} onPress={onPress} />
      <Text style={s.hint}>Demo: demo@healthshop.dev / password</Text>
    </View>
  );
}
const s = StyleSheet.create({
  hint: { color: '#666', marginTop: 8, fontSize: 12 },
  container: { flex: 1, padding: 24, justifyContent: 'center', gap: 14 },
  title: { fontSize: 32, fontWeight: '800' },
  subtitle: { color: '#666', marginBottom: 20 },
  input: { borderWidth: 1, borderColor: '#ddd', borderRadius: 10, padding: 12 },
});
