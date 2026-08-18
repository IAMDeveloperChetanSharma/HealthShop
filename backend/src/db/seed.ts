import bcrypt from 'bcryptjs';
import { pool } from './pool';
(async () => {
  const hash = await bcrypt.hash('password', 10);
  await pool.query(
    'INSERT INTO users(email,password_hash) VALUES($1,$2) ON CONFLICT(email) DO UPDATE SET password_hash=EXCLUDED.password_hash',
    ['demo@healthshop.dev', hash],
  );
  await pool.query(
    `INSERT INTO products(name,description,price,stock) VALUES('FitRing Strap','Comfort replacement strap for the simulated wearable.',899,25),('Smart Water Bottle','Insulated bottle with hydration reminders.',1299,20),('Recovery Band','Elastic fitness recovery band.',499,50) ON CONFLICT DO NOTHING`,
  );
  await pool.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
