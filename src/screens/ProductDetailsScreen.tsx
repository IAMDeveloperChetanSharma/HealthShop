import React, { useEffect, useState } from 'react';
import { View, Text, Button, StyleSheet, Alert } from 'react-native';
import { api } from '../api/client';
import { Product } from '../types/models';
import { useRoute } from '@react-navigation/native';
export default function ProductDetailsScreen() {
  const { params } = useRoute<any>();
  const [p, setP] = useState<Product | null>(null);
  useEffect(() => {
    api.request<Product>(`/products/${params.id}`).then(setP).catch(console.error);
  }, [params.id]);
  if (!p)
    return (
      <View style={s.wrap}>
        <Text>Loading…</Text>
      </View>
    );
  return (
    <View style={s.wrap}>
      <Text style={s.name}>{p.name}</Text>
      <Text>{p.description}</Text>
      <Text style={s.price}>₹{p.price}</Text>
      <Button
        title="Add to Cart"
        onPress={() =>
          api
            .request('/cart', {
              method: 'POST',
              body: JSON.stringify({ productId: p.id, quantity: 1 }),
            })
            .then(() => Alert.alert('Cart', 'Added'))
            .catch((e) => Alert.alert('Cart', e.message))
        }
      />
    </View>
  );
}
const s = StyleSheet.create({
  wrap: { padding: 20, gap: 18 },
  name: { fontSize: 28, fontWeight: '800' },
  price: { fontSize: 22, fontWeight: '700' },
});
