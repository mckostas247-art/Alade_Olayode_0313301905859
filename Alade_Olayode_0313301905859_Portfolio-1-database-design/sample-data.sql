-- MIT 8103 Portfolio 1: Sample Data (5+ rows per table)

INSERT INTO customers (full_name, email, phone, region) VALUES
('Adebayo Ogunlesi', 'adebayo.o@example.ng', '+2348031112233', 'Lagos'),
('Chioma Nwosu', 'chioma.nwosu@example.ng', '+2348022223344', 'Abuja'),
('Ibrahim Musa', 'ibrahim.musa@example.ng', '+2348053334455', 'Kano'),
('Funke Akindele', 'funke.a@example.ng', '+2348094445566', 'Lagos'),
('Emeka Okafor', 'emeka.okafor@example.ng', '+2348065556677', 'Port Harcourt');

INSERT INTO addresses (customer_id, street, city, state, is_default) VALUES
(1, '14 Admiralty Way, Lekki Phase 1', 'Lagos', 'Lagos', TRUE),
(2, '22 Aminu Kano Crescent, Wuse 2', 'Abuja', 'FCT', TRUE),
(3, '8 Zoo Road', 'Kano', 'Kano', TRUE),
(4, '5 Allen Avenue, Ikeja', 'Lagos', 'Lagos', TRUE),
(5, '19 Aba Road, GRA Phase 2', 'Port Harcourt', 'Rivers', TRUE);

INSERT INTO categories (name, parent_id) VALUES
('Electronics', NULL),
('Fashion', NULL),
('Smartphones', 1),
('Laptops', 1),
('Menswear', 2);

INSERT INTO products (sku, name, category_id, price) VALUES
('PHN-SAM-A55', 'Samsung Galaxy A55 5G 128GB', 3, 485000.00),
('PHN-INF-N40', 'Infinix Note 40 Pro 256GB', 3, 365000.00),
('LAP-HP-G9', 'HP ProBook 450 G9 Core i5', 4, 890000.00),
('LAP-DEL-3520', 'Dell Vostro 3520 16GB RAM', 4, 750000.00),
('FSH-KAF-001', 'Classic Senator Native Wear', 5, 45000.00);

INSERT INTO inventory (product_id, quantity) VALUES
(1, 25),
(2, 40),
(3, 10),
(4, 15),
(5, 60);

INSERT INTO orders (customer_id, status, placed_at, total) VALUES
(1, 'DELIVERED', NOW() - INTERVAL '10 days', 530000.00),
(2, 'PAID', NOW() - INTERVAL '5 days', 365000.00),
(3, 'SHIPPED', NOW() - INTERVAL '3 days', 890000.00),
(4, 'PENDING', NOW() - INTERVAL '1 day', 750000.00),
(5, 'PAID', NOW() - INTERVAL '2 hours', 90000.00);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 485000.00),
(1, 5, 1, 45000.00),
(2, 2, 1, 365000.00),
(3, 3, 1, 890000.00),
(4, 4, 1, 750000.00),
(5, 5, 2, 45000.00);

INSERT INTO payments (order_id, amount, method, status) VALUES
(1, 530000.00, 'CARD', 'SUCCESS'),
(2, 365000.00, 'BANK_TRANSFER', 'SUCCESS'),
(3, 890000.00, 'CARD', 'SUCCESS'),
(4, 750000.00, 'CARD', 'FAILED'),
(5, 90000.00, 'WALLET', 'SUCCESS');

INSERT INTO deliveries (order_id, address_id, tracking_number, status, dispatched_at, delivered_at) VALUES
(1, 1, 'NJC-TRK-0001', 'DELIVERED', NOW() - INTERVAL '9 days', NOW() - INTERVAL '7 days'),
(2, 2, 'NJC-TRK-0002', 'PREPARING', NULL, NULL),
(3, 3, 'NJC-TRK-0003', 'IN_TRANSIT', NOW() - INTERVAL '2 days', NULL),
(4, 4, 'NJC-TRK-0004', 'PREPARING', NULL, NULL),
(5, 5, 'NJC-TRK-0005', 'PREPARING', NULL, NULL);