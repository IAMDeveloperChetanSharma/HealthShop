import express from 'express';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { pool } from './db/pool';
import { auth, AuthRequest } from './middleware/auth';
import dotenv from 'dotenv';
dotenv.config();
const app = express();
app.use(cors());
app.use(express.json({ limit: '1mb' }));
const sign = (userId: string) =>
  jwt.sign({ userId }, process.env.JWT_SECRET || 'change-me', {
    expiresIn: '7d',
  });

app.get('/health', (_, res) => res.json({ ok: true }));

app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = z
      .object({ email: z.string().email(), password: z.string().min(1) })
      .parse(req.body);
    const u = await pool.query('SELECT * FROM users WHERE email=$1', [email]);
    if (!u.rowCount) return res.status(401).json({ message: 'Invalid credentials' });
    if (!(await bcrypt.compare(password, u.rows[0].password_hash)))
      return res.status(401).json({ message: 'Invalid credentials' });
    res.json({
      token: sign(u.rows[0].id),
      user: { id: u.rows[0].id, email: u.rows[0].email },
    });
  } catch (e) {
    console.error('login error:', e);
    const message = e instanceof Error ? e.message : 'Bad request';
    res.status(500).json({ message });
  }
});
app.use(auth);

app.post('/devices', async (req: AuthRequest, res) => {
  const { deviceId, name } = z.object({ deviceId: z.string(), name: z.string() }).parse(req.body);
  const r = await pool.query(
    'INSERT INTO devices(id,user_id,name) VALUES($1,$2,$3) ON CONFLICT(id) DO UPDATE SET name=EXCLUDED.name RETURNING *',
    [deviceId, req.userId, name],
  );
  res.json(r.rows[0]);
});

app.get('/devices', async (req: AuthRequest, res) =>
  res.json((await pool.query('SELECT * FROM devices WHERE user_id=$1', [req.userId])).rows),
);

app.post('/health/readings', async (req: AuthRequest, res) => {
  const payload = Array.isArray(req.body?.readings) ? req.body.readings : [];
  const rows = z
    .array(
      z.object({
        id: z.string().optional(),
        deviceId: z.string(),
        heartRate: z.number(),
        spo2: z.number(),
        steps: z.number(),
        battery: z.number().optional(),
        timestamp: z.string(),
        source: z.string().optional(),
      }),
    )
    .parse(payload.slice(0, 50));
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const x of rows) {
      await client.query(
        `INSERT INTO health_readings(id,user_id,device_id,heart_rate,spo2,steps,battery,timestamp,source) VALUES(COALESCE($1,gen_random_uuid()),$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT(id) DO NOTHING`,
        [
          x.id || null,
          req.userId,
          x.deviceId,
          x.heartRate,
          x.spo2,
          x.steps,
          x.battery ?? null,
          x.timestamp,
          x.source || 'mock',
        ],
      );
    }
    await client.query('COMMIT');
    res.json({ accepted: rows.length });
  } catch (e) {
    await client.query('ROLLBACK');
    res.status(500).json({ message: 'Sync failed' });
  } finally {
    client.release();
  }
});
app.get('/health/readings', async (req: AuthRequest, res) => {
  const limit = Math.min(Number(req.query.limit) || 100, 500);
  res.json(
    (
      await pool.query(
        'SELECT * FROM health_readings WHERE user_id=$1 ORDER BY timestamp DESC LIMIT $2',
        [req.userId, limit],
      )
    ).rows,
  );
});
app.get('/health/summary', async (req: AuthRequest, res) => {
  const r = await pool.query(
    `SELECT COUNT(*)::int as readings,ROUND(AVG(heart_rate),1) as avg_heart_rate,ROUND(AVG(spo2),1) as avg_spo2,MAX(steps)::int as max_steps FROM health_readings WHERE user_id=$1 AND timestamp >= NOW()-INTERVAL '7 days'`,
    [req.userId],
  );
  res.json(r.rows[0]);
});
app.get('/products', async (_, res) =>
  res.json((await pool.query('SELECT * FROM products WHERE stock>0 ORDER BY name')).rows),
);
app.get('/products/:id', async (req, res) => {
  const r = await pool.query('SELECT * FROM products WHERE id=$1', [req.params.id]);
  if (!r.rowCount) return res.status(404).json({ message: 'Not found' });
  res.json(r.rows[0]);
});
app.post('/cart', async (req: AuthRequest, res) => {
  const { productId, quantity } = z
    .object({ productId: z.string(), quantity: z.number().int().positive() })
    .parse(req.body);
  await pool.query(
    `INSERT INTO cart_items(user_id,product_id,quantity) VALUES($1,$2,$3) ON CONFLICT(user_id,product_id) DO UPDATE SET quantity=cart_items.quantity+EXCLUDED.quantity`,
    [req.userId, productId, quantity],
  );
  res.json({ ok: true });
});
app.get('/cart', async (req: AuthRequest, res) =>
  res.json(
    (
      await pool.query(
        `SELECT c.id,c.product_id as "productId",p.name,p.price,c.quantity FROM cart_items c JOIN products p ON p.id=c.product_id WHERE c.user_id=$1`,
        [req.userId],
      )
    ).rows,
  ),
);
app.post('/orders', async (req: AuthRequest, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const c = await client.query(
      `SELECT c.product_id,p.price,c.quantity FROM cart_items c JOIN products p ON p.id=c.product_id WHERE c.user_id=$1`,
      [req.userId],
    );
    if (!c.rowCount) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Cart empty' });
    }
    const total = c.rows.reduce((s, x) => s + Number(x.price) * x.quantity, 0);
    const o = await client.query(
      'INSERT INTO orders(user_id,total,status) VALUES($1,$2,$3) RETURNING *',
      [req.userId, total, 'PLACED'],
    );
    for (const x of c.rows)
      await client.query(
        'INSERT INTO order_items(order_id,product_id,price,quantity) VALUES($1,$2,$3,$4)',
        [o.rows[0].id, x.product_id, x.price, x.quantity],
      );
    await client.query('DELETE FROM cart_items WHERE user_id=$1', [req.userId]);
    await client.query('COMMIT');
    res.json(o.rows[0]);
  } catch (e) {
    await client.query('ROLLBACK');
    res.status(500).json({ message: 'Order failed' });
  } finally {
    client.release();
  }
});
app.get('/orders', async (req: AuthRequest, res) => {
  const orders = (
    await pool.query('SELECT * FROM orders WHERE user_id=$1 ORDER BY created_at DESC', [req.userId])
  ).rows;
  for (const o of orders)
    o.items = (
      await pool.query(
        'SELECT oi.*,p.name FROM order_items oi JOIN products p ON p.id=oi.product_id WHERE order_id=$1',
        [o.id],
      )
    ).rows;
  res.json(orders);
});
app.listen(Number(process.env.PORT) || 4000, () => console.log('HealthShop API listening'));
