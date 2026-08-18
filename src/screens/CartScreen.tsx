import React, { useCallback, useState } from 'react';
import { View, Text, Button, StyleSheet, Alert, ScrollView } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../api/client';
import { CartItem } from '../types/models';
export default function CartScreen() {
  const [items, setItems] = useState<CartItem[]>([]);
  const load = () => api.request<CartItem[]>('/cart').then(setItems).catch((e) => Alert.alert('Cart', e.message));

  useFocusEffect(
    useCallback(() => {
      load();
    }, []),
  );

  const order = () =>
    api
      .request('/orders', { method: 'POST' })
      .then(() => {
        Alert.alert('Order', 'Order created');
        load();
      })
      .catch((e) => Alert.alert('Order', e.message));
  return (
    <ScrollView contentContainerStyle={s.wrap}>
      <Text style={s.title}>Cart</Text>
      {items.map((x) => (
        <View style={s.item} key={x.id}>
          <Text>{x.name}</Text>
          <Text>
            {x.quantity} × ₹{x.price}
          </Text>
        </View>
      ))}
      <Button title="Place Order" disabled={!items.length} onPress={order} />
    </ScrollView>
  );
}
const s = StyleSheet.create({
  wrap: { padding: 16, gap: 12 },
  title: { fontSize: 28, fontWeight: '800' },
  item: { padding: 14, borderWidth: 1, borderColor: '#ddd', borderRadius: 10 },
});