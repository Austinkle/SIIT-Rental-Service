-- Limited account used by the Express app (instead of root)
DROP USER IF EXISTS 'equip_app'@'localhost';
CREATE USER 'equip_app'@'localhost' IDENTIFIED BY 'choose_a_strong_password';

-- Read everything (login and all pages need this)
GRANT SELECT ON equipment_borrow.* TO 'equip_app'@'localhost';

-- Normal day-to-day changes
GRANT INSERT, UPDATE ON equipment_borrow.borrow_request     TO 'equip_app'@'localhost';
GRANT INSERT, UPDATE ON equipment_borrow.borrow_transaction TO 'equip_app'@'localhost';
GRANT INSERT, UPDATE ON equipment_borrow.penalty            TO 'equip_app'@'localhost';
GRANT INSERT, UPDATE, DELETE ON equipment_borrow.equipment  TO 'equip_app'@'localhost';
GRANT INSERT, UPDATE, DELETE ON equipment_borrow.category   TO 'equip_app'@'localhost';

-- Users: direct UPDATE only on two columns; create/delete only through the procedures
GRANT UPDATE (password_hash, phone) ON equipment_borrow.`user` TO 'equip_app'@'localhost';
GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_create_student TO 'equip_app'@'localhost';
GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_create_staff   TO 'equip_app'@'localhost';
GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_create_admin   TO 'equip_app'@'localhost';
GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_delete_user    TO 'equip_app'@'localhost';

-- Example of taking a permission away (optional):
-- REVOKE DELETE ON equipment_borrow.category FROM 'equip_app'@'localhost';

-- Check what the account can do:
-- SHOW GRANTS FOR 'equip_app'@'localhost';