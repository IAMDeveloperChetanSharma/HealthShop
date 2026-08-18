import React, { useEffect, useState } from 'react';
import { FlatList, View, Text, StyleSheet } from 'react-native';
import { api } from '../api/client';
import { Order } from '../types/models';
export default function OrdersScreen() {
  const [orders, setOrders] = useState<Order[]>([]);
  useEffect(() => {
    api.request<Order[]>('/orders').then(setOrders);
  }, []);
  return (
    <FlatList
      contentContainerStyle={s.list}
      data={orders}
      keyExtractor={(x) => x.id}
      renderItem={({ item }) => (
        <View style={s.item}>
          <Text style={s.id}>Order {item.id}</Text>
          <Text>
            ₹{item.total} · {item.status}
          </Text>
          <Text>{new Date(item.createdAt).toLocaleString()}</Text>
        </View>
      )}
    />
  );
}
const s = StyleSheet.create({
  list: { padding: 16, gap: 12 },
  item: { padding: 16, borderWidth: 1, borderColor: '#ddd', borderRadius: 12 },
  id: { fontWeight: '700' },
});
