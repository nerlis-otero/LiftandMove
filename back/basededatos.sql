-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: localhost    Database: rutinas_ejercicios
-- ------------------------------------------------------
-- Server version	8.0.45

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
-- Table structure for table `ejercicio_musculo`
--

DROP TABLE IF EXISTS `ejercicio_musculo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ejercicio_musculo` (
  `idEjercicio` varchar(100) NOT NULL,
  `idMusculo` varchar(50) NOT NULL,
  `rol` int NOT NULL,
  PRIMARY KEY (`idEjercicio`,`idMusculo`),
  KEY `MuscEjer_FK` (`idMusculo`),
  CONSTRAINT `ejerMusc_FK` FOREIGN KEY (`idEjercicio`) REFERENCES `ejercicios` (`idEjercicio`),
  CONSTRAINT `MuscEjer_FK` FOREIGN KEY (`idMusculo`) REFERENCES `musculos` (`idMusculo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ejercicios`
--

DROP TABLE IF EXISTS `ejercicios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ejercicios` (
  `idEjercicio` varchar(100) NOT NULL,
  `nombreEj` varchar(100) NOT NULL,
  `tipo` varchar(50) NOT NULL,
  `equipamiento` varchar(50) DEFAULT NULL,
  `nivel` varchar(20) DEFAULT NULL,
  `instrucciones` json DEFAULT NULL,
  `imagenes` json DEFAULT NULL,
  PRIMARY KEY (`idEjercicio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `entreno_ejercicio`
--

DROP TABLE IF EXISTS `entreno_ejercicio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `entreno_ejercicio` (
  `idEntEj` varchar(20) NOT NULL,
  `idEntreno` varchar(20) NOT NULL,
  `idEjercicio` varchar(100) NOT NULL,
  `series` int NOT NULL,
  `repeticiones` int NOT NULL,
  `peso_kg` double NOT NULL,
  `orden` int NOT NULL,
  PRIMARY KEY (`idEntEj`),
  KEY `entreno_ejercicio_FK` (`idEntreno`),
  KEY `ejercicio_entreno_FK` (`idEjercicio`),
  CONSTRAINT `ejercicio_entreno_FK` FOREIGN KEY (`idEjercicio`) REFERENCES `ejercicios` (`idEjercicio`),
  CONSTRAINT `entreno_ejercicio_FK` FOREIGN KEY (`idEntreno`) REFERENCES `entrenos` (`idEntreno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `entrenos`
--

DROP TABLE IF EXISTS `entrenos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `entrenos` (
  `idEntreno` varchar(20) NOT NULL,
  `fecha_entreno` datetime NOT NULL,
  `idUsu` varchar(20) NOT NULL,
  `nombre_entreno` varchar(30) DEFAULT NULL,
  `notas` text,
  PRIMARY KEY (`idEntreno`),
  KEY `entrenos_usuarios_FK` (`idUsu`),
  CONSTRAINT `entrenos_usuarios_FK` FOREIGN KEY (`idUsu`) REFERENCES `usuarios` (`idUsu`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `medida_corporal`
--

DROP TABLE IF EXISTS `medida_corporal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `medida_corporal` (
  `id_med` varchar(20) NOT NULL,
  `idUsu` varchar(20) NOT NULL,
  `fecha` date NOT NULL,
  `peso_kg` double DEFAULT NULL,
  `cintura_cm` double DEFAULT NULL,
  `cadera_cm` double DEFAULT NULL,
  `pecho_cm` double DEFAULT NULL,
  `brazo_cm` double DEFAULT NULL,
  `muslo_cm` double DEFAULT NULL,
  `es_meta` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id_med`),
  KEY `medida_usuario_FK` (`idUsu`),
  CONSTRAINT `medida_usuario_FK` FOREIGN KEY (`idUsu`) REFERENCES `usuarios` (`idUsu`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `modalidad_entreno`
--

DROP TABLE IF EXISTS `modalidad_entreno`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `modalidad_entreno` (
  `idUsu` varchar(20) NOT NULL,
  `modalidad` varchar(20) NOT NULL,
  PRIMARY KEY (`idUsu`),
  CONSTRAINT `usuario_modalidad_FK` FOREIGN KEY (`idUsu`) REFERENCES `usuarios` (`idUsu`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `musculos`
--

DROP TABLE IF EXISTS `musculos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `musculos` (
  `idMusculo` varchar(50) NOT NULL,
  `nombreMusc` varchar(50) NOT NULL,
  `grupo_muscular` varchar(20) NOT NULL,
  PRIMARY KEY (`idMusculo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rutina_completada`
--

DROP TABLE IF EXISTS `rutina_completada`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rutina_completada` (
  `id` int NOT NULL AUTO_INCREMENT,
  `idPlantilla` varchar(36) NOT NULL,
  `idUsu` varchar(100) NOT NULL,
  `fecha` date NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unico_dia` (`idPlantilla`,`fecha`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rutina_dias`
--

DROP TABLE IF EXISTS `rutina_dias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rutina_dias` (
  `idPlantilla` varchar(36) NOT NULL,
  `dia_semana` tinyint NOT NULL,
  PRIMARY KEY (`idPlantilla`,`dia_semana`),
  CONSTRAINT `rutina_dias_plantilla_FK` FOREIGN KEY (`idPlantilla`) REFERENCES `rutina_plantilla` (`idPlantilla`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rutina_ejercicio`
--

DROP TABLE IF EXISTS `rutina_ejercicio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rutina_ejercicio` (
  `idRutinaEj` varchar(36) NOT NULL,
  `idPlantilla` varchar(36) NOT NULL,
  `idEjercicio` varchar(100) NOT NULL,
  `series` int NOT NULL DEFAULT '3',
  `repeticiones` int NOT NULL DEFAULT '10',
  `peso_kg` double NOT NULL DEFAULT '0',
  `orden` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`idRutinaEj`),
  KEY `rutina_ejercicio_plantilla_FK` (`idPlantilla`),
  KEY `rutina_ejercicio_ejercicio_FK` (`idEjercicio`),
  CONSTRAINT `rutina_ejercicio_ejercicio_FK` FOREIGN KEY (`idEjercicio`) REFERENCES `ejercicios` (`idEjercicio`),
  CONSTRAINT `rutina_ejercicio_plantilla_FK` FOREIGN KEY (`idPlantilla`) REFERENCES `rutina_plantilla` (`idPlantilla`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rutina_plantilla`
--

DROP TABLE IF EXISTS `rutina_plantilla`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rutina_plantilla` (
  `idPlantilla` varchar(36) NOT NULL,
  `idUsu` varchar(20) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  PRIMARY KEY (`idPlantilla`),
  KEY `rutina_plantilla_usuario_FK` (`idUsu`),
  CONSTRAINT `rutina_plantilla_usuario_FK` FOREIGN KEY (`idUsu`) REFERENCES `usuarios` (`idUsu`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sesion_ejercicio`
--

DROP TABLE IF EXISTS `sesion_ejercicio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sesion_ejercicio` (
  `id` varchar(36) NOT NULL,
  `id_sesion` varchar(36) NOT NULL,
  `idEjercicio` varchar(20) NOT NULL,
  `series` int NOT NULL DEFAULT '0',
  `repeticiones` int NOT NULL DEFAULT '0',
  `peso_kg` double NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_sesion` (`id_sesion`),
  KEY `idx_ejercicio` (`idEjercicio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sesion_entreno`
--

DROP TABLE IF EXISTS `sesion_entreno`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sesion_entreno` (
  `id_sesion` varchar(36) NOT NULL,
  `idUsu` varchar(20) NOT NULL,
  `idPlantilla` varchar(36) NOT NULL,
  `fecha` date NOT NULL,
  PRIMARY KEY (`id_sesion`),
  UNIQUE KEY `uq_sesion_usuario_rutina_fecha` (`idUsu`,`idPlantilla`,`fecha`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `idUsu` varchar(20) NOT NULL,
  `nombreUsu` varchar(30) NOT NULL,
  `correoUsu` varchar(30) NOT NULL,
  `contrasenha` varchar(100) NOT NULL,
  `sexo` char(1) NOT NULL,
  `altura_cm` int NOT NULL,
  `peso` int NOT NULL,
  `objetivo_entreno` varchar(30) NOT NULL,
  `esAdmin` tinyint(1) NOT NULL DEFAULT '0',
  `peso_objetivo` float DEFAULT NULL,
  `meta_series_semanales` int DEFAULT NULL,
  `meta_peso_maximo` float DEFAULT NULL,
  `meta_dias_semana` int DEFAULT NULL,
  PRIMARY KEY (`idUsu`),
  CONSTRAINT `sexo_CK` CHECK ((`sexo` in (_utf8mb4'M',_utf8mb4'F')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-26 23:16:38
