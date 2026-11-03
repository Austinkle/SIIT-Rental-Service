-- 2
SELECT category_id, category_name FROM category ORDER BY category_name;


-- 3
-- 3.1 (student press request)
SELECT * from borrow_request;

-- 3.2 (search equipment name)
SELECT e.equipment_id, e.name, c.category_name, e.description, e.status, e.location,
        e.available_quantity, e.total_quantity
   FROM equipment e
   JOIN category c ON c.category_id = e.category_id
  WHERE e.status = 'active'
    AND (e.name LIKE '%casio%');

-- 3.3 (student press return)
select * from borrow_transaction where status = 'returned';

-- 3.4 (staff delete equipment)
SELECT * from equipment;

-- 5
SELECT * from user;

-- 6
-- 6.1 (trigger bi + bu)
SELECT * from borrow_request;

-- 6.2 (trigger au)
SELECT * from borrow_transaction;

-- 6.3 (add equipment)
SELECT * from equipment;

-- 6.4 (delete equipment)
SELECT * from equipment;

-- 6.5 (delete user)
SELECT * from user;