-- Total participation for the user ISA: every user row must have exactly one subtype row.
-- Run AFTER equipment_borrow_schema.sql.   mysql -u root -p < equipment_borrow_triggers.sql
-- MySQL cannot defer constraints, so the rule is enforced like this:
--   * users can only be created through sp_create_student / sp_create_staff / sp_create_admin
--     (user row + subtype row are inserted in one transaction)
--   * a subtype row can only be deleted through sp_delete_user
--   * user.user_type can never change
-- The session variables below are a guard against mistakes, not a security boundary:
-- anyone who knows them can SET them. Use GRANTs if you need real protection.

USE equipment_borrow;

DELIMITER $$

CREATE TRIGGER trg_user_bi BEFORE INSERT ON `user` FOR EACH ROW
BEGIN
    IF @creating_user IS NULL OR @creating_user <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Create users with sp_create_student, sp_create_staff or sp_create_admin';
    END IF;
END$$

CREATE TRIGGER trg_user_bu BEFORE UPDATE ON `user` FOR EACH ROW
BEGIN
    IF NEW.user_type <> OLD.user_type THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'user_type cannot be changed';
    END IF;
END$$

CREATE TRIGGER trg_student_bd BEFORE DELETE ON `student` FOR EACH ROW
BEGIN
    IF @deleting_user_id IS NULL OR @deleting_user_id <> OLD.user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Delete users with sp_delete_user';
    END IF;
END$$

CREATE TRIGGER trg_staff_bd BEFORE DELETE ON `staff` FOR EACH ROW
BEGIN
    IF @deleting_user_id IS NULL OR @deleting_user_id <> OLD.user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Delete users with sp_delete_user';
    END IF;
END$$

CREATE TRIGGER trg_admin_bd BEFORE DELETE ON `admin` FOR EACH ROW
BEGIN
    IF @deleting_user_id IS NULL OR @deleting_user_id <> OLD.user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Delete users with sp_delete_user';
    END IF;
END$$


-- Who may do what is decided by the subclass the user belongs to (no RBAC tables):
--   student        -> may submit borrow requests and be the borrower (borrower_id)
--   staff          -> may approve (approved_by on a borrow transaction)
CREATE TRIGGER trg_borrow_request_bi BEFORE INSERT ON `borrow_request` FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM `student` WHERE user_id = NEW.user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only students can submit borrow requests';
    END IF;
END$$

CREATE TRIGGER trg_borrow_transaction_bi BEFORE INSERT ON `borrow_transaction` FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM `student` WHERE user_id = NEW.borrower_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Borrower must be a student';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `staff` WHERE user_id = NEW.approved_by) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only staff can approve a borrow';
    END IF;
END$$

-- same two rules when borrower_id / approved_by are changed later
CREATE TRIGGER trg_borrow_transaction_bu BEFORE UPDATE ON `borrow_transaction` FOR EACH ROW
BEGIN
    IF NEW.borrower_id <> OLD.borrower_id
       AND NOT EXISTS (SELECT 1 FROM `student` WHERE user_id = NEW.borrower_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Borrower must be a student';
    END IF;
    IF NEW.approved_by <> OLD.approved_by
       AND NOT EXISTS (SELECT 1 FROM `staff` WHERE user_id = NEW.approved_by) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only staff can approve a borrow';
    END IF;
END$$

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
END$$

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
END$$

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
END$$

-- Fails (and rolls back) if the user is still referenced by requests, transactions or penalties
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
END$$

DELIMITER ;

-- Quick test (uncomment to try):
-- CALL sp_create_student('Somchai', 'Jaidee', 's1@example.com', NULL, 6501234567, 'CPE', 2);
-- INSERT INTO user (first_name, last_name, email, user_type)
--     VALUES ('X', 'Y', 'x@example.com', 'student');          -- must FAIL (trigger)
-- DELETE FROM student WHERE user_id = 1;                          -- must FAIL (trigger)
-- CALL sp_delete_user(1);                                         -- OK
