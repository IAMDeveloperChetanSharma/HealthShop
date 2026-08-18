import React, { useEffect, useState } from 'react';
import { ScrollView, View, Text, StyleSheet, Button, Alert } from 'react-native';
import Svg, { Polyline, Line } from 'react-native-svg';
import { listReadings } from '../storage/localDb';
import { readHealthHistory } from '../services/NativeHealthService';
import { HealthReading } from '../types/models';
function Chart({ values }: { values: number[] }) {
  if (values.length < 2) return <Text>No chart data yet</Text>;
  const max = Math.max(...values),
    min = Math.min(...values),
    w = 320,
    h = 100;
  const pts = values
    .map(
      (v, i) => `${(i / (values.length - 1)) * w},${h - ((v - min) / Math.max(1, max - min)) * h}`,
    )
    .join(' ');
  return (
    <Svg width={w} height={h}>
      <Line x1="0" y1="99" x2="320" y2="99" stroke="#bbb" />
      <Polyline points={pts} fill="none" stroke="#222" strokeWidth="2" />
    </Svg>
  );
}
export default function HistoryScreen() {
  const [rows, setRows] = useState<HealthReading[]>([]);
  const load = async () => setRows(await listReadings(200));
  useEffect(() => {
    load();
  }, []);
  const native = async () => {
    try {
      const x = await readHealthHistory(7);
      setRows(x as any);
    } catch (e: any) {
      Alert.alert('Health history', e.message);
    }
  };
  const hrs = rows
    .filter((x) => x.heartRate > 0)
    .slice(0, 30)
    .reverse()
    .map((x) => x.heartRate);
  const ox = rows
    .filter((x) => x.spo2 > 0)
    .slice(0, 30)
    .reverse()
    .map((x) => x.spo2);
  return (
    <ScrollView contentContainerStyle={s.wrap}>
      <Text style={s.title}>History</Text>
      <Button title="Refresh local" onPress={load} />
      <Button title="Read Device health history" onPress={native} />
      <Text style={s.h}>Heart-rate chart</Text>
      <Chart values={hrs} />
      <Text style={s.h}>SpO₂ chart</Text>
      <Chart values={ox} />
      <Text style={s.h}>Weekly summary</Text>
      <Text>
        {rows.length} readings loaded (bounded to 200). Latest steps: {rows[0]?.steps ?? '—'}
      </Text>
      {rows.slice(0, 50).map((x) => (
        <View style={s.item} key={`${x.id}-${x.timestamp}`}>
          <Text>{new Date(x.timestamp).toLocaleString()}</Text>
          <Text>
            {x.heartRate ? `${Math.round(x.heartRate)} BPM` : ''}{' '}
            {x.spo2 ? `${Math.round(x.spo2)}%` : ''} {x.steps ? `${x.steps} steps` : ''} ·{' '}
            {x.source}
          </Text>
        </View>
      ))}
    </ScrollView>
  );
}
const s = StyleSheet.create({
  wrap: { padding: 16, gap: 12 },
  title: { fontSize: 28, fontWeight: '800' },
  h: { fontSize: 20, fontWeight: '700', marginTop: 8 },
  item: { paddingVertical: 8, borderBottomWidth: 1, borderColor: '#eee' },
});
