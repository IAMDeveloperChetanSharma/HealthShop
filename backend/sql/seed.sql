-- Demo password is: password
INSERT INTO users(email,password_hash) VALUES('demo@healthshop.dev', '$2b$10$O42rmpngH/Env0pW2e0gB.DBqbaFAw/b.OgerGUirh/t3amZbS89W') ON CONFLICT(email) DO NOTHING;
INSERT INTO products(name,description,price,stock) VALUES('FitRing Strap','Comfort replacement strap for the simulated wearable.',899,25),('Smart Water Bottle','Insulated bottle with hydration reminders.',1299,20),('Recovery Band','Elastic fitness recovery band.',499,50);
