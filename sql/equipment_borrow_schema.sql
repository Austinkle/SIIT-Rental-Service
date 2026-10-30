
CREATE DATABASE IF NOT EXISTS equipment_borrow
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE equipment_borrow;

-- ---------- Users (ISA: user -> student | staff | admin) ----------
-- user = supertype: only the columns every person has.
-- The role of a user IS its subclass (user_type); there is no separate role table.
CREATE TABLE `user` (
    `user_id`       INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `first_name`    VARCHAR(50) NOT NULL,
    `last_name`     VARCHAR(50) NOT NULL,
    `email`         VARCHAR(100) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `phone`         VARCHAR(20) NULL,
    `user_type`     VARCHAR(10) NOT NULL,
    UNIQUE KEY `user_email_unique` (`email`),
    UNIQUE KEY `user_id_type_unique` (`user_id`, `user_type`),
    CONSTRAINT `chk_user_type` CHECK (`user_type` IN ('student', 'staff', 'admin'))
) ENGINE=InnoDB;

-- ISA subtypes (disjoint): each subtype row pins user_type to its own value and
-- references (user_id, user_type), so one user can only appear in the subtype that
-- matches user.user_type. No ON DELETE CASCADE here: MySQL forbids referential
-- actions on columns used in a CHECK. Delete the subtype row before the user row.
CREATE TABLE `student` (
    `user_id`    INT NOT NULL PRIMARY KEY,
    `user_type`  VARCHAR(10) NOT NULL DEFAULT 'student',
    `student_id` BIGINT NOT NULL,
    `major`      VARCHAR(50) NULL,
    `year`       INT NULL,
    UNIQUE KEY `student_student_id_unique` (`student_id`),
    CONSTRAINT `chk_student_type` CHECK (`user_type` = 'student'),
    CONSTRAINT `student_user_fk`
        FOREIGN KEY (`user_id`, `user_type`) REFERENCES `user`(`user_id`, `user_type`)
) ENGINE=InnoDB;

CREATE TABLE `staff` (
    `user_id`   INT NOT NULL PRIMARY KEY,
    `user_type` VARCHAR(10) NOT NULL DEFAULT 'staff',
    `staff_id`  BIGINT NOT NULL,
    UNIQUE KEY `staff_staff_id_unique` (`staff_id`),
    CONSTRAINT `chk_staff_type` CHECK (`user_type` = 'staff'),
    CONSTRAINT `staff_user_fk`
        FOREIGN KEY (`user_id`, `user_type`) REFERENCES `user`(`user_id`, `user_type`)
) ENGINE=InnoDB;

CREATE TABLE `admin` (
    `user_id`   INT NOT NULL PRIMARY KEY,
    `user_type` VARCHAR(10) NOT NULL DEFAULT 'admin',
    `admin_id`  BIGINT NOT NULL,
    UNIQUE KEY `admin_admin_id_unique` (`admin_id`),
    CONSTRAINT `chk_admin_type` CHECK (`user_type` = 'admin'),
    CONSTRAINT `admin_user_fk`
        FOREIGN KEY (`user_id`, `user_type`) REFERENCES `user`(`user_id`, `user_type`)
) ENGINE=InnoDB;

-- ---------- Equipment ----------
CREATE TABLE `category` (
    `category_id`   INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `category_name` VARCHAR(50) NOT NULL,
    UNIQUE KEY `category_category_name_unique` (`category_name`)
) ENGINE=InnoDB;

-- FIX 3: CHECK keeps available_quantity within 0..total_quantity
CREATE TABLE `equipment` (
    `equipment_id`       INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name`               VARCHAR(100) NOT NULL,
    `category_id`        INT NOT NULL,
    `description`        TEXT NULL,
    `total_quantity`     INT NOT NULL DEFAULT 1,
    `available_quantity` INT NOT NULL DEFAULT 1,
    `condition_note`     VARCHAR(100) NULL,
    `status` ENUM('active', 'retired', 'maintenance') NOT NULL DEFAULT 'active',
    -- ER relationship "add":    staff 1 : N equipment  (equipment.added_by)
    -- ER relationship "delete": staff 1 : N equipment  (soft delete: deleted_by + deleted_at)
    -- A row is never physically deleted, otherwise the "delete" relationship would be lost.
    `added_by`   INT NULL,
    `deleted_by` INT NULL,
    `deleted_at` DATETIME NULL,
    `location` ENUM('Rangsit','Bangkadi') NOT NULL,
    CONSTRAINT `equipment_category_id_foreign`
        FOREIGN KEY (`category_id`) REFERENCES `category`(`category_id`),
    CONSTRAINT `equipment_added_by_foreign`
        FOREIGN KEY (`added_by`) REFERENCES `staff`(`user_id`),
    CONSTRAINT `equipment_deleted_by_foreign`
        FOREIGN KEY (`deleted_by`) REFERENCES `staff`(`user_id`),
    CONSTRAINT `chk_equipment_qty`
        CHECK (`available_quantity` >= 0 AND `available_quantity` <= `total_quantity`),
    CONSTRAINT `chk_equipment_deleted`
        CHECK ((`deleted_by` IS NULL AND `deleted_at` IS NULL)
               OR (`deleted_by` IS NOT NULL AND `deleted_at` IS NOT NULL AND `status` = 'retired'))
) ENGINE=InnoDB;

-- Total participation (double lines in the Chen ER) is already enforced by NOT NULL + FK:
--   borrow_request.user_id (submit), borrow_transaction.borrower_id (borrows),
--   borrow_transaction.approved_by (approve), penalty.user_id (owes),
--   penalty.transaction_id (incurs)

-- ---------- Borrowing ----------
CREATE TABLE `borrow_request` (
    `request_id`   INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id`      INT NOT NULL,
    `equipment_id` INT NOT NULL,
    `request_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `status` ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    `handled_by`   INT NULL,        -- NEW: the staff member who accepted or rejected
    `handled_at`   DATETIME NULL,   -- NEW: when they did it
    `borrow_date`         DATETIME NOT NULL,
    `due_date`            DATETIME NOT NULL,
    `location` ENUM('Rangsit','Bangkadi') NOT NULL,
    CONSTRAINT `borrow_request_user_id_foreign`
        FOREIGN KEY (`user_id`) REFERENCES `user`(`user_id`),
    CONSTRAINT `borrow_request_equipment_id_foreign`
        FOREIGN KEY (`equipment_id`) REFERENCES `equipment`(`equipment_id`),
    CONSTRAINT `borrow_request_handled_by_foreign`
        FOREIGN KEY (`handled_by`) REFERENCES `staff`(`user_id`)
) ENGINE=InnoDB;

CREATE TABLE `borrow_transaction` (
    `transaction_id`      INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `request_id`          INT NULL,
    `equipment_id`        INT NOT NULL,
    `borrower_id`         INT NOT NULL,
    `approved_by`         INT NOT NULL,
    `borrow_date`         DATETIME NOT NULL,
    `due_date`            DATETIME NOT NULL,
    `return_date`         DATETIME NULL,
    `condition_at_borrow` VARCHAR(100) NULL,
    `condition_at_return` VARCHAR(100) NULL,
    `status` ENUM('borrowed', 'returned', 'overdue', 'damaged', 'lost')
        NOT NULL DEFAULT 'borrowed',
    UNIQUE KEY `borrow_transaction_request_id_unique` (`request_id`),
    `location` ENUM('Rangsit','Bangkadi') NOT NULL,
    `close_order`         BIT DEFAULT 0 NOT NULL,
    `flag_damage`         BIT DEFAULT 0 NOT NULL,
    `damage_amount`       DECIMAL(10,2) NULL,
    `damage_reason`       VARCHAR(100) NULL,
    `checked_by`          INT NULL,
  ADD CONSTRAINT borrow_transaction_checked_by_foreign
      FOREIGN KEY (checked_by) REFERENCES staff(user_id),
  ADD CONSTRAINT chk_damage_amount CHECK (damage_amount IS NULL OR damage_amount > 0);
    -- FIX 2: correct direction: transaction -> request (1 request : 0..1 transaction)
    CONSTRAINT `borrow_transaction_request_id_foreign`
        FOREIGN KEY (`request_id`) REFERENCES `borrow_request`(`request_id`),
    CONSTRAINT `borrow_transaction_equipment_id_foreign`
        FOREIGN KEY (`equipment_id`) REFERENCES `equipment`(`equipment_id`),
    CONSTRAINT `borrow_transaction_borrower_id_foreign`
        FOREIGN KEY (`borrower_id`) REFERENCES `user`(`user_id`),
    CONSTRAINT `borrow_transaction_approved_by_foreign`
        FOREIGN KEY (`approved_by`) REFERENCES `user`(`user_id`),
    CONSTRAINT `chk_borrow_dates`
        CHECK (`due_date` >= `borrow_date`
               AND (`return_date` IS NULL OR `return_date` >= `borrow_date`))
) ENGINE=InnoDB;

CREATE TABLE `penalty` (
    `penalty_id`     INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id`        INT NOT NULL,
    `transaction_id` INT NOT NULL,
    `penalty_type`   ENUM('late', 'damaged', 'lost') NOT NULL,
    `reason`         VARCHAR(100) NOT NULL,
    `amount`         DECIMAL(10, 2) NOT NULL,
    `paid_status`    ENUM('unpaid', 'paid', 'waived') NOT NULL DEFAULT 'unpaid',
    CONSTRAINT `penalty_user_id_foreign`
        FOREIGN KEY (`user_id`) REFERENCES `user`(`user_id`),
    CONSTRAINT `penalty_transaction_id_foreign`
        FOREIGN KEY (`transaction_id`) REFERENCES `borrow_transaction`(`transaction_id`),
    CONSTRAINT `chk_penalty_amount` CHECK (`amount` >= 0)
) ENGINE=InnoDB;
