USE equipment_borrow;

-- Who and what to use (the first student, the first staff member, three items with stock)
SET @student := (SELECT user_id FROM student ORDER BY user_id LIMIT 1);
SET @staff   := (SELECT user_id FROM staff   ORDER BY user_id LIMIT 1);
SET @eqA := (SELECT equipment_id FROM equipment WHERE deleted_at IS NULL AND available_quantity > 0
              ORDER BY equipment_id LIMIT 1 OFFSET 0);
SET @eqB := (SELECT equipment_id FROM equipment WHERE deleted_at IS NULL AND available_quantity > 0
              ORDER BY equipment_id LIMIT 1 OFFSET 1);
SET @eqC := (SELECT equipment_id FROM equipment WHERE deleted_at IS NULL AND available_quantity > 0
              ORDER BY equipment_id LIMIT 1 OFFSET 2);

-- ===== CASE A: due 3 days ago, NOT returned =====
INSERT INTO borrow_request (user_id, equipment_id, borrow_date, due_date, location)
SELECT @student, @eqA,
       TIMESTAMP(CURDATE() - INTERVAL 10 DAY),
       TIMESTAMP(CURDATE() - INTERVAL 3 DAY, '23:59:59'),
       location
  FROM equipment WHERE equipment_id = @eqA;
SET @reqA := LAST_INSERT_ID();
UPDATE borrow_request SET status = 'approved', handled_by = @staff WHERE request_id = @reqA;
-- the trigger now created the borrow_transaction and took one unit off the shelf

-- ===== CASE B: due 5 days ago, returned today (late) =====
INSERT INTO borrow_request (user_id, equipment_id, borrow_date, due_date, location)
SELECT @student, @eqB,
       TIMESTAMP(CURDATE() - INTERVAL 12 DAY),
       TIMESTAMP(CURDATE() - INTERVAL 5 DAY, '23:59:59'),
       location
  FROM equipment WHERE equipment_id = @eqB;
SET @reqB := LAST_INSERT_ID();
UPDATE borrow_request SET status = 'approved', handled_by = @staff WHERE request_id = @reqB;

SET @txB := (SELECT transaction_id FROM borrow_transaction WHERE request_id = @reqB);
-- the student returns it (the trigger sets return_date = now, so it is 5 days late)
UPDATE borrow_transaction SET status = 'returned', condition_at_return = 'Good'
 WHERE transaction_id = @txB;
-- staff close the order (remove this line to leave it waiting in the Return Desk as well)
UPDATE borrow_transaction SET close_order = 1, checked_by = @staff WHERE transaction_id = @txB;

-- ===== CASE C: on time (control, must NOT be in the Overdue tab) =====
INSERT INTO borrow_request (user_id, equipment_id, borrow_date, due_date, location)
SELECT @student, @eqC,
       TIMESTAMP(CURDATE()),
       TIMESTAMP(CURDATE() + INTERVAL 3 DAY, '23:59:59'),
       location
  FROM equipment WHERE equipment_id = @eqC;
SET @reqC := LAST_INSERT_ID();
UPDATE borrow_request SET status = 'approved', handled_by = @staff WHERE request_id = @reqC;

-- ===== Check the result and find the accounts to log in with =====
SELECT bt.transaction_id, e.name, bt.due_date, bt.return_date, bt.status
  FROM borrow_transaction bt JOIN equipment e ON e.equipment_id = bt.equipment_id
 WHERE bt.request_id IN (@reqA, @reqB, @reqC);

SELECT user_id, email, user_type FROM `user` WHERE user_id IN (@student, @staff);