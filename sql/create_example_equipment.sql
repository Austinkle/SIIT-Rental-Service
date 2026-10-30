USE equipment_borrow;
INSERT INTO category (category_name) VALUES ('Umbrellas'), ('Calculators'),('Power Strips/Extension Cords');
INSERT INTO equipment (name, category_id, total_quantity, available_quantity,location,description)
VALUES ('Compact Auto Open/Close Umbrella', 1, 1, 1,'Rangsit','Windproof compact umbrella with auto-open/close button, 8-rib fibreglass frame, and UV-protective canopy (UPF 50+). Folds to 28 cm. Perfect for Rangsit afternoon showers.'),
('Casio FX-991EX CLASSWIZ', 2, 1, 1,'Rangsit','Casio fx-991EX ClassWiz non-programmable scientific calculator. 552 functions, spreadsheet mode, QR code output, solar + battery. Required for most SIIT engineering and maths exams.'),
('Large Golf Umbrella', 1, 1, 1,'Bangkadi','Extra-large 1.3 m canopy golf umbrella with double canopy vented design for wind resistance. Covers 2–3 people. Wooden crook handle. Available at Bangkadi campus for inter-building walks.'),
('Casio FX-991CW', 2, 1, 1,'Bangkadi','Latest Casio fx-991CW with colour-coded keys, natural textbook display, and 700+ functions. Perfect for physics, chemistry, and statistics coursework. Solar + battery dual power.'),
('3-Socket Extension Cord (5 m)', 3, 1, 1,'Rangsit','Heavy-duty 3-socket extension cord with 5 m cable, surge protector, and individual switch per socket. TIS 2162 safety standard certified. Ideal for lab benches and group study rooms.'),
('6-Socket Power Strip with USB (2 m)', 3, 1, 1,'Bangkadi','6 AC outlets + 2 USB-A 2.4A ports, 2 m flat cable, master switch, and 2 500 J surge protection. Compact enough for laptop bags. Great for presentations and group projects.');

-- Check the student's id first:  SELECT user_id, email FROM `user`;
INSERT INTO borrow_request (user_id, equipment_id) VALUES (1, 1);