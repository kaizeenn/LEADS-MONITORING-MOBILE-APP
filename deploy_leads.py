#!/usr/bin/env python3
"""
Script deploy Leads Monitoring ke VPS via SSH (paramiko)
"""
import paramiko
import sys
import os
import io
import time

VPS_HOST = "202.10.41.37"
VPS_USER = "root"
VPS_PASS = "235115"
VPS_APP_DIR = "/var/www/leads-monitoring"
LOCAL_PROJECT = "/home/yume/Me/Task/Project/LEADS MONITORING MOBILE APP"
PORT = "18791"

def run(ssh, cmd, show=True):
    print(f"\n>>> {cmd}")
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=120, get_pty=True)
    out = stdout.read().decode(errors='ignore')
    err = stderr.read().decode(errors='ignore')
    if out and show:
        print(out)
    if err and show:
        print("[ERR]", err)
    return out, err

def connect():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"🔗 Connecting to {VPS_HOST}...")
    ssh.connect(VPS_HOST, username=VPS_USER, password=VPS_PASS, timeout=15)
    print("✅ Connected!")
    return ssh

def upload_backend(ssh):
    """Upload folder backend ke VPS via SFTP"""
    sftp = ssh.open_sftp()
    
    # Buat direktori jika belum ada
    run(ssh, f"mkdir -p {VPS_APP_DIR}/backend {VPS_APP_DIR}/frontend/dist", show=False)
    
    backend_dir = os.path.join(LOCAL_PROJECT, "backend")
    vps_backend = f"{VPS_APP_DIR}/backend"
    
    # File yang perlu diupload (exclude node_modules, .env, dll)
    skip_dirs = {'node_modules', '.git', '__pycache__'}
    skip_files = {'.env'}
    
    uploaded = 0
    for root, dirs, files in os.walk(backend_dir):
      dirs[:] = [d for d in dirs if d not in skip_dirs]
      rel_root = os.path.relpath(root, backend_dir)
      vps_root = f"{vps_backend}/{rel_root}" if rel_root != '.' else vps_backend
      
      try:
        sftp.mkdir(vps_root)
      except:
        pass
      
      for fname in files:
        if fname in skip_files:
          continue
        local_path = os.path.join(root, fname)
        vps_path = f"{vps_root}/{fname}"
        try:
          sftp.put(local_path, vps_path)
          uploaded += 1
        except Exception as e:
          print(f"  ⚠️ Skip {fname}: {e}")
              
    print(f"  ✅ Total {uploaded} files uploaded ke backend")
    sftp.close()

def upload_frontend_dist(ssh):
    """Upload folder frontend/dist ke VPS"""
    sftp = ssh.open_sftp()
    
    dist_dir = os.path.join(LOCAL_PROJECT, "frontend", "dist")
    vps_dist = f"{VPS_APP_DIR}/frontend/dist"
    
    run(ssh, f"rm -rf {vps_dist} && mkdir -p {vps_dist}", show=False)
    
    uploaded = 0
    for root, dirs, files in os.walk(dist_dir):
        rel_root = os.path.relpath(root, dist_dir)
        vps_root = f"{vps_dist}/{rel_root}" if rel_root != '.' else vps_dist
        
        try:
            sftp.mkdir(vps_root)
        except:
            pass
        
        for fname in files:
            local_path = os.path.join(root, fname)
            vps_path = f"{vps_root}/{fname}"
            try:
                sftp.put(local_path, vps_path)
                uploaded += 1
            except Exception as e:
                print(f"  ⚠️ Skip {fname}: {e}")
                
    print(f"  ✅ Total {uploaded} files frontend dist uploaded")
    sftp.close()

def main():
    print("=" * 55)
    print("  🚀 DEPLOY LEADS MONITORING ke VPS")
    print("=" * 55)
    
    ssh = connect()
    
    # 1. Pastikan port 18791 bebas
    print("\n📊 [1/6] Cek kondisi port 18791...")
    run(ssh, f"ss -tlnp | grep {PORT} || echo 'Port {PORT} bebas'")
    
    # 2. Buat database & import schema
    print("\n📦 [2/6] Setup database MySQL...")
    
    # Jalankan query buat DB & berikan privilage jika belum
    fix_mysql = run(ssh, f"""mysql --skip-ssl -u esurat -pesurat2025! -e "
CREATE DATABASE IF NOT EXISTS leads_monitoring CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON leads_monitoring.* TO 'esurat'@'localhost';
FLUSH PRIVILEGES;
" 2>&1""")
    
    # 3. Upload files
    print("\n📤 [3/6] Upload files backend & frontend dist...")
    upload_backend(ssh)
    upload_frontend_dist(ssh)
    
    # Buat file schema di VPS agar bisa diimport langsung
    sftp = ssh.open_sftp()
    sftp.put(os.path.join(LOCAL_PROJECT, "backend", "schema.sql"), f"{VPS_APP_DIR}/backend/schema.sql")
    sftp.close()
    
    # Import schema ke database
    print("  📥 Mengimpor schema database...")
    run(ssh, f"mysql --skip-ssl -u esurat -pesurat2025! leads_monitoring < {VPS_APP_DIR}/backend/schema.sql 2>&1")
    
    # 4. Buat file .env di VPS
    print("\n⚙️ [4/6] Konfigurasi file .env...")
    vps_env = f"""PORT={PORT}
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=esurat
DB_PASSWORD=esurat2025!
DB_NAME=leads_monitoring
JWT_SECRET=leads_monitoring_secret_key_12345
"""
    sftp = ssh.open_sftp()
    sftp.putfo(io.BytesIO(vps_env.encode()), f"{VPS_APP_DIR}/backend/.env")
    sftp.close()
    print("  ✅ .env berhasil ditulis")
    
    # 5. Install dependencies di VPS
    print("\n📦 [5/6] Install npm dependencies di VPS...")
    run(ssh, f"cd {VPS_APP_DIR}/backend && npm install --omit=dev 2>&1 | tail -5")
    
    # 6. PM2 setup & start
    print("\n🚀 [6/6] Menjalankan backend dengan PM2...")
    run(ssh, f"pm2 delete leads-monitoring 2>/dev/null || true")
    run(ssh, f"cd {VPS_APP_DIR}/backend && pm2 start server.js --name 'leads-monitoring'")
    run(ssh, "pm2 save")
    
    # Buka firewall port 18791
    print("\n🛡️ Membuka port 18791 di Firewall...")
    run(ssh, f"iptables -I INPUT -p tcp --dport {PORT} -j ACCEPT || true")
    
    time.sleep(3)
    
    # Verifikasi
    print("\n✅ VERIFIKASI AKHIR:")
    run(ssh, "pm2 list")
    health = run(ssh, f"curl -s --max-time 5 http://127.0.0.1:{PORT}/api/health 2>&1")
    print("Health check:", health)
    
    ssh.close()
    print("\n" + "=" * 55)
    print("  🎉 Deploy Leads Monitoring selesai!")
    print(f"  🌐 Akses Web Dashboard: http://202.10.41.37:{PORT}")
    print("=" * 55)

if __name__ == "__main__":
    main()
