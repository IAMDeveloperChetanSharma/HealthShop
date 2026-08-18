import React, { useEffect, useState } from 'react';
import { FlatList, View, Text, Button, StyleSheet } from 'react-native';
import { api } from '../api/client';
import { Product } from '../types/models';
import { useNavigation } from '@react-navigation/native';

export default function ProductsScreen() {
  const [items, setItems] = useState<Product[]>([]);
  const nav = useNavigation<any>();

  useEffect(() => {
    api.request<Product[]>('/products').then(setItems).catch(console.error);
  }, []);

  return (
    <FlatList
      contentContainerStyle={s.list}
      data={items}
      keyExtractor={(x) => x.id}
      renderItem={({ item }) => (
        <View style={s.card}>
          <Text style={s.name}>{item.name}</Text>
          <Text>{item.description}</Text>
          <Text style={s.price}>₹{item.price}</Text>
          <Button
            title="View details"
            onPress={() => nav.navigate('ProductDetails', { id: item.id })}
          />
        </View>
      )}
    />
  );
}

const s = StyleSheet.create({
  list: { padding: 16, gap: 12 },
  card: {
    padding: 16,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 12,
    gap: 8,
  },
  name: { fontSize: 18, fontWeight: '700' },
  price: { fontSize: 18, fontWeight: '700' },
});
