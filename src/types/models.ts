export type HealthReading = {
  id?: string;
  deviceId: string;
  heartRate: number;
  spo2: number;
  steps: number;
  battery?: number;
  timestamp: string;
  source?: 'mock' | 'healthkit' | 'healthconnect';
  synced?: boolean;
};
export type Product = {
  id: string;
  name: string;
  description: string;
  price: number;
  imageUrl?: string;
  stock: number;
};
export type CartItem = {
  id: string;
  productId: string;
  name: string;
  price: number;
  quantity: number;
};
export type Order = {
  id: string;
  total: number;
  status: string;
  createdAt: string;
  items: CartItem[];
};
