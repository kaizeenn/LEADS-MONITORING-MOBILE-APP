# 🚀 PANDUAN MUDAH: DEPLOY APLIKASI LEADS MONITORING KE VPS BARU

Panduan ini dibuat khusus untuk memudahkan proses pemindahan aplikasi **Leads Monitoring** dari komputer lokal (laptop) ke **VPS Baru** agar bisa diakses oleh semua orang lewat internet.

---

## 🛠️ Persiapan Awal
Sebelum memulai, pastikan Anda memiliki:
1.  **Detail VPS Baru**: Alamat IP (contoh: `202.10.41.37`) dan Password Administrator (`root`).
2.  **Aplikasi Pendukung di Laptop**:
    *   Aplikasi transfer file: Unduh dan instal **[FileZilla Client](https://filezilla-project.org/)** (gratis) untuk mengirim file ke server dengan mudah.
    *   Aplikasi Terminal: Command Prompt/PowerShell (Windows), atau Terminal (Mac/Linux).

---

## 📁 STRUKTUR FILE: Apa yang Dikirim ke Server?

Tidak semua file di laptop Anda harus dikirim ke server. Aplikasi ini dibagi menjadi dua bagian:

### ❌ JANGAN Dikirim ke Server (Biarkan di Laptop)
Folder aplikasi HP (Flutter) tidak perlu diunggah karena server tidak bisa menjalankan aplikasi HP. Folder yang harus diabaikan adalah:
*   `android/`, `ios/`, `lib/`, `test/`, `web/`, `windows/`, `macos/`, `linux/`
*   `build/` (ukuran file sangat besar, cukup hapus atau abaikan)
*   `.dart_tool/`, `.idea/`, `.metadata`
*   `pubspec.yaml`, `pubspec.lock`

### ✅ HARUS Dikirim ke Server (VPS)
Hanya dua folder ini saja yang akan kita jalankan di server:
1.  Folder **`backend/`** (kecuali folder `node_modules` di dalamnya karena ukurannya besar, nanti akan kita instal langsung di server).
2.  Folder **`frontend/dist/`** (hasil file web jadi setelah dikompilasi).

---

## ⚙️ LANGKAH 1: Persiapan di Laptop Lokal

### A. Sambungkan Alamat Web ke Server Baru
1. Buka folder utama proyek Anda di laptop, lalu masuk ke folder `frontend/src/`.
2. Buka file bernama `App.jsx` menggunakan editor teks (Notepad, VS Code, dll).
3. Cari baris **27** yang tertulis:
   `const API_URL = 'http://localhost:3000/api';`
4. Ubah `localhost:3000` menjadi **Alamat IP VPS Baru** Anda dengan port **`18791`**.
   *Contoh jika IP VPS Anda adalah `202.10.41.37`:*
   ```javascript
   const API_URL = 'http://202.10.41.37:18791/api';
   ```

### B. Kompilasi Halaman Web
1. Buka Terminal/Command Prompt di laptop Anda.
2. Arahkan terminal masuk ke dalam folder `frontend` proyek Anda:
   ```bash
   # Masuk ke folder frontend proyek Anda
   cd [JALUR_FOLDER_PROYEK_ANDA]/frontend
   ```
   *(Tips: Anda juga bisa membuka folder `frontend` di File Explorer, klik kanan, lalu pilih "Open in Terminal" atau "Buka di Terminal")*
3. Jalankan perintah ini untuk merakit halaman web:
   ```bash
   npm install
   npm run build
   ```
4. Setelah selesai, Anda akan melihat folder baru bernama `dist` muncul di dalam folder `frontend`.

### C. Sambungkan Halaman Web ke Backend
Agar Anda tidak perlu menyewa domain/port tambahan untuk web, kita akan menyatukan halaman web ke dalam backend.
1. Buka folder `backend/` di laptop Anda.
2. Buka file `app.js`.
3. Cari bagian paling bawah (sebelum baris `module.exports = app;`).
4. Salin dan tempel kode berikut tepat di atasnya:
   ```javascript
   // ===== Mengarahkan server untuk membaca halaman web dashboard =====
   const path = require('path');
   const frontendDistPath = path.join(__dirname, '../frontend/dist');
   app.use(express.static(frontendDistPath));

   app.get('*', (req, res, next) => {
     if (req.path.startsWith('/api')) {
       return next();
     }
     res.sendFile(path.join(frontendDistPath, 'index.html'));
   });
   ```

---

## 📤 LANGKAH 2: Mengirim File ke Server (VPS)

Kita akan menggunakan aplikasi **FileZilla** agar proses pengiriman file semudah *drag-and-drop*:

1. Buka aplikasi **FileZilla** di laptop Anda.
2. Isi kolom koneksi di bagian atas:
   *   **Host**: `sftp://<MASUKKAN_IP_VPS_ANDA>` (contoh: `sftp://202.10.41.37`)
   *   **Username**: `root`
   *   **Password**: `<PASSWORD_VPS_ANDA>`
   *   **Port**: `22` (atau kosongkan)
3. Klik **Quickconnect**. Jika ada peringatan keamanan, klik **OK**.
4. Di panel sebelah kanan (Server VPS), masuk ke folder `/var/www/`. Jika folder `www` belum ada, klik kanan lalu pilih **Create directory** dengan nama `www`.
5. Di dalam `/var/www/`, buat folder baru bernama `leads-monitoring`.
6. Di dalam `/var/www/leads-monitoring/`, buat dua folder baru:
   *   `backend`
   *   `frontend` (di dalam `frontend`, buat lagi folder `dist`)
7. Di panel sebelah kiri (Laptop Anda), cari lokasi file proyek Anda.
8. **Kirim file**:
   *   Seret (*drag*) semua file dari folder **`backend`** laptop Anda (KECUALI folder `node_modules` dan file `.env`) dan lepaskan (*drop*) ke folder `/var/www/leads-monitoring/backend/` di server.
   *   Seret isi dari folder **`frontend/dist`** laptop Anda dan masukkan ke folder `/var/www/leads-monitoring/frontend/dist/` di server.

---

## 🖥️ LANGKAH 3: Setting Server (Tinggal Copy-Paste)

Buka aplikasi **Terminal** (Mac/Linux) atau **Command Prompt/PuTTY** (Windows), lalu hubungkan ke server Anda:
```bash
ssh root@<IP_VPS_BARU>
```

Salin dan tempel perintah-perintah di bawah ini ke dalam terminal server satu per satu:

### A. Instalasi Node.js, PM2 (Penjaga Server), dan Database MySQL
```bash
# 1. Update sistem server
apt update && apt upgrade -y

# 2. Instal Node.js (mesin server javascript)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# 3. Instal PM2 agar backend tetap berjalan saat terminal ditutup
npm install -g pm2

# 4. Instal database MySQL
apt install -y mysql-server
```

### B. Membuat Database Baru
Jalankan perintah ini untuk masuk ke database server:
```bash
sudo mysql
```
Salin blok perintah SQL di bawah ini, tempel ke dalam MySQL, lalu tekan Enter:
```sql
-- Membuat database baru
CREATE DATABASE IF NOT EXISTS leads_monitoring CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Membuat user database baru dengan nama 'esurat' dan password 'esurat2025!'
CREATE USER IF NOT EXISTS 'esurat'@'localhost' IDENTIFIED BY 'esurat2025!';
GRANT ALL PRIVILEGES ON leads_monitoring.* TO 'esurat'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

Setelah keluar dari MySQL, jalankan perintah ini untuk membuat tabel otomatis:
```bash
mysql -u esurat -pesurat2025! leads_monitoring < /var/www/leads-monitoring/backend/schema.sql
```

### C. Menulis File Konfigurasi (.env) di Server
Buat file konfigurasi rahasia di server menggunakan editor teks nano:
```bash
nano /var/www/leads-monitoring/backend/.env
```
Salin teks di bawah ini dan tempelkan ke dalam editor tersebut:
```env
PORT=18791
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=esurat
DB_PASSWORD=esurat2025!
DB_NAME=leads_monitoring
JWT_SECRET=leads_monitoring_secret_key_12345
```
*Cara menyimpan: Tekan `Ctrl + O` lalu Enter. Cara keluar: Tekan `Ctrl + X`.*

### D. Menyalakan Aplikasi Secara Permanen
```bash
# Masuk ke folder backend di server
cd /var/www/leads-monitoring/backend

# Instal modul pendukung
npm install --omit=dev

# Jalankan server
pm2 start server.js --name "leads-monitoring"

# Simpan agar otomatis menyala saat server restart
pm2 save
pm2 startup
```
*(Jika muncul perintah tambahan dari `pm2 startup` di layar, salin dan jalankan perintah tersebut).*

### E. Membuka Pintu Akses (Firewall)
Jalankan perintah ini agar orang luar bisa membuka halaman web dan aplikasi Anda:
```bash
iptables -I INPUT -p tcp --dport 18791 -j ACCEPT
```

---

## 📱 LANGKAH 4: Konfigurasi Aplikasi HP (Flutter) di Laptop

Sekarang, kembali ke laptop Anda untuk menyambungkan aplikasi HP Anda ke server baru.

### A. Ubah IP Server di Aplikasi HP
Buka folder proyek aplikasi Flutter Anda di laptop, cari 3 file berikut, lalu ubah alamat IP-nya menjadi IP VPS Baru Anda:

1.  **`lib/services/report_service.dart`** (Baris 7):
    ```dart
    static const String apiBaseUrl = 'http://<IP_VPS_BARU>:18791/api';
    ```
2.  **`lib/providers/leads_provider.dart`** (Baris 12):
    ```dart
    static const String apiBaseUrl = 'http://<IP_VPS_BARU>:18791/api';
    ```
3.  **`lib/providers/auth_provider.dart`** (Baris 7):
    ```dart
    static const String apiBaseUrl = 'http://<IP_VPS_BARU>:18791/api';
    ```

### B. Membuat File APK Jadi
1. Buka terminal/Command Prompt di laptop Anda.
2. Masuk ke folder utama proyek Anda:
   ```bash
   cd [JALUR_FOLDER_PROYEK_ANDA]
   ```
3. Jalankan perintah kompilasi:
   ```bash
   flutter pub get
   flutter build apk --release
   ```

### C. Memasang di HP Anda
File APK siap instal telah dibuat. Anda bisa mengambilnya di folder:
`build/app/outputs/flutter-apk/app-release.apk`

Kirim file tersebut ke HP Android Anda lewat WhatsApp, Google Drive, atau kabel USB, lalu instal seperti biasa.

---
