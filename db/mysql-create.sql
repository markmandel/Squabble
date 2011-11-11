/*
	Copyright 2011 Ezra Parker, Josh Wines, Mark Mandel

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.


	Squabble Database Create Script (MySQL with InnoDB)
 */

-- MySQL dump 10.13  Distrib 5.1.41, for debian-linux-gnu (x86_64)
--
-- Host: squabble    Database: squabble
-- ------------------------------------------------------
-- Server version	5.1.41-3ubuntu12.10

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `squabble_combinations`
--

DROP TABLE IF EXISTS `squabble_combinations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `squabble_combinations` (
  `id` char(35) NOT NULL,
  `visitor_id` char(35) DEFAULT NULL,
  `section_name` varchar(500) NOT NULL,
  `variation_name` varchar(500) NOT NULL,
  KEY `fk_combination_visitor_id` (`visitor_id`),
  CONSTRAINT `fk_combination_visitor_id` FOREIGN KEY (`visitor_id`) REFERENCES `squabble_visitors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `squabble_conversions`
--

DROP TABLE IF EXISTS `squabble_conversions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `squabble_conversions` (
  `id` char(35) NOT NULL,
  `visitor_id` char(35) DEFAULT NULL,
  `conversion_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `conversion_name` varchar(500) NOT NULL,
  `conversion_value` double DEFAULT NULL,
  `conversion_units` double DEFAULT NULL,
  KEY `fk_conversion_visitor_id` (`visitor_id`),
  CONSTRAINT `fk_conversion_visitor_id` FOREIGN KEY (`visitor_id`) REFERENCES `squabble_visitors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `squabble_visitor_tags`
--

DROP TABLE IF EXISTS `squabble_visitor_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `squabble_visitor_tags` (
  `visitor_id` char(35) NOT NULL,
  `tag_value` varchar(500) NOT NULL,
  PRIMARY KEY (`visitor_id`,`tag_value`),
  KEY `fk_visitor_tag_visitor_id` (`visitor_id`),
  CONSTRAINT `fk_visitor_tag_visitor_id` FOREIGN KEY (`visitor_id`) REFERENCES `squabble_visitors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `squabble_visitors`
--

DROP TABLE IF EXISTS `squabble_visitors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `squabble_visitors` (
  `id` char(35) NOT NULL,
  `visit_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `test_name` varchar(500) NOT NULL,
  `flat_combination` varchar(1000) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_test_name` (`test_name`),
  KEY `idx_flat_combination` (`flat_combination`(767))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-11-11 14:53:28
