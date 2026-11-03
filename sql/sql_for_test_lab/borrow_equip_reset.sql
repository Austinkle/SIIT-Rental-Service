CREATE DATABASE  IF NOT EXISTS `equipment_borrow` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `equipment_borrow`;
-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: equipment_borrow
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `admin`
--

DROP TABLE IF EXISTS `admin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin` (
  `user_id` int NOT NULL,
  `user_type` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'admin',
  `admin_id` bigint NOT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `admin_admin_id_unique` (`admin_id`),
  KEY `admin_user_fk` (`user_id`,`user_type`),
  CONSTRAINT `admin_user_fk` FOREIGN KEY (`user_id`, `user_type`) REFERENCES `user` (`user_id`, `user_type`),
  CONSTRAINT `chk_admin_type` CHECK ((`user_type` = _utf8mb4'admin'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin`
--

LOCK TABLES `admin` WRITE;
/*!40000 ALTER TABLE `admin` DISABLE KEYS */;
INSERT INTO `admin` VALUES (3,'admin',9001);
/*!40000 ALTER TABLE `admin` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `borrow_request`
--

DROP TABLE IF EXISTS `borrow_request`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `borrow_request` (
  `request_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `equipment_id` int NOT NULL,
  `request_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('pending','approved','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `handled_by` int DEFAULT NULL,
  `handled_at` datetime DEFAULT NULL,
  `borrow_date` datetime NOT NULL,
  `due_date` datetime NOT NULL,
  `location` enum('Rangsit','Bangkadi') COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`request_id`),
  KEY `borrow_request_user_id_foreign` (`user_id`),
  KEY `borrow_request_equipment_id_foreign` (`equipment_id`),
  KEY `borrow_request_handled_by_foreign` (`handled_by`),
  CONSTRAINT `borrow_request_equipment_id_foreign` FOREIGN KEY (`equipment_id`) REFERENCES `equipment` (`equipment_id`),
  CONSTRAINT `borrow_request_handled_by_foreign` FOREIGN KEY (`handled_by`) REFERENCES `staff` (`user_id`),
  CONSTRAINT `borrow_request_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `borrow_request`
--

LOCK TABLES `borrow_request` WRITE;
/*!40000 ALTER TABLE `borrow_request` DISABLE KEYS */;
INSERT INTO `borrow_request` VALUES (1,1,1,'2026-11-02 14:36:11','approved',2,'2026-11-02 14:36:11','2026-10-23 00:00:00','2026-10-30 23:59:59','Rangsit'),(2,1,2,'2026-11-02 14:36:11','approved',2,'2026-11-02 14:36:11','2026-10-21 00:00:00','2026-10-28 23:59:59','Rangsit'),(3,1,3,'2026-11-02 14:36:11','approved',2,'2026-11-02 14:36:11','2026-11-02 00:00:00','2026-11-05 23:59:59','Bangkadi');
/*!40000 ALTER TABLE `borrow_request` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_borrow_request_bi` BEFORE INSERT ON `borrow_request` FOR EACH ROW BEGIN
    IF NOT EXISTS (SELECT 1 FROM `student` WHERE user_id = NEW.user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only students can submit borrow requests';
    END IF;
    IF EXISTS (SELECT 1 FROM `equipment`
               WHERE equipment_id = NEW.equipment_id AND deleted_at IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This equipment has been deleted';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_borrow_request_bu` BEFORE UPDATE ON `borrow_request` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_borrow_request_au` AFTER UPDATE ON `borrow_request` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `borrow_transaction`
--

DROP TABLE IF EXISTS `borrow_transaction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `borrow_transaction` (
  `transaction_id` int NOT NULL AUTO_INCREMENT,
  `request_id` int DEFAULT NULL,
  `equipment_id` int NOT NULL,
  `borrower_id` int NOT NULL,
  `approved_by` int NOT NULL,
  `borrow_date` datetime NOT NULL,
  `due_date` datetime NOT NULL,
  `return_date` datetime DEFAULT NULL,
  `condition_at_borrow` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `condition_at_return` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('borrowed','returned','overdue','damaged','lost') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'borrowed',
  `location` enum('Rangsit','Bangkadi') COLLATE utf8mb4_unicode_ci NOT NULL,
  `close_order` bit(1) NOT NULL DEFAULT b'0',
  `flag_damage` bit(1) NOT NULL DEFAULT b'0',
  `damage_amount` decimal(10,2) DEFAULT NULL,
  `damage_reason` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `checked_by` int DEFAULT NULL,
  PRIMARY KEY (`transaction_id`),
  UNIQUE KEY `borrow_transaction_request_id_unique` (`request_id`),
  KEY `borrow_transaction_checked_by_foreign` (`checked_by`),
  KEY `borrow_transaction_equipment_id_foreign` (`equipment_id`),
  KEY `borrow_transaction_borrower_id_foreign` (`borrower_id`),
  KEY `borrow_transaction_approved_by_foreign` (`approved_by`),
  CONSTRAINT `borrow_transaction_approved_by_foreign` FOREIGN KEY (`approved_by`) REFERENCES `user` (`user_id`),
  CONSTRAINT `borrow_transaction_borrower_id_foreign` FOREIGN KEY (`borrower_id`) REFERENCES `user` (`user_id`),
  CONSTRAINT `borrow_transaction_checked_by_foreign` FOREIGN KEY (`checked_by`) REFERENCES `staff` (`user_id`),
  CONSTRAINT `borrow_transaction_equipment_id_foreign` FOREIGN KEY (`equipment_id`) REFERENCES `equipment` (`equipment_id`),
  CONSTRAINT `borrow_transaction_request_id_foreign` FOREIGN KEY (`request_id`) REFERENCES `borrow_request` (`request_id`),
  CONSTRAINT `chk_borrow_dates` CHECK (((`due_date` >= `borrow_date`) and ((`return_date` is null) or (`return_date` >= `borrow_date`)))),
  CONSTRAINT `chk_damage_amount` CHECK (((`damage_amount` is null) or (`damage_amount` > 0)))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `borrow_transaction`
--

LOCK TABLES `borrow_transaction` WRITE;
/*!40000 ALTER TABLE `borrow_transaction` DISABLE KEYS */;
INSERT INTO `borrow_transaction` VALUES (1,1,1,1,2,'2026-10-23 00:00:00','2026-10-30 23:59:59',NULL,NULL,NULL,'borrowed','Rangsit',_binary '\0',_binary '\0',NULL,NULL,NULL),(2,2,2,1,2,'2026-10-21 00:00:00','2026-10-28 23:59:59','2026-11-02 14:36:11',NULL,'Good','returned','Rangsit',_binary '',_binary '\0',NULL,NULL,2),(3,3,3,1,2,'2026-11-02 00:00:00','2026-11-05 23:59:59',NULL,NULL,NULL,'borrowed','Bangkadi',_binary '\0',_binary '\0',NULL,NULL,NULL);
/*!40000 ALTER TABLE `borrow_transaction` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_borrow_transaction_bi` BEFORE INSERT ON `borrow_transaction` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_borrow_transaction_bu` BEFORE UPDATE ON `borrow_transaction` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_borrow_transaction_au` AFTER UPDATE ON `borrow_transaction` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `category`
--

DROP TABLE IF EXISTS `category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `category` (
  `category_id` int NOT NULL AUTO_INCREMENT,
  `category_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `category_category_name_unique` (`category_name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `category`
--

LOCK TABLES `category` WRITE;
/*!40000 ALTER TABLE `category` DISABLE KEYS */;
INSERT INTO `category` VALUES (2,'Calculators'),(3,'Power Strips/Extension Cords'),(1,'Umbrellas');
/*!40000 ALTER TABLE `category` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `equipment`
--

DROP TABLE IF EXISTS `equipment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `equipment` (
  `equipment_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category_id` int NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `total_quantity` int NOT NULL DEFAULT '1',
  `available_quantity` int NOT NULL DEFAULT '1',
  `condition_note` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('active','retired','maintenance') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `added_by` int DEFAULT NULL,
  `deleted_by` int DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `location` enum('Rangsit','Bangkadi') COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`equipment_id`),
  KEY `equipment_category_id_foreign` (`category_id`),
  KEY `equipment_added_by_foreign` (`added_by`),
  KEY `equipment_deleted_by_foreign` (`deleted_by`),
  CONSTRAINT `equipment_added_by_foreign` FOREIGN KEY (`added_by`) REFERENCES `user` (`user_id`),
  CONSTRAINT `equipment_category_id_foreign` FOREIGN KEY (`category_id`) REFERENCES `category` (`category_id`),
  CONSTRAINT `equipment_deleted_by_foreign` FOREIGN KEY (`deleted_by`) REFERENCES `user` (`user_id`),
  CONSTRAINT `chk_equipment_deleted` CHECK ((((`deleted_by` is null) and (`deleted_at` is null)) or ((`deleted_by` is not null) and (`deleted_at` is not null) and (`status` = _utf8mb4'retired')))),
  CONSTRAINT `chk_equipment_qty` CHECK (((`available_quantity` >= 0) and (`available_quantity` <= `total_quantity`)))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `equipment`
--

LOCK TABLES `equipment` WRITE;
/*!40000 ALTER TABLE `equipment` DISABLE KEYS */;
INSERT INTO `equipment` VALUES (1,'Compact Auto Open/Close Umbrella',1,'Windproof compact umbrella with auto-open/close button, 8-rib fibreglass frame, and UV-protective canopy (UPF 50+). Folds to 28 cm. Perfect for Rangsit afternoon showers.',1,0,NULL,'active',NULL,NULL,NULL,'Rangsit'),(2,'Casio FX-991EX CLASSWIZ',2,'Casio fx-991EX ClassWiz non-programmable scientific calculator. 552 functions, spreadsheet mode, QR code output, solar + battery. Required for most SIIT engineering and maths exams.',1,1,NULL,'active',NULL,NULL,NULL,'Rangsit'),(3,'Large Golf Umbrella',1,'Extra-large 1.3 m canopy golf umbrella with double canopy vented design for wind resistance. Covers 2–3 people. Wooden crook handle. Available at Bangkadi campus for inter-building walks.',1,0,NULL,'active',NULL,NULL,NULL,'Bangkadi'),(4,'Casio FX-991CW',2,'Latest Casio fx-991CW with colour-coded keys, natural textbook display, and 700+ functions. Perfect for physics, chemistry, and statistics coursework. Solar + battery dual power.',1,1,NULL,'active',NULL,NULL,NULL,'Bangkadi'),(5,'3-Socket Extension Cord (5 m)',3,'Heavy-duty 3-socket extension cord with 5 m cable, surge protector, and individual switch per socket. TIS 2162 safety standard certified. Ideal for lab benches and group study rooms.',1,1,NULL,'active',NULL,NULL,NULL,'Rangsit'),(6,'6-Socket Power Strip with USB (2 m)',3,'6 AC outlets + 2 USB-A 2.4A ports, 2 m flat cable, master switch, and 2 500 J surge protection. Compact enough for laptop bags. Great for presentations and group projects.',1,1,NULL,'active',NULL,NULL,NULL,'Bangkadi');
/*!40000 ALTER TABLE `equipment` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_equipment_bu` BEFORE UPDATE ON `equipment` FOR EACH ROW BEGIN
    IF OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Deleted equipment cannot be restored';
    END IF;
    IF OLD.added_by IS NOT NULL AND NOT (NEW.added_by <=> OLD.added_by) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'added_by cannot be changed';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `notification`
--

DROP TABLE IF EXISTS `notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification` (
  `notification_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `transaction_id` int DEFAULT NULL,
  `sent_by` int DEFAULT NULL,
  `type` enum('overdue','late_return') COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`notification_id`),
  KEY `notification_user_idx` (`user_id`,`is_read`,`created_at`),
  KEY `notification_transaction_id_foreign` (`transaction_id`),
  KEY `notification_sent_by_foreign` (`sent_by`),
  CONSTRAINT `notification_sent_by_foreign` FOREIGN KEY (`sent_by`) REFERENCES `staff` (`user_id`),
  CONSTRAINT `notification_transaction_id_foreign` FOREIGN KEY (`transaction_id`) REFERENCES `borrow_transaction` (`transaction_id`),
  CONSTRAINT `notification_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notification`
--

LOCK TABLES `notification` WRITE;
/*!40000 ALTER TABLE `notification` DISABLE KEYS */;
/*!40000 ALTER TABLE `notification` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `penalty`
--

DROP TABLE IF EXISTS `penalty`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `penalty` (
  `penalty_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `transaction_id` int NOT NULL,
  `penalty_type` enum('late','damaged','lost') COLLATE utf8mb4_unicode_ci NOT NULL,
  `reason` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `paid_status` enum('unpaid','paid','waived') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'unpaid',
  PRIMARY KEY (`penalty_id`),
  KEY `penalty_user_id_foreign` (`user_id`),
  KEY `penalty_transaction_id_foreign` (`transaction_id`),
  CONSTRAINT `penalty_transaction_id_foreign` FOREIGN KEY (`transaction_id`) REFERENCES `borrow_transaction` (`transaction_id`),
  CONSTRAINT `penalty_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`),
  CONSTRAINT `chk_penalty_amount` CHECK ((`amount` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `penalty`
--

LOCK TABLES `penalty` WRITE;
/*!40000 ALTER TABLE `penalty` DISABLE KEYS */;
/*!40000 ALTER TABLE `penalty` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `staff`
--

DROP TABLE IF EXISTS `staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `staff` (
  `user_id` int NOT NULL,
  `user_type` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'staff',
  `staff_id` bigint NOT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `staff_staff_id_unique` (`staff_id`),
  KEY `staff_user_fk` (`user_id`,`user_type`),
  CONSTRAINT `staff_user_fk` FOREIGN KEY (`user_id`, `user_type`) REFERENCES `user` (`user_id`, `user_type`),
  CONSTRAINT `chk_staff_type` CHECK ((`user_type` = _utf8mb4'staff'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `staff`
--

LOCK TABLES `staff` WRITE;
/*!40000 ALTER TABLE `staff` DISABLE KEYS */;
INSERT INTO `staff` VALUES (2,'staff',7001);
/*!40000 ALTER TABLE `staff` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_staff_bd` BEFORE DELETE ON `staff` FOR EACH ROW BEGIN
    IF @deleting_user_id IS NULL OR @deleting_user_id <> OLD.user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Delete users with sp_delete_user';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `student`
--

DROP TABLE IF EXISTS `student`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student` (
  `user_id` int NOT NULL,
  `user_type` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'student',
  `student_id` bigint NOT NULL,
  `major` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `year` tinyint DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `student_student_id_unique` (`student_id`),
  KEY `student_user_fk` (`user_id`,`user_type`),
  CONSTRAINT `student_user_fk` FOREIGN KEY (`user_id`, `user_type`) REFERENCES `user` (`user_id`, `user_type`),
  CONSTRAINT `chk_student_type` CHECK ((`user_type` = _utf8mb4'student')),
  CONSTRAINT `chk_student_year` CHECK ((`year` between 1 and 6))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `student`
--

LOCK TABLES `student` WRITE;
/*!40000 ALTER TABLE `student` DISABLE KEYS */;
INSERT INTO `student` VALUES (1,'student',6501234567,'CPE',2);
/*!40000 ALTER TABLE `student` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_student_bd` BEFORE DELETE ON `student` FOR EACH ROW BEGIN
    IF @deleting_user_id IS NULL OR @deleting_user_id <> OLD.user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Delete users with sp_delete_user';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `first_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_type` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `user_email_unique` (`email`),
  UNIQUE KEY `user_id_type_unique` (`user_id`,`user_type`),
  CONSTRAINT `chk_user_type` CHECK ((`user_type` in (_utf8mb4'student',_utf8mb4'staff',_utf8mb4'admin')))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'Peter','Parker','6722771234@g.siit.tu.ac.th','$2b$12$D..9wekUiuSfcaniG6OI2OBQzvIeP89/ibT6jBY.YVh3VsjRtS1HW',NULL,'student'),(2,'Tony','Stark','staff2@example.com','$2b$12$ks8aBQLBVC9Qg8ykeJM2ZOlIVTQDyhdltiJWP00eQ88zRKP4KyiHu',NULL,'staff'),(3,'Mary','Jane','admin2@example.com','$2b$12$SPnKzdjbVgDIkmpwaCSfTul7A6WAq093EBpY67fSchccTgxw6RouS',NULL,'admin');
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_user_bi` BEFORE INSERT ON `user` FOR EACH ROW BEGIN
    IF @creating_user IS NULL OR @creating_user <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Create users with sp_create_student, sp_create_staff or sp_create_admin';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Dumping routines for database 'equipment_borrow'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_add_equipment` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_add_equipment`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_admin_add_equipment` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_admin_add_equipment`(
    IN p_admin_user_id INT, IN p_name VARCHAR(100), IN p_category_id INT,
    IN p_description TEXT, IN p_total_quantity INT, IN p_condition_note VARCHAR(100),
    IN p_location VARCHAR(20))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM `admin` WHERE user_id = p_admin_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only an admin can add equipment';
    END IF;
    INSERT INTO `equipment`
        (name, category_id, description, total_quantity, available_quantity,
         condition_note, added_by, location)
    VALUES
        (p_name, p_category_id, p_description, p_total_quantity, p_total_quantity,
         p_condition_note, p_admin_user_id, p_location);
    COMMIT;
    SELECT LAST_INSERT_ID() AS equipment_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_admin_delete_equipment` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_admin_delete_equipment`(IN p_equipment_id INT, IN p_admin_user_id INT)
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
    IF NOT EXISTS (SELECT 1 FROM `admin` WHERE user_id = p_admin_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only an admin can delete equipment';
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
       SET status = 'retired', deleted_by = p_admin_user_id, deleted_at = NOW()
     WHERE equipment_id = p_equipment_id;
    COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_admin_delete_user` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_admin_delete_user`(IN p_user_id INT, IN p_admin_user_id INT)
BEGIN
    DECLARE v_type VARCHAR(10);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET @deleting_user_id = NULL;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM `admin` WHERE user_id = p_admin_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only an admin can delete accounts';
    END IF;
    IF p_user_id = p_admin_user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You cannot delete your own account';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `user` WHERE user_id = p_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account not found';
    END IF;
    SELECT user_type INTO v_type FROM `user` WHERE user_id = p_user_id;
    IF v_type = 'admin' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Admin accounts cannot be deleted here';
    END IF;

    -- the delete triggers on student/staff only allow this user to be removed
    SET @deleting_user_id = p_user_id;
    DELETE FROM `student` WHERE user_id = p_user_id;
    DELETE FROM `staff`   WHERE user_id = p_user_id;
    DELETE FROM `user`    WHERE user_id = p_user_id;
    SET @deleting_user_id = NULL;
    COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_create_admin` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_admin`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_create_staff` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_staff`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_create_student` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_student`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_delete_equipment` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delete_equipment`(IN p_equipment_id INT, IN p_staff_user_id INT)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-02 14:44:36

-- Limited account used by the Express app (instead of root)
DROP USER IF EXISTS 'equip_app'@'localhost';
CREATE USER 'equip_app'@'localhost' IDENTIFIED BY 'choose_a_strong_password';

-- Read everything (login and all pages need this)
GRANT SELECT ON equipment_borrow.* TO 'equip_app'@'localhost';

-- Normal day-to-day changes
GRANT INSERT, UPDATE ON equipment_borrow.borrow_request     TO 'equip_app'@'localhost';
GRANT INSERT, UPDATE ON equipment_borrow.borrow_transaction TO 'equip_app'@'localhost';
GRANT INSERT, UPDATE ON equipment_borrow.penalty            TO 'equip_app'@'localhost';
GRANT INSERT, UPDATE, DELETE ON equipment_borrow.category   TO 'equip_app'@'localhost';

-- Equipment: add/delete only through the procedures; direct UPDATE only on normal columns
GRANT UPDATE (name, category_id, description, total_quantity, available_quantity,
              condition_note, status)
      ON equipment_borrow.equipment TO 'equip_app'@'localhost';
GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_add_equipment    TO 'equip_app'@'localhost';
GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_delete_equipment TO 'equip_app'@'localhost';

-- Users: direct UPDATE only on two columns; create/delete only through the procedures
GRANT UPDATE (password_hash, phone) ON equipment_borrow.`user` TO 'equip_app'@'localhost';
GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_create_student TO 'equip_app'@'localhost';
GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_create_staff   TO 'equip_app'@'localhost';
GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_create_admin   TO 'equip_app'@'localhost';
-- Check what the account can do:
-- SHOW GRANTS FOR 'equip_app'@'localhost';

GRANT INSERT ON equipment_borrow.notification TO 'equip_app'@'localhost';
GRANT UPDATE (is_read) ON equipment_borrow.notification TO 'equip_app'@'localhost';

GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_admin_add_equipment    TO 'equip_app'@'localhost';
GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_admin_delete_equipment TO 'equip_app'@'localhost';

GRANT EXECUTE ON PROCEDURE equipment_borrow.sp_admin_delete_user TO 'equip_app'@'localhost';
