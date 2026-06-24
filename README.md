# LEADS MONITORING MOBILE APP

## Project Information

### Project Name

Leads Monitoring App

### Project Type

Mobile Application

### Platform

* Android (Primary)
* iOS (Optional)

### Framework

Flutter Stable

### Language

Dart

### Local Database

SQLite (sqflite)

### State Management

Provider

### Architecture

Feature First + Service Layer

### Connectivity

Offline First

Aplikasi harus dapat digunakan tanpa internet.

Semua data disimpan secara lokal menggunakan SQLite.

Tidak menggunakan backend.

Tidak menggunakan Firebase.

Tidak menggunakan Hive.

Tidak menggunakan ObjectBox.

---

# Business Background

Perusahaan bus pariwisata memiliki tim marketing yang bertugas mencari calon pelanggan (leads).

Saat ini pencatatan leads masih dilakukan secara manual menggunakan spreadsheet.

Tujuan aplikasi adalah:

* Memudahkan input leads harian
* Mengelompokkan leads berdasarkan wilayah
* Mengelompokkan leads berdasarkan sumber leads
* Menyediakan laporan
* Menyediakan grafik performa
* Menyediakan backup dan restore data

---

# User Role

Saat ini hanya ada 1 role:

## Marketing

Hak akses:

* Input leads
* Melihat dashboard
* Melihat laporan
* Export data
* Backup data
* Restore data

Tidak ada login.

Tidak ada autentikasi.

---

# Application Navigation

Bottom Navigation Bar

1. Home
2. Add Data
3. Laporan
4. Pengaturan

---

# SCREEN 1 : HOME

## Purpose

Menampilkan ringkasan performa leads.

---

## Dashboard Cards

### Total Leads Hari Ini

Query:

SUM(jumlah)

berdasarkan tanggal hari ini.

---

### Total Leads Bulan Ini

Query:

SUM(jumlah)

berdasarkan bulan berjalan.

---

### Total Leads Tahun Ini

Query:

SUM(jumlah)

berdasarkan tahun berjalan.

---

### Wilayah Terbaik

Wilayah dengan jumlah leads terbesar.

---

### Sumber Leads Terbaik

Sumber leads dengan jumlah leads terbesar.

---

# Grafik 1

## Trend Leads Harian

Jenis:

Line Chart

Data:

7 hari terakhir.

---

# Grafik 2

## Leads Berdasarkan Wilayah

Jenis:

Bar Chart

Data:

Top wilayah berdasarkan jumlah leads.

---

# Grafik 3

## Leads Berdasarkan Sumber

Jenis:

Pie Chart

Data:

Persentase sumber leads.

---

# SCREEN 2 : ADD DATA

## Purpose

Input data leads harian.

---

## Form

### Wilayah

Dropdown

Data berasal dari tabel wilayah.

---

### Tanggal

Date Picker

Default:

Today

---

### Sumber Leads

Dropdown

Data berasal dari tabel sumber_leads.

---

### Jumlah Leads

Input Number

Validation:

* wajib diisi
* hanya angka
* minimal 0

---

## Action

### Simpan

Saat berhasil:

* insert ke database
* tampil snackbar sukses
* reset form

---

# SCREEN 3 : LAPORAN

## Purpose

Melihat data leads.

---

## Filter Section

### Tanggal Awal

Date Picker

### Tanggal Akhir

Date Picker

### Wilayah

Dropdown

Default:

Semua Wilayah

### Sumber Leads

Dropdown

Default:

Semua Sumber

---

## Statistik

Tampilkan:

* Total Leads
* Rata-rata Leads
* Total Hari Aktif
* Wilayah Terbaik
* Sumber Terbaik

---

## Data Table

Kolom:

* Tanggal
* Wilayah
* Sumber Leads
* Jumlah Leads

Sorting:

* Tanggal
* Wilayah
* Jumlah

---

## Grafik

### Leads Harian

Line Chart

### Leads Wilayah

Bar Chart

### Leads Sumber

Pie Chart

---

# Export Excel

Format:

.xlsx

Nama File:

Leads_Report_YYYYMMDD.xlsx

Sheet 1:

Summary

Sheet 2:

Detail Leads

---

# Export PDF

Format:

.pdf

Nama File:

Leads_Report_YYYYMMDD.pdf

Isi:

* Judul Laporan
* Periode
* Statistik
* Grafik
* Tabel

---

# SCREEN 4 : PENGATURAN

---

# Backup Data

## Tujuan

Menyimpan seluruh database ke file JSON.

---

## Nama File

backup_leads_YYYYMMDD_HHMMSS.json

---

## Struktur JSON

{
"version": "1.0",
"backup_date": "",
"wilayah": [],
"sumber_leads": [],
"leads": []
}

---

## Action

* Generate JSON
* Simpan ke storage
* Share file

---

# Restore Data

## Flow

1. Pilih file JSON
2. Validasi format
3. Tampilkan preview
4. Konfirmasi restore
5. Hapus data lama
6. Import data baru

---

## Validation

Pastikan field:

* wilayah
* sumber_leads
* leads

tersedia.

Jika tidak valid:

Tampilkan error.

---

# Share Backup

Gunakan:

share_plus

Dapat dibagikan ke:

* WhatsApp
* Telegram
* Gmail
* Google Drive

---

# DATABASE DESIGN

## Table wilayah

CREATE TABLE wilayah (
id INTEGER PRIMARY KEY AUTOINCREMENT,
nama_wilayah TEXT NOT NULL
);

---

## Table sumber_leads

CREATE TABLE sumber_leads (
id INTEGER PRIMARY KEY AUTOINCREMENT,
nama_sumber TEXT NOT NULL
);

---

## Table leads

CREATE TABLE leads (
id INTEGER PRIMARY KEY AUTOINCREMENT,
wilayah_id INTEGER NOT NULL,
sumber_id INTEGER NOT NULL,
tanggal TEXT NOT NULL,
jumlah INTEGER NOT NULL,
created_at TEXT NOT NULL,
updated_at TEXT,
FOREIGN KEY(wilayah_id) REFERENCES wilayah(id),
FOREIGN KEY(sumber_id) REFERENCES sumber_leads(id)
);

---

# Seed Data

## Wilayah

* Surabaya
* Sidoarjo
* Gresik
* Malang
* Pasuruan
* Probolinggo
* Jember
* Banyuwangi
* Sumenep
* Pamekasan
* Sampang
* Bangkalan

---

## Sumber Leads

* WhatsApp
* Website
* Instagram
* Facebook
* TikTok
* Google Ads
* Event
* Referensi
* Telepon
* Walk In
* Lainnya

---

# Folder Structure

lib/

core/

constants/

theme/

utils/

database/

database_helper.dart

seed_data.dart

models/

wilayah_model.dart

sumber_leads_model.dart

leads_model.dart

services/

backup_service.dart

restore_service.dart

excel_service.dart

pdf_service.dart

report_service.dart

providers/

dashboard_provider.dart

leads_provider.dart

laporan_provider.dart

settings_provider.dart

screens/

home/

add_data/

laporan/

settings/

widgets/

summary_card.dart

chart_card.dart

custom_dropdown.dart

custom_button.dart

empty_state.dart

routes/

app_routes.dart

main.dart

---

# Required Packages

dependencies:

flutter:
sdk: flutter

provider:

sqflite:

path:

path_provider:

intl:

fl_chart:

file_picker:

share_plus:

excel:

pdf:

printing:

---

# UI Design Requirements

Material 3

Responsive

Modern Dashboard

Card Radius:

16

Padding:

16

Spacing:

12

Color:

Primary:
#0F4C81

Secondary:
#3AAFA9

Background:
#F5F7FA

Success:
#4CAF50

Warning:
#FF9800

Danger:
#F44336

---

# Error Handling

Wajib menangani:

* Database gagal dibuka
* Database kosong
* File JSON rusak
* Restore gagal
* Export gagal
* Input kosong

Gunakan Snackbar untuk feedback.

---

# Performance

Target:

* Startup < 2 detik
* Data 10.000 record tetap lancar
* Query menggunakan index

Tambahkan index:

CREATE INDEX idx_leads_tanggal ON leads(tanggal);

CREATE INDEX idx_leads_wilayah ON leads(wilayah_id);

CREATE INDEX idx_leads_sumber ON leads(sumber_id);

---

# Deliverables

AI Agent harus menghasilkan:

1. Flutter project lengkap
2. SQLite implementation
3. Provider state management
4. Dashboard
5. Grafik
6. CRUD Leads
7. Filter laporan
8. Export Excel
9. Export PDF
10. Backup JSON
11. Restore JSON
12. Seed data otomatis
13. Error handling
14. Material 3 UI
15. Ready build APK

Build Command:

flutter pub get

flutter run

flutter build apk --release

Aplikasi harus dapat dijalankan tanpa konfigurasi tambahan.
