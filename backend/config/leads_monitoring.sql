-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jul 01, 2026 at 09:11 AM
-- Server version: 12.3.2-MariaDB
-- PHP Version: 8.5.7

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `leads_monitoring`
--

-- --------------------------------------------------------

--
-- Table structure for table `leads`
--

CREATE TABLE `leads` (
  `id` int(11) NOT NULL,
  `wilayah_id` int(11) NOT NULL,
  `sumber_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `tanggal` date NOT NULL,
  `jumlah` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `leads`
--

INSERT INTO `leads` (`id`, `wilayah_id`, `sumber_id`, `user_id`, `tanggal`, `jumlah`, `created_at`) VALUES
(1, 4, 3, 2, '2026-06-30', 12, '2026-06-30 08:56:39'),
(2, 5, 2, 2, '2026-06-30', 9, '2026-06-30 09:15:23'),
(3, 3, 1, 2, '2026-06-23', 2, '2026-06-30 09:15:43'),
(4, 5, 4, 2, '2026-07-01', 3, '2026-07-01 02:05:00');

-- --------------------------------------------------------

--
-- Table structure for table `leads_tour`
--

CREATE TABLE `leads_tour` (
  `id` int(11) NOT NULL,
  `lokasi` varchar(255) NOT NULL,
  `sumber_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `tanggal` date NOT NULL,
  `nama_client` varchar(255) NOT NULL,
  `asal_client` varchar(255) NOT NULL,
  `no_hp_client` varchar(50) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `leads_tour`
--

INSERT INTO `leads_tour` (`id`, `lokasi`, `sumber_id`, `user_id`, `tanggal`, `nama_client`, `asal_client`, `no_hp_client`, `created_at`) VALUES
(1, 'Lombok', 3, 3, '2026-06-30', 'SMA 1 Sumenep', 'Sumenep', '08512312321321', '2026-06-30 08:55:21'),
(2, 'Malang', 2, 3, '2026-07-01', 'SMA 1 Pamekasan', 'Pamekasan', '08367583568', '2026-07-01 02:10:17'),
(3, 'Bandung', 2, 3, '2026-07-01', 'test', 'test', '085231329639', '2026-07-01 04:04:14');

-- --------------------------------------------------------

--
-- Table structure for table `sumber_leads`
--

CREATE TABLE `sumber_leads` (
  `id` int(11) NOT NULL,
  `nama_sumber` varchar(100) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sumber_leads`
--

INSERT INTO `sumber_leads` (`id`, `nama_sumber`, `created_at`) VALUES
(1, 'TikTok', '2026-06-30 08:39:47'),
(2, 'Instagram', '2026-06-30 08:39:47'),
(3, 'Facebook', '2026-06-30 08:39:47'),
(4, 'Google Maps', '2026-06-30 08:39:47'),
(5, 'WhatsApp', '2026-06-30 08:39:47');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `nama_lengkap` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','karyawan','owner') NOT NULL DEFAULT 'karyawan',
  `bagian` enum('marketing','tour') DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `nama_lengkap`, `password`, `role`, `bagian`, `created_at`) VALUES
(1, 'admin', 'Administrator', '$2a$10$mGhfDROKTroOVujEO9tAlu/UpICTrrQMrVTAC9p.S5Zjzjr7LaBa6', 'admin', NULL, '2026-06-30 08:39:47'),
(2, 'anwar', 'Khairil Anwar PENS', '$2a$10$COB7sB5O8vWgBQwNi0EbZ.UzwzARe9/v4JzHFJtYes2LmJD19rCHS', 'karyawan', 'marketing', '2026-06-30 08:39:47'),
(3, 'budi', 'Budi Santoso', '$2a$10$vkY5ZhbeZD/9BmL4IX316Od94x0vTIFM0fn5SgYiFSUxWfZ7BR5F.', 'karyawan', 'tour', '2026-06-30 08:39:47'),
(5, 'owner', 'ari', '$2a$10$ULY3qN4aJTjB0/tHKtlsrejOdRow9Ue0MTCdWa8cJwkbtL/PrTVBu', 'owner', NULL, '2026-07-01 02:37:58');

-- --------------------------------------------------------

--
-- Table structure for table `wilayah`
--

CREATE TABLE `wilayah` (
  `id` int(11) NOT NULL,
  `nama_wilayah` varchar(100) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `wilayah`
--

INSERT INTO `wilayah` (`id`, `nama_wilayah`, `created_at`) VALUES
(1, 'Gresik', '2026-06-30 08:39:47'),
(2, 'Surabaya', '2026-06-30 08:39:47'),
(3, 'Sidoarjo', '2026-06-30 08:39:47'),
(4, 'Malang', '2026-06-30 08:39:47'),
(5, 'Mojokerto', '2026-06-30 08:39:47');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `leads`
--
ALTER TABLE `leads`
  ADD PRIMARY KEY (`id`),
  ADD KEY `wilayah_id` (`wilayah_id`),
  ADD KEY `sumber_id` (`sumber_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `leads_tour`
--
ALTER TABLE `leads_tour`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sumber_id` (`sumber_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `sumber_leads`
--
ALTER TABLE `sumber_leads`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nama_sumber` (`nama_sumber`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `wilayah`
--
ALTER TABLE `wilayah`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nama_wilayah` (`nama_wilayah`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `leads`
--
ALTER TABLE `leads`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `leads_tour`
--
ALTER TABLE `leads_tour`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `sumber_leads`
--
ALTER TABLE `sumber_leads`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `wilayah`
--
ALTER TABLE `wilayah`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `leads`
--
ALTER TABLE `leads`
  ADD CONSTRAINT `1` FOREIGN KEY (`wilayah_id`) REFERENCES `wilayah` (`id`),
  ADD CONSTRAINT `2` FOREIGN KEY (`sumber_id`) REFERENCES `sumber_leads` (`id`),
  ADD CONSTRAINT `3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `leads_tour`
--
ALTER TABLE `leads_tour`
  ADD CONSTRAINT `1` FOREIGN KEY (`sumber_id`) REFERENCES `sumber_leads` (`id`),
  ADD CONSTRAINT `2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
