-- Total participation for the user ISA: every user row must have exactly one subtype row.
-- Also: staff "add" / "delete" equipment (equipment.added_by / deleted_by, soft delete).
-- Run AFTER equipment_borrow_schema.sql.   mysql -u root -p < equipment_borrow_triggers.sql
-- MySQL cannot defer constraints, so the rule is enforced like this:
--   * users can only be created through sp_create_student / sp_create_staff / sp_create_admin
--     (user row + subtype row are inserted in one transaction)
--   * a subtype row can only be deleted through sp_delete_user
--   * user.user_type can never change
-- The session variables below are a guard against mistakes, not a security boundary:
-- anyone who knows them can SET them. Use GRANTs if you need real protection.

USE equipment_borrow;

DELIMITER //

DROP TRIGGER IF EXISTS trg_user_bi//

CREATE TRIGGER trg_user_bi BEFORE INSERT ON `user` FOR EACH ROW
BEGIN
    IF @creating_user IS NULL OR @creating_user <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Create users with sp_create_student, sp_create_staff or sp_create_admin';
    END IF;
END//

DROP TRIGGER IF EXISTS trg_user_bu//

CREATE TRIGGER trg_user_bu BEFORE UPDATE ON `user` FOR EACH ROW
BEGIN
    IF NEW.user_type <> OLD.user_type THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'user_type cannot be changed';
    END IF;
END//

DROP TRIGGER IF EXISTS trg_student_bd//

CREATE TRIGGER trg_student_bd BEFORE DELETE ON `student` FOR EACH ROW
BEGIN
    IF @deleting_user_id IS NULL OR @deleting_user_id <> OLD.user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Delete users with sp_delete_user';
    END IF;
END//

DROP TRIGGER IF EXISTS trg_staff_bd//

CREATE TRIGGER trg_staff_bd BEFORE DELETE ON `staff` FOR EACH ROW
BEGIN
    IF @deleting_user_id IS NULL OR @deleting_user_id <> OLD.user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Delete users with sp_delete_user';
    END IF;
END//

DROP TRIGGER IF EXISTS trg_admin_bd//

CREATE TRIGGER trg_admin_bd BEFORE DELETE ON `admin` FOR EACH ROW
BEGIN
    IF @deleting_user_id IS NULL OR @deleting_user_id <> OLD.user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Delete users with sp_delete_user';
    END IF;
END//


-- Who may do what is decided by the subclass the user belongs to (no RBAC tables):
--   student        -> may submit borrow requests and be the borrower (borrower_id)
--   staff          -> may approve (approved_by on a borrow transaction)
DROP TRIGGER IF EXISTS trg_borrow_request_bi//

CREATE TRIGGER trg_borrow_request_bi BEFORE INSERT ON `borrow_request` FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM `student` WHERE user_id = NEW.user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only students can submit borrow requests';
    END IF;
    IF EXISTS (SELECT 1 FROM `equipment`
               WHERE equipment_id = NEW.equipment_id AND deleted_at IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This equipment has been deleted';
    END IF;
END//

DROP TRIGGER IF EXISTS trg_borrow_transaction_bi//

CREATE TRIGGER trg_borrow_transaction_bi BEFORE INSERT ON `borrow_transaction` FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM `student` WHERE user_id = NEW.borrower_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Borrower must be a student';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `staff` WHERE user_id = NEW.approved_by) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only staff can approve a borrow';
    END IF;
    IF EXISTS (SELECT 1 FROM `equipment`
               WHERE equipment_id = NEW.equipment_id AND deleted_at IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This equipment has been deleted';
    END IF;
END//

DROP TRIGGER IF EXISTS trg_borrow_transaction_bu//

CREATE TRIGGER trg_borrow_transaction_bu BEFORE UPDATE ON `borrow_transaction` FOR EACH ROW
BEGIN
    -- existing rules: borrower must be a student, approver must be staff
    IF NEW.borrower_id <> OLD.borrower_id
       AND NOT EXISTS (SELECT 1 FROM `student` WHERE user_id = NEW.borrower_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Borrower must be a student';
    END IF;
    IF NEW.approved_by <> OLD.approved_by
       AND NOT EXISTS (SELECT 1 FROM `staff` WHERE user_id = NEW.approved_by) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only staff can approve a borrow';
    END IF;

    -- a closed order is final
    IF OLD.close_order = 1
       AND (NEW.close_order = 0 OR NEW.flag_damage <> OLD.flag_damage OR NEW.status <> OLD.status) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This order is already closed';
    END IF;

    -- a finished rental cannot go back to borrowed/overdue
    IF OLD.status IN ('returned', 'damaged', 'lost') AND NEW.status IN ('borrowed', 'overdue') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This rental is already returned';
    END IF;

    -- 1) the student returns the item
    IF OLD.status IN ('borrowed', 'overdue') AND NEW.status = 'returned' THEN
        IF NOW() < OLD.borrow_date THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This rental has not started yet';
        END IF;
        IF NEW.condition_at_return IS NULL OR TRIM(NEW.condition_at_return) = '' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Condition at return is required';
        END IF;
        SET NEW.return_date = NOW();
    END IF;

    -- 2) staff flag damage
    IF OLD.flag_damage = 1 AND NEW.flag_damage = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The damage flag cannot be removed';
    END IF;
    IF OLD.flag_damage = 0 AND NEW.flag_damage = 1 THEN
        IF NEW.status <> 'returned' OR NEW.close_order = 1 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only a returned, open order can be flagged';
        END IF;
        IF NEW.checked_by IS NULL
           OR NOT EXISTS (SELECT 1 FROM `staff` WHERE user_id = NEW.checked_by) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only staff can flag damage';
        END IF;
        IF NEW.damage_amount IS NULL OR NEW.damage_amount <= 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Enter a penalty amount greater than 0';
        END IF;
        IF NEW.damage_reason IS NULL OR TRIM(NEW.damage_reason) = '' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Enter a reason for the damage';
        END IF;
    END IF;

    -- 3) staff close the order
    IF OLD.close_order = 0 AND NEW.close_order = 1 THEN
        IF NEW.status <> 'returned' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only a returned item can be closed';
        END IF;
        IF NEW.checked_by IS NULL
           OR NOT EXISTS (SELECT 1 FROM `staff` WHERE user_id = NEW.checked_by) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only staff can close an order';
        END IF;
        IF NEW.flag_damage = 1
           AND EXISTS (SELECT 1 FROM `penalty`
                        WHERE transaction_id = NEW.transaction_id AND paid_status = 'unpaid') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The penalty must be paid before closing the order';
        END IF;
    END IF;
END//

DROP TRIGGER IF EXISTS trg_borrow_transaction_au//

CREATE TRIGGER trg_borrow_transaction_au AFTER UPDATE ON `borrow_transaction` FOR EACH ROW
BEGIN
    -- staff flagged damage: create the penalty for this order and this person
    IF OLD.flag_damage = 0 AND NEW.flag_damage = 1 THEN
        INSERT INTO `penalty` (user_id, transaction_id, penalty_type, reason, amount)
        VALUES (NEW.borrower_id, NEW.transaction_id, 'damaged', NEW.damage_reason, NEW.damage_amount);
    END IF;

    -- staff closed the order: the item is back on the shelf
    IF OLD.close_order = 0 AND NEW.close_order = 1 THEN
        UPDATE `equipment`
           SET available_quantity = available_quantity + 1
         WHERE equipment_id = NEW.equipment_id;
    END IF;
END//

DROP PROCEDURE IF EXISTS sp_create_student//

CREATE PROCEDURE sp_create_student(
    IN p_first_name VARCHAR(50), IN p_last_name VARCHAR(50),
    IN p_email VARCHAR(100), IN p_password_hash VARCHAR(255), IN p_phone VARCHAR(20),
    IN p_student_id BIGINT, IN p_major VARCHAR(50), IN p_year INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET @creating_user = NULL;
        RESIGNAL;
    END;
    START TRANSACTION;
    SET @creating_user = 1;
    INSERT INTO `user` (first_name, last_name, email, password_hash, phone, user_type)
    VALUES (p_first_name, p_last_name, p_email, p_password_hash, p_phone, 'student');
    SET @creating_user = NULL;
    INSERT INTO `student` (user_id, student_id, major, year)
    VALUES (LAST_INSERT_ID(), p_student_id, p_major, p_year);
    COMMIT;
END//

DROP PROCEDURE IF EXISTS sp_create_staff//

CREATE PROCEDURE sp_create_staff(
    IN p_first_name VARCHAR(50), IN p_last_name VARCHAR(50),
    IN p_email VARCHAR(100), IN p_password_hash VARCHAR(255), IN p_phone VARCHAR(20),
    IN p_staff_id BIGINT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET @creating_user = NULL;
        RESIGNAL;
    END;
    START TRANSACTION;
    SET @creating_user = 1;
    INSERT INTO `user` (first_name, last_name, email, password_hash, phone, user_type)
    VALUES (p_first_name, p_last_name, p_email, p_password_hash, p_phone, 'staff');
    SET @creating_user = NULL;
    INSERT INTO `staff` (user_id, staff_id) VALUES (LAST_INSERT_ID(), p_staff_id);
    COMMIT;
END//

DROP PROCEDURE IF EXISTS sp_create_admin//

CREATE PROCEDURE sp_create_admin(
    IN p_first_name VARCHAR(50), IN p_last_name VARCHAR(50),
    IN p_email VARCHAR(100), IN p_password_hash VARCHAR(255), IN p_phone VARCHAR(20),
    IN p_admin_id BIGINT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET @creating_user = NULL;
        RESIGNAL;
    END;
    START TRANSACTION;
    SET @creating_user = 1;
    INSERT INTO `user` (first_name, last_name, email, password_hash, phone, user_type)
    VALUES (p_first_name, p_last_name, p_email, p_password_hash, p_phone, 'admin');
    SET @creating_user = NULL;
    INSERT INTO `admin` (user_id, admin_id) VALUES (LAST_INSERT_ID(), p_admin_id);
    COMMIT;
END//

-- Fails (and rolls back) if the user is still referenced by requests, transactions, penalties
-- or equipment (equipment.added_by / deleted_by)
DROP PROCEDURE IF EXISTS sp_delete_user//

CREATE PROCEDURE sp_delete_user(IN p_user_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET @deleting_user_id = NULL;
        RESIGNAL;
    END;
    START TRANSACTION;
    SET @deleting_user_id = p_user_id;
    DELETE FROM `student` WHERE user_id = p_user_id;
    DELETE FROM `staff`   WHERE user_id = p_user_id;
    DELETE FROM `admin`   WHERE user_id = p_user_id;
    DELETE FROM `user`    WHERE user_id = p_user_id;
    SET @deleting_user_id = NULL;
    COMMIT;
END//

-- ---------- Equipment: staff "add" and "delete" ----------
-- Equipment rows are never physically deleted (that would erase who deleted them).
-- "delete" = soft delete: status 'retired' + deleted_by + deleted_at, via sp_delete_equipment.
DROP TRIGGER IF EXISTS trg_equipment_bd//

CREATE TRIGGER trg_equipment_bd BEFORE DELETE ON `equipment` FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Equipment is never hard-deleted; use sp_delete_equipment';
END//

DROP TRIGGER IF EXISTS trg_equipment_bu//

CREATE TRIGGER trg_equipment_bu BEFORE UPDATE ON `equipment` FOR EACH ROW
BEGIN
    IF OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Deleted equipment cannot be restored';
    END IF;
    IF OLD.added_by IS NOT NULL AND NOT (NEW.added_by <=> OLD.added_by) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'added_by cannot be changed';
    END IF;
END//

DROP PROCEDURE IF EXISTS sp_add_equipment//

CREATE PROCEDURE sp_add_equipment(
    IN p_staff_user_id INT, IN p_name VARCHAR(100), IN p_category_id INT,
    IN p_description TEXT, IN p_total_quantity INT, IN p_condition_note VARCHAR(100),
    IN p_location VARCHAR(20))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM `staff` WHERE user_id = p_staff_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only staff can add equipment';
    END IF;
    INSERT INTO `equipment`
        (name, category_id, description, total_quantity, available_quantity,
         condition_note, added_by, location)
    VALUES
        (p_name, p_category_id, p_description, p_total_quantity, p_total_quantity,
         p_condition_note, p_staff_user_id, p_location);
    COMMIT;
    SELECT LAST_INSERT_ID() AS equipment_id;
END//

DROP PROCEDURE IF EXISTS sp_delete_equipment//

CREATE PROCEDURE sp_delete_equipment(IN p_equipment_id INT, IN p_staff_user_id INT)
BEGIN
    DECLARE v_deleted_at DATETIME;
    DECLARE v_available INT;
    DECLARE v_total INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM `staff` WHERE user_id = p_staff_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only staff can delete equipment';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `equipment` WHERE equipment_id = p_equipment_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Equipment not found';
    END IF;
    SELECT deleted_at, available_quantity, total_quantity
      INTO v_deleted_at, v_available, v_total
      FROM `equipment` WHERE equipment_id = p_equipment_id FOR UPDATE;
    IF v_deleted_at IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Equipment is already deleted';
    END IF;
    IF v_available < v_total THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Some units are still borrowed; cannot delete';
    END IF;
    UPDATE `equipment`
       SET status = 'retired', deleted_by = p_staff_user_id, deleted_at = NOW()
     WHERE equipment_id = p_equipment_id;
    COMMIT;
END//

-- ---------- Staff accept / reject a borrow request ----------
-- BEFORE: validate. AFTER: do the side effects (only runs if validation passed).
DROP TRIGGER IF EXISTS trg_borrow_request_bu//

CREATE TRIGGER trg_borrow_request_bu BEFORE UPDATE ON `borrow_request` FOR EACH ROW
BEGIN
    -- a request that was already approved/rejected cannot change again
    IF OLD.status <> 'pending' AND NEW.status <> OLD.status THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This request has already been handled';
    END IF;

    IF OLD.status = 'pending' AND NEW.status IN ('approved', 'rejected') THEN
        IF NEW.handled_by IS NULL
           OR NOT EXISTS (SELECT 1 FROM `staff` WHERE user_id = NEW.handled_by) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only staff can accept or reject a request';
        END IF;

        IF NEW.status = 'approved'
           AND (SELECT available_quantity FROM `equipment`
                 WHERE equipment_id = NEW.equipment_id) < 1 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No equipment available';
        END IF;

        SET NEW.handled_at = NOW();
    END IF;
END//

DROP TRIGGER IF EXISTS trg_borrow_request_au//

CREATE TRIGGER trg_borrow_request_au AFTER UPDATE ON `borrow_request` FOR EACH ROW
BEGIN
    IF OLD.status = 'pending' AND NEW.status = 'approved' THEN
        UPDATE `equipment`
           SET available_quantity = available_quantity - 1
         WHERE equipment_id = NEW.equipment_id;
        
        INSERT INTO `borrow_transaction`
            (request_id, equipment_id, borrower_id, approved_by,
             borrow_date, due_date, condition_at_borrow, location)
        VALUES
            (NEW.request_id, NEW.equipment_id, NEW.user_id, NEW.handled_by,
             NEW.borrow_date, NEW.due_date,                      -- the dates the student chose
             (SELECT condition_note FROM `equipment` WHERE equipment_id = NEW.equipment_id),
             NEW.location);
    END IF;
END//


DELIMITER ;

-- Quick test (uncomment to try):
-- CALL sp_create_student('Somchai', 'Jaidee', 's1@example.com', NULL, 6501234567, 'CPE', 2);
-- INSERT INTO user (first_name, last_name, email, user_type)
--     VALUES ('X', 'Y', 'x@example.com', 'student');          -- must FAIL (trigger)
-- DELETE FROM student WHERE user_id = 1;                          -- must FAIL (trigger)
-- CALL sp_delete_user(1);                                         -- OK
-- CALL sp_create_staff('Mali', 'Rakdee', 'st1@example.com', NULL, 7001);   -- note its user_id
-- INSERT INTO category (category_name) VALUES ('Camera');
-- CALL sp_add_equipment(<staff user_id>, 'Canon R50', 1, NULL, 3, 'new', 'Rangsit');  -- OK
-- CALL sp_add_equipment(<student user_id>, 'X', 1, NULL, 1, NULL, 'Bangkadi'); -- must FAIL (not staff)
-- DELETE FROM equipment WHERE equipment_id = 1;                            -- must FAIL (trigger)
-- CALL sp_delete_equipment(1, <staff user_id>);                            -- OK (soft delete)
-- CALL sp_delete_equipment(1, <staff user_id>);                            -- must FAIL (already deleted)