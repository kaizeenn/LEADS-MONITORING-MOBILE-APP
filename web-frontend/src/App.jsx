import React, { useState, useEffect, useCallback, useRef } from 'react';
import { 
  LogOut, 
  Plus, 
  MapPin, 
  Share2, 
  Calendar, 
  TrendingUp, 
  Users, 
  Edit2, 
  Trash2, 
  Filter, 
  User, 
  Lock, 
  Mail, 
  Check, 
  AlertCircle,
  X,
  FileText,
  Bus,
  FileSpreadsheet,
  ChevronDown
} from 'lucide-react';
import * as XLSX from 'xlsx';

const API_URL = 'http://localhost:3000/api';

// Beautiful Custom React Dropdown Component
function CustomSelect({ value, onChange, options, placeholder }) {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef(null);

  useEffect(() => {
    function handleClickOutside(event) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const selectedOption = options.find(opt => String(opt.value) === String(value));

  return (
    <div className="custom-select-container" ref={dropdownRef}>
      <div className={`custom-select-trigger ${isOpen ? 'open' : ''}`} onClick={() => setIsOpen(!isOpen)}>
        <span>{selectedOption ? selectedOption.label : placeholder}</span>
        <ChevronDown size={14} className={`custom-select-arrow ${isOpen ? 'open' : ''}`} />
      </div>
      {isOpen && (
        <div className="custom-select-options">
          {options.map((opt) => (
            <div 
              key={opt.value} 
              className={`custom-select-option ${String(opt.value) === String(value) ? 'selected' : ''}`}
              onClick={() => {
                onChange(opt.value);
                setIsOpen(false);
              }}
            >
              {opt.label}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default function App() {
  const [token, setToken] = useState(localStorage.getItem('token') || '');
  const [user, setUser] = useState(null);
  
  // Auth state
  const [loginUsername, setLoginUsername] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [authError, setAuthError] = useState('');
  const [authLoading, setAuthLoading] = useState(false);

  // App data state
  const [leads, setLeads] = useState([]);
  const [wilayah, setWilayah] = useState([]);
  const [sumber, setSumber] = useState([]);
  const [dashboardStats, setDashboardStats] = useState(null);
  const [loading, setLoading] = useState(false);

  // Active Division Tab
  const [activeDivisi, setActiveDivisi] = useState('marketing');

  // Filters
  const [filterWilayah, setFilterWilayah] = useState('');
  const [filterSumber, setFilterSumber] = useState('');
  const [filterStartDate, setFilterStartDate] = useState('');
  const [filterEndDate, setFilterEndDate] = useState('');
  const [filterLokasi, setFilterLokasi] = useState('');

  // Modals state
  const [isLeadModalOpen, setIsLeadModalOpen] = useState(false);
  const [editingLead, setEditingLead] = useState(null);
  const [isWilayahModalOpen, setIsWilayahModalOpen] = useState(false);
  const [isSumberModalOpen, setIsSumberModalOpen] = useState(false);
  const [isUserModalOpen, setIsUserModalOpen] = useState(false);

  // User Management State
  const [usersList, setUsersList] = useState([]);
  const [newUserName, setNewUserName] = useState('');
  const [newUserUsername, setNewUserUsername] = useState('');
  const [newUserPassword, setNewUserPassword] = useState('');
  const [newUserRole, setNewUserRole] = useState('karyawan');
  const [newUserBagian, setNewUserBagian] = useState('marketing');
  const [userError, setUserError] = useState('');

  // Toast state
  const [toast, setToast] = useState(null);
  const showToast = (message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => {
      setToast(null);
    }, 3000);
  };

  // Lead Form
  const [formWilayahId, setFormWilayahId] = useState('');
  const [formSumberId, setFormSumberId] = useState('');
  const [formTanggal, setFormTanggal] = useState(new Date().toISOString().split('T')[0]);
  const [formJumlah, setFormJumlah] = useState('');
  const [formLokasi, setFormLokasi] = useState('');
  const [formNamaClient, setFormNamaClient] = useState('');
  const [formAsalClient, setFormAsalClient] = useState('');
  const [formNoHpClient, setFormNoHpClient] = useState('');
  const [formError, setFormError] = useState('');
  const [formLoading, setFormLoading] = useState(false);

  // Wilayah/Sumber Manage Form
  const [newWilayahName, setNewWilayahName] = useState('');
  const [newSumberName, setNewSumberName] = useState('');
  const [manageError, setManageError] = useState('');

  // Fetch current user details
  const fetchUser = useCallback(async (tokenStr) => {
    try {
      const res = await fetch(`${API_URL}/auth/me`, {
        headers: { 'Authorization': `Bearer ${tokenStr}` }
      });
      const data = await res.json();
      if (res.ok) {
        setUser(data.user);
        if (data.user.role === 'karyawan') {
          setActiveDivisi(data.user.bagian || 'marketing');
        }
      } else {
        handleLogout();
      }
    } catch (e) {
      handleLogout();
    }
  }, []);

  // Fetch all dashboard & list data
  const fetchData = useCallback(async () => {
    if (!token) return;
    setLoading(true);
    try {
      const headers = { 'Authorization': `Bearer ${token}` };

      // Build query string for leads filter
      let query = '';
      const params = [];
      if (activeDivisi === 'marketing') {
        if (filterWilayah) params.push(`wilayah_id=${filterWilayah}`);
      } else {
        if (filterLokasi) params.push(`lokasi=${filterLokasi}`);
      }
      if (filterSumber) params.push(`sumber_id=${filterSumber}`);
      if (filterStartDate) params.push(`startDate=${filterStartDate}`);
      if (filterEndDate) params.push(`endDate=${filterEndDate}`);
      if (params.length > 0) query = '?' + params.join('&');

      const statsUrl = activeDivisi === 'marketing' 
        ? `${API_URL}/dashboard` 
        : `${API_URL}/dashboard-tour`;

      const leadsUrl = activeDivisi === 'marketing'
        ? `${API_URL}/leads${query}`
        : `${API_URL}/leads-tour${query}`;

      // Parallel requests
      const promises = [
        fetch(statsUrl, { headers }),
        fetch(leadsUrl, { headers }),
        fetch(`${API_URL}/wilayah`, { headers }),
        fetch(`${API_URL}/sumber`, { headers })
      ];

      const isAdmin = user && user.role === 'admin';
      if (isAdmin) {
        promises.push(fetch(`${API_URL}/users`, { headers }));
      }

      const responses = await Promise.all(promises);

      const dataStats = await responses[0].json();
      const dataLeads = await responses[1].json();
      const dataWilayah = await responses[2].json();
      const dataSumber = await responses[3].json();

      if (responses[0].ok) setDashboardStats(dataStats);
      if (responses[1].ok) setLeads(dataLeads);
      if (responses[2].ok) setWilayah(dataWilayah);
      if (responses[3].ok) setSumber(dataSumber);

      if (isAdmin && responses[4]) {
        const dataUsers = await responses[4].json();
        if (responses[4].ok) setUsersList(dataUsers);
      }

    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  }, [token, activeDivisi, filterWilayah, filterLokasi, filterSumber, filterStartDate, filterEndDate, user]);

  useEffect(() => {
    if (token) {
      fetchUser(token);
    }
  }, [token, fetchUser]);

  useEffect(() => {
    if (token && user) {
      fetchData();
    }
  }, [token, user, fetchData]);

  // Auth Handlers
  const handleLogin = async (e) => {
    e.preventDefault();
    if (!loginUsername || !loginPassword) {
      setAuthError('Username dan password wajib diisi.');
      return;
    }
    setAuthLoading(true);
    setAuthError('');
    try {
      const res = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: loginUsername, password: loginPassword })
      });
      const data = await res.json();
      if (res.ok) {
        localStorage.setItem('token', data.token);
        setToken(data.token);
        setUser(data.user);
        setLoginPassword('');
        if (data.user.role === 'karyawan') {
          setActiveDivisi(data.user.bagian || 'marketing');
        } else {
          setActiveDivisi('marketing');
        }
      } else {
        setAuthError(data.error || 'Login gagal.');
      }
    } catch (err) {
      setAuthError('Gagal terhubung ke server.');
    } finally {
      setAuthLoading(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    setToken('');
    setUser(null);
    setDashboardStats(null);
    setLeads([]);
  };

  // Lead CRUD Handlers
  const handleOpenLeadModal = (lead = null) => {
    if (lead) {
      setEditingLead(lead);
      setFormSumberId(lead.sumber_id);
      setFormTanggal(lead.tanggal.split('T')[0]);
      if (activeDivisi === 'marketing') {
        setFormWilayahId(lead.wilayah_id);
        setFormJumlah(lead.jumlah);
      } else {
        setFormLokasi(lead.lokasi);
        setFormNamaClient(lead.nama_client);
        setFormAsalClient(lead.asal_client);
        setFormNoHpClient(lead.no_hp_client);
      }
    } else {
      setEditingLead(null);
      setFormWilayahId('');
      setFormSumberId('');
      setFormTanggal(new Date().toISOString().split('T')[0]);
      setFormJumlah('');
      setFormLokasi('');
      setFormNamaClient('');
      setFormAsalClient('');
      setFormNoHpClient('');
    }
    setFormError('');
    setIsLeadModalOpen(true);
  };

  const handleSaveLead = async (e) => {
    e.preventDefault();
    if (activeDivisi === 'marketing') {
      if (!formWilayahId || !formSumberId || !formTanggal || formJumlah === '') {
        setFormError('Semua kolom wajib diisi.');
        return;
      }
    } else {
      if (!formLokasi || !formSumberId || !formTanggal || !formNamaClient || !formAsalClient || !formNoHpClient) {
        setFormError('Semua kolom wajib diisi.');
        return;
      }
    }

    setFormLoading(true);
    setFormError('');
    try {
      const method = editingLead ? 'PUT' : 'POST';
      const url = activeDivisi === 'marketing'
        ? (editingLead ? `${API_URL}/leads/${editingLead.id}` : `${API_URL}/leads`)
        : (editingLead ? `${API_URL}/leads-tour/${editingLead.id}` : `${API_URL}/leads-tour`);
      
      const payload = activeDivisi === 'marketing'
        ? {
            wilayah_id: parseInt(formWilayahId),
            sumber_id: parseInt(formSumberId),
            tanggal: formTanggal,
            jumlah: parseInt(formJumlah)
          }
        : {
            lokasi: formLokasi.trim(),
            sumber_id: parseInt(formSumberId),
            tanggal: formTanggal,
            nama_client: formNamaClient.trim(),
            asal_client: formAsalClient.trim(),
            no_hp_client: formNoHpClient.trim()
          };

      const res = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(payload)
      });

      const data = await res.json();
      if (res.ok) {
        setIsLeadModalOpen(false);
        showToast(editingLead ? 'Data lead berhasil diperbarui!' : 'Data lead berhasil disimpan!', 'success');
        fetchData();
      } else {
        setFormError(data.error || 'Gagal menyimpan data.');
      }
    } catch (e) {
      setFormError('Gagal terhubung ke server.');
    } finally {
      setFormLoading(false);
    }
  };

  const handleDeleteLead = async (id) => {
    if (!confirm('Apakah Anda yakin ingin menghapus data lead ini?')) return;
    try {
      const url = activeDivisi === 'marketing' ? `${API_URL}/leads/${id}` : `${API_URL}/leads-tour/${id}`;
      const res = await fetch(url, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.ok) {
        showToast('Data lead berhasil dihapus!', 'success');
        fetchData();
      } else {
        const data = await res.json();
        showToast(data.error || 'Gagal menghapus lead.', 'error');
      }
    } catch (e) {
      alert('Gagal terhubung ke server.');
    }
  };

  // Wilayah Handlers
  const handleAddWilayah = async (e) => {
    e.preventDefault();
    if (!newWilayahName.trim()) return;
    setManageError('');
    try {
      const res = await fetch(`${API_URL}/wilayah`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ nama_wilayah: newWilayahName.trim() })
      });
      const data = await res.json();
      if (res.ok) {
        setNewWilayahName('');
        showToast('Wilayah pariwisata berhasil ditambahkan!', 'success');
        fetchData();
      } else {
        setManageError(data.error || 'Gagal menambahkan wilayah.');
      }
    } catch (e) {
      setManageError('Gagal terhubung ke server.');
    }
  };

  const handleDeleteWilayah = async (id) => {
    if (!confirm('Apakah Anda yakin ingin menghapus wilayah pariwisata ini?')) return;
    setManageError('');
    try {
      const res = await fetch(`${API_URL}/wilayah/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) {
        showToast('Wilayah pariwisata berhasil dihapus!', 'success');
        fetchData();
      } else {
        setManageError(data.error || 'Gagal menghapus wilayah.');
      }
    } catch (e) {
      setManageError('Gagal terhubung ke server.');
    }
  };

  // Sumber Handlers
  const handleAddSumber = async (e) => {
    e.preventDefault();
    if (!newSumberName.trim()) return;
    setManageError('');
    try {
      const res = await fetch(`${API_URL}/sumber`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ nama_sumber: newSumberName.trim() })
      });
      const data = await res.json();
      if (res.ok) {
        setNewSumberName('');
        showToast('Sumber leads berhasil ditambahkan!', 'success');
        fetchData();
      } else {
        setManageError(data.error || 'Gagal menambahkan sumber.');
      }
    } catch (e) {
      setManageError('Gagal terhubung ke server.');
    }
  };

  const handleDeleteSumber = async (id) => {
    if (!confirm('Apakah Anda yakin ingin menghapus sumber leads ini?')) return;
    setManageError('');
    try {
      const res = await fetch(`${API_URL}/sumber/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) {
        showToast('Sumber leads berhasil dihapus!', 'success');
        fetchData();
      } else {
        setManageError(data.error || 'Gagal menghapus sumber.');
      }
    } catch (e) {
      setManageError('Gagal terhubung ke server.');
    }
  };

  // User Handlers (Admin Only)
  const handleAddUser = async (e) => {
    e.preventDefault();
    if (!newUserName.trim() || !newUserUsername.trim() || !newUserPassword.trim() || !newUserRole) {
      setUserError('Semua kolom wajib diisi.');
      return;
    }
    setUserError('');
    try {
      const res = await fetch(`${API_URL}/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          nama_lengkap: newUserName.trim(),
          username: newUserUsername.trim(),
          password: newUserPassword.trim(),
          role: newUserRole,
          bagian: newUserRole === 'admin' ? null : newUserBagian
        })
      });
      const data = await res.json();
      if (res.ok) {
        setNewUserName('');
        setNewUserUsername('');
        setNewUserPassword('');
        setNewUserRole('karyawan');
        setNewUserBagian('marketing');
        showToast('Akun user baru berhasil dibuat!', 'success');
        fetchData();
      } else {
        setUserError(data.error || 'Gagal menambahkan user.');
      }
    } catch (e) {
      setUserError('Gagal terhubung ke server.');
    }
  };

  const handleDeleteUser = async (id) => {
    if (!confirm('Apakah Anda yakin ingin menghapus akun user ini?')) return;
    setUserError('');
    try {
      const res = await fetch(`${API_URL}/users/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) {
        showToast('Akun user berhasil dihapus!', 'success');
        fetchData();
      } else {
        setUserError(data.error || 'Gagal menghapus user.');
      }
    } catch (e) {
      setUserError('Gagal terhubung ke server.');
    }
  };

  // Format date helper
  const formatDateStr = (dateStr) => {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = String(date.getFullYear()).substring(2, 4);
    return `${day}/${month}/${year}`;
  };

  // Calculate sum of visible leads
  const totalLeadsSum = leads.reduce((sum, lead) => sum + lead.jumlah, 0);

  // Export to Excel handler
  const exportToExcel = () => {
    if (leads.length === 0) {
      alert('Tidak ada data leads untuk diekspor.');
      return;
    }

    const dataToExport = leads.map(lead => ({
      'Tanggal': formatDateStr(lead.tanggal),
      'Nama Wilayah': lead.nama_wilayah,
      'Sumber Leads': lead.nama_sumber,
      'Inputter': lead.nama_inputter,
      'Jumlah': lead.jumlah
    }));

    // Tambah baris total di paling bawah
    dataToExport.push({
      'Tanggal': 'TOTAL JUMLAH LEADS',
      'Nama Wilayah': '',
      'Sumber Leads': '',
      'Inputter': '',
      'Jumlah': totalLeadsSum
    });

    const worksheet = XLSX.utils.json_to_sheet(dataToExport);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Data Leads');
    XLSX.writeFile(workbook, 'leads-report-web.xlsx');
  };

  // SVG Chart Helpers
  const renderLineChart = () => {
    if (!dashboardStats || !dashboardStats.dailyTrend || dashboardStats.dailyTrend.length === 0) {
      return <div className="text-muted text-center pt-8">Tidak ada data trend</div>;
    }

    const data = dashboardStats.dailyTrend;
    const maxVal = Math.max(...data.map(d => d.total), 5);
    const height = 180;
    const width = 500;
    const padding = 20;

    const points = data.map((d, i) => {
      const x = padding + (i * (width - padding * 2) / (data.length - 1 || 1));
      const y = height - padding - (d.total * (height - padding * 2) / maxVal);
      return { x, y, total: d.total, label: d.label };
    });

    let pathD = `M ${points[0].x} ${points[0].y} `;
    for (let i = 1; i < points.length; i++) {
      pathD += `L ${points[i].x} ${points[i].y} `;
    }

    // Fill path D
    const fillD = `${pathD} L ${points[points.length - 1].x} ${height - padding} L ${points[0].x} ${height - padding} Z`;

    return (
      <svg viewBox={`0 0 ${width} ${height}`} className="w-full h-full">
        {/* Grids */}
        {[0, 0.25, 0.5, 0.75, 1].map((r, i) => (
          <line 
            key={i}
            x1={padding}
            y1={padding + r * (height - padding * 2)}
            x2={width - padding}
            y2={padding + r * (height - padding * 2)}
            stroke="#E2E8F0"
            strokeWidth="1"
            strokeDasharray="4"
          />
        ))}

        {/* Shading area */}
        <path d={fillD} fill="url(#lineGradientFill)" />

        {/* Trend line */}
        <path d={pathD} fill="none" stroke="#0F4C81" strokeWidth="3" strokeLinecap="round" />

        {/* Nodes and tooltip labels */}
        {points.map((p, i) => (
          <g key={i}>
            <circle cx={p.x} cy={p.y} r="5" fill="#ffffff" stroke="#0F4C81" strokeWidth="2.5" />
            <text x={p.x} y={height - 2} textAnchor="middle" fontSize="10" fill="#64748B" fontWeight="500">
              {p.label}
            </text>
            <text x={p.x} y={p.y - 10} textAnchor="middle" fontSize="9.5" fill="#0F4C81" fontWeight="700">
              {p.total}
            </text>
          </g>
        ))}

        <defs>
          <linearGradient id="lineGradientFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#0F4C81" stopOpacity="0.15" />
            <stop offset="100%" stopColor="#0F4C81" stopOpacity="0.0" />
          </linearGradient>
        </defs>
      </svg>
    );
  };

  const renderBarChart = () => {
    if (!dashboardStats || !dashboardStats.wilayahChart || dashboardStats.wilayahChart.length === 0) {
      return <div className="text-muted text-center pt-8">Tidak ada data wilayah</div>;
    }

    const data = dashboardStats.wilayahChart;
    const maxVal = Math.max(...data.map(d => d.total), 5);
    const height = 180;
    const width = 500;
    const padding = 20;

    const barWidth = 36;
    const spacing = (width - padding * 2) / data.length;

    return (
      <svg viewBox={`0 0 ${width} ${height}`} className="w-full h-full">
        {/* Horizontal Grids */}
        {[0, 0.25, 0.5, 0.75, 1].map((r, i) => (
          <line 
            key={i}
            x1={padding}
            y1={padding + r * (height - padding * 2)}
            x2={width - padding}
            y2={padding + r * (height - padding * 2)}
            stroke="#E2E8F0"
            strokeWidth="1"
          />
        ))}

        {data.map((d, i) => {
          const x = padding + i * spacing + (spacing - barWidth) / 2;
          const barHeight = (d.total * (height - padding * 2)) / maxVal;
          const y = height - padding - barHeight;

          return (
            <g key={i}>
              {/* Back Track */}
              <rect 
                x={x}
                y={padding}
                width={barWidth}
                height={height - padding * 2}
                fill="#F1F5F9"
                rx="4"
              />
              {/* Active Bar */}
              <rect 
                x={x}
                y={y}
                width={barWidth}
                height={barHeight}
                fill="#3AAFA9"
                rx="4"
              />
              {/* Teks jumlah */}
              <text x={x + barWidth/2} y={y - 8} textAnchor="middle" fontSize="10" fill="#2d8c87" fontWeight="700">
                {d.total}
              </text>
              {/* Teks label */}
              <text x={x + barWidth/2} y={height - 2} textAnchor="middle" fontSize="10" fill="#64748B" fontWeight="500">
                {d.nama_wilayah.substring(0, 8)}
              </text>
            </g>
          );
        })}
      </svg>
    );
  };

  // Render Auth UI
  if (!token || !user) {
    return (
      <div className="auth-container">
        <div className="auth-card">
          <div className="auth-header">
            <img src="/Icon Apps.png" alt="Apps Icon" style={{ height: '64px', marginBottom: '14px', objectFit: 'contain' }} />
            <h1 className="auth-title">Rekap Leads</h1>
            <p className="auth-subtitle">Masuk untuk mengelola data leads pariwisata</p>
          </div>

          {authError && (
            <div className="alert alert-danger">
              <AlertCircle size={18} />
              <span>{authError}</span>
            </div>
          )}

          <form onSubmit={handleLogin}>
            <div className="form-group">
              <label className="form-label">USERNAME</label>
              <div className="input-wrapper">
                <User className="input-icon" size={16} />
                <input 
                  type="text" 
                  className="form-control has-icon" 
                  placeholder="Masukkan username"
                  value={loginUsername}
                  onChange={(e) => setLoginUsername(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">PASSWORD</label>
              <div className="input-wrapper">
                <Lock className="input-icon" size={16} />
                <input 
                  type="password" 
                  className="form-control has-icon" 
                  placeholder="Masukkan password"
                  value={loginPassword}
                  onChange={(e) => setLoginPassword(e.target.value)}
                  required
                />
              </div>
            </div>

            <button type="submit" className="btn btn-primary btn-block mt-4" disabled={authLoading}>
              {authLoading ? 'Menghubungkan...' : 'Masuk ke Dashboard'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  // Render Dashboard UI
  return (
    <div className={`dashboard-wrapper theme-${activeDivisi}`}>
      {/* Header */}
      <header className="header">
        <div className="brand-wrapper" style={{ gap: '14px' }}>
          <img src="/Icon Apps.png" alt="Apps Icon" style={{ height: '36px', objectFit: 'contain' }} />
          <div>
            <h1 className="brand-title">Rekap Leads</h1>
            <p className="brand-subtitle">WEB PORTAL MONITORING</p>
          </div>
        </div>

        <div className="user-toolbar">
          <div className="user-badge">
            <div className="user-avatar">
              {user.nama_lengkap.substring(0, 2).toUpperCase()}
            </div>
            <div className="user-info">
              <span className="user-name">{user.nama_lengkap}</span>
              <span className="user-role">{user.role}</span>
            </div>
          </div>
          <button onClick={handleLogout} className="btn btn-outline" style={{ padding: '8px 16px', fontSize: '13.5px' }}>
            <LogOut size={16} />
            <span>Keluar</span>
          </button>
        </div>
      </header>

      {/* Admin Menu / Navigation Tab Bar */}
      {user.role === 'admin' && (
        <div className="admin-bar">
          <span className="admin-bar-label">PANEL ADMIN:</span>
          <button onClick={() => setIsUserModalOpen(true)} className="admin-btn">
            <Users size={14} className="text-muted" />
            <span>Kelola User</span>
          </button>
          <button onClick={() => setIsWilayahModalOpen(true)} className="admin-btn">
            <MapPin size={14} className="text-muted" />
            <span>Kelola Wilayah</span>
          </button>
          <button onClick={() => setIsSumberModalOpen(true)} className="admin-btn">
            <Share2 size={14} className="text-muted" />
            <span>Kelola Sumber</span>
          </button>
        </div>
      )}

      {/* Main Body */}
      <main className="main-content">
        
        {/* Tabs for Admin / Owner */}
        {(user.role === 'admin' || user.role === 'owner') && (
          <div className="tabs-container" style={{ display: 'flex', gap: '12px', marginBottom: '24px' }}>
            <button 
              onClick={() => {
                setActiveDivisi('marketing');
                setFilterWilayah('');
                setFilterSumber('');
                setFilterStartDate('');
                setFilterEndDate('');
                setFilterLokasi('');
              }} 
              className={`tab-btn ${activeDivisi === 'marketing' ? 'active' : ''}`}
            >
              Divisi Marketing
            </button>
            <button 
              onClick={() => {
                setActiveDivisi('tour');
                setFilterWilayah('');
                setFilterSumber('');
                setFilterStartDate('');
                setFilterEndDate('');
                setFilterLokasi('');
              }} 
              className={`tab-btn ${activeDivisi === 'tour' ? 'active' : ''}`}
            >
              Divisi Tour
            </button>
          </div>
        )}

        {/* Filter Bar */}
        <section className="filter-bar">
          {activeDivisi === 'marketing' ? (
            <div className="filter-item">
              <label className="form-label" style={{ marginBottom: '6px' }}>WILAYAH</label>
              <CustomSelect 
                value={filterWilayah} 
                onChange={setFilterWilayah} 
                options={[
                  { value: '', label: 'Semua Wilayah' },
                  ...wilayah.map(w => ({ value: String(w.id), label: w.nama_wilayah }))
                ]} 
                placeholder="Semua Wilayah" 
              />
            </div>
          ) : (
            <div className="filter-item">
              <label className="form-label" style={{ marginBottom: '6px' }}>LOKASI / DAERAH</label>
              <CustomSelect 
                value={filterLokasi} 
                onChange={setFilterLokasi} 
                options={[
                  { value: '', label: 'Semua Lokasi' },
                  { value: 'Bogor', label: 'Bogor' },
                  { value: 'Bandung', label: 'Bandung' },
                  { value: 'Jogja', label: 'Jogja' },
                  { value: 'Malang', label: 'Malang' },
                  { value: 'Bromo', label: 'Bromo' },
                  { value: 'Banyuwangi', label: 'Banyuwangi' },
                  { value: 'Bali', label: 'Bali' },
                  { value: 'Lombok', label: 'Lombok' },
                  { value: 'Labuan Bajo', label: 'Labuan Bajo' }
                ]} 
                placeholder="Semua Lokasi" 
              />
            </div>
          )}

          <div className="filter-item">
            <label className="form-label" style={{ marginBottom: '6px' }}>SUMBER LEADS</label>
            <CustomSelect 
              value={filterSumber} 
              onChange={setFilterSumber} 
              options={[
                { value: '', label: 'Semua Sumber' },
                ...sumber.map(s => ({ value: String(s.id), label: s.nama_sumber }))
              ]} 
              placeholder="Semua Sumber" 
            />
          </div>

          <div className="filter-item">
            <label className="form-label" style={{ marginBottom: '6px' }}>DARI TANGGAL</label>
            <input type="date" className="form-control" value={filterStartDate} onChange={(e) => setFilterStartDate(e.target.value)} />
          </div>

          <div className="filter-item">
            <label className="form-label" style={{ marginBottom: '6px' }}>SAMPAI TANGGAL</label>
            <input type="date" className="form-control" value={filterEndDate} onChange={(e) => setFilterEndDate(e.target.value)} />
          </div>

          <button onClick={() => {
            setFilterWilayah('');
            setFilterSumber('');
            setFilterStartDate('');
            setFilterEndDate('');
            setFilterLokasi('');
          }} className="btn btn-outline">
            Reset Filter
          </button>
        </section>

        {/* Stats Row */}
        {dashboardStats && (
          <section className="stats-grid">
            <div className="stat-card">
              <div className="stat-icon" style={{ background: 'rgba(15, 76, 129, 0.08)', color: 'var(--primary)' }}>
                <Calendar size={22} />
              </div>
              <div className="stat-info">
                <p className="stat-label">Hari Ini</p>
                <h3 className="stat-value">{dashboardStats.todayTotal}</h3>
              </div>
            </div>

            <div className="stat-card">
              <div className="stat-icon" style={{ background: 'rgba(58, 175, 169, 0.08)', color: 'var(--secondary)' }}>
                <TrendingUp size={22} />
              </div>
              <div className="stat-info">
                <p className="stat-label">Bulan Ini</p>
                <h3 className="stat-value">{dashboardStats.monthTotal}</h3>
              </div>
            </div>

            <div className="stat-card">
              <div className="stat-icon" style={{ background: 'rgba(16, 185, 129, 0.08)', color: 'var(--success)' }}>
                <FileText size={22} />
              </div>
              <div className="stat-info">
                <p className="stat-label">Tahun Ini</p>
                <h3 className="stat-value">{dashboardStats.yearTotal}</h3>
              </div>
            </div>

            <div className="stat-card">
              <div className="stat-icon" style={{ background: 'rgba(245, 158, 11, 0.08)', color: 'var(--warning)' }}>
                <MapPin size={22} />
              </div>
              <div className="stat-info">
                <p className="stat-label">{activeDivisi === 'marketing' ? 'Top Wilayah' : 'Top Lokasi'}</p>
                <h3 className="stat-value" style={{ fontSize: '16px' }}>{dashboardStats.bestWilayah}</h3>
              </div>
            </div>

            <div className="stat-card">
              <div className="stat-icon" style={{ background: 'rgba(156, 39, 176, 0.08)', color: '#9C27B0' }}>
                <Share2 size={22} />
              </div>
              <div className="stat-info">
                <p className="stat-label">Top Sumber</p>
                <h3 className="stat-value" style={{ fontSize: '16px' }}>{dashboardStats.bestSumber}</h3>
              </div>
            </div>
          </section>
        )}

        {/* Dashboard grid panel */}
        <div className="dashboard-grid">
          {/* Main Table Column */}
          <div className="panel">
            <div className="panel-header">
              <h2 className="panel-title">
                <FileText size={18} />
                <span>Detail Data Leads ({leads.length})</span>
              </h2>
              <div style={{ display: 'flex', gap: '10px' }}>
                {user.role !== 'owner' && (
                  <button onClick={() => handleOpenLeadModal()} className="btn btn-primary" style={{ padding: '8px 16px', fontSize: '13.5px' }}>
                    <Plus size={16} />
                    <span>Input Leads</span>
                  </button>
                )}
                <button onClick={exportToExcel} className="btn btn-outline" style={{ padding: '8px 16px', fontSize: '13.5px', borderColor: '#10B981', color: '#10B981', display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <FileSpreadsheet size={16} />
                  <span>Export Excel</span>
                </button>
              </div>
            </div>

            {loading ? (
              <div className="spinner"></div>
            ) : leads.length === 0 ? (
              <div className="text-muted text-center py-8">Belum ada data leads yang sesuai filter.</div>
            ) : (
              <div className="table-responsive">
                <table className="table">
                  <thead>
                    {activeDivisi === 'marketing' ? (
                      <tr>
                        <th>Tanggal</th>
                        <th>Wilayah</th>
                        <th>Sumber Leads</th>
                        <th>Inputter</th>
                        <th>Jumlah</th>
                        {user.role !== 'owner' && <th style={{ textAlign: 'right' }}>Aksi</th>}
                      </tr>
                    ) : (
                      <tr>
                        <th>Tanggal</th>
                        <th>Lokasi/Daerah</th>
                        <th>Sumber Leads</th>
                        <th>Nama/Instansi Client</th>
                        <th>Asal Client</th>
                        <th>No HP Client</th>
                        <th>Inputter</th>
                        {user.role !== 'owner' && <th style={{ textAlign: 'right' }}>Aksi</th>}
                      </tr>
                    )}
                  </thead>
                  <tbody>
                    {leads.map((lead, idx) => (
                      <tr key={lead.id} className={idx % 2 === 1 ? 'table-row-odd' : ''}>
                        <td>{formatDateStr(lead.tanggal)}</td>
                        {activeDivisi === 'marketing' ? (
                          <>
                            <td><strong>{lead.nama_wilayah}</strong></td>
                            <td><span className="text-muted">{lead.nama_sumber}</span></td>
                            <td>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                <User size={12} className="text-muted" />
                                <span style={{ fontSize: '12px' }}>{lead.nama_inputter}</span>
                              </div>
                            </td>
                            <td className="badge-lead">{lead.jumlah}</td>
                          </>
                        ) : (
                          <>
                            <td><strong>{lead.lokasi}</strong></td>
                            <td><span className="text-muted">{lead.nama_sumber}</span></td>
                            <td>{lead.nama_client}</td>
                            <td>{lead.asal_client}</td>
                            <td><span style={{ fontFamily: 'monospace' }}>{lead.no_hp_client}</span></td>
                            <td>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                <User size={12} className="text-muted" />
                                <span style={{ fontSize: '12px' }}>{lead.nama_inputter}</span>
                              </div>
                            </td>
                          </>
                        )}
                        {user.role !== 'owner' && (
                          <td style={{ textAlign: 'right' }}>
                            {(user.role === 'admin' || lead.user_id === user.id) && (
                              <div className="action-buttons" style={{ justifyContent: 'flex-end' }}>
                                <button onClick={() => handleOpenLeadModal(lead)} className="btn-icon btn-icon-primary" title="Edit">
                                  <Edit2 size={13} />
                                </button>
                                <button onClick={() => handleDeleteLead(lead.id)} className="btn-icon btn-icon-danger" title="Hapus">
                                  <Trash2 size={13} />
                                </button>
                              </div>
                            )}
                          </td>
                        )}
                      </tr>
                    ))}
                    {/* Total Row */}
                    <tr className="total-row">
                      <td colSpan={activeDivisi === 'marketing' ? 4 : 6}>TOTAL JUMLAH LEADS</td>
                      <td className="badge-lead" style={{ fontSize: '14.5px', color: 'var(--primary)' }}>
                        {activeDivisi === 'marketing' ? totalLeadsSum : leads.length}
                      </td>
                      {user.role !== 'owner' && <td></td>}
                    </tr>
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Sidebar Charts/Leaderboard Column */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            {/* Visualisations Panel */}
            <div className="panel">
              <h2 className="panel-title" style={{ marginBottom: '16px' }}>
                <TrendingUp size={18} />
                <span>Trend Leads Harian</span>
              </h2>
              <div className="chart-container">
                {renderLineChart()}
              </div>
            </div>

            <div className="panel">
              <h2 className="panel-title" style={{ marginBottom: '16px' }}>
                <MapPin size={18} />
                <span>{activeDivisi === 'marketing' ? 'Wilayah Teraktif (Top 5)' : 'Lokasi Teraktif (Top 5)'}</span>
              </h2>
              <div className="chart-container">
                {renderBarChart()}
              </div>
            </div>

            {/* Leaderboard Panel (Admin / Owner Only) */}
            {(user.role === 'admin' || user.role === 'owner') && dashboardStats && dashboardStats.leaderboard && (
              <div className="panel">
                <h2 className="panel-title" style={{ marginBottom: '16px' }}>
                  <Users size={18} />
                  <span>Leaderboard Input Karyawan</span>
                </h2>
                <div className="leaderboard-list">
                  {dashboardStats.leaderboard.length === 0 ? (
                    <p className="text-muted text-center py-4" style={{ fontSize: '13px' }}>Belum ada data input karyawan.</p>
                  ) : (
                    dashboardStats.leaderboard.map((item, idx) => (
                      <div key={idx} className="leaderboard-item">
                        <div style={{ display: 'flex', alignItems: 'center' }}>
                          <span className={`leaderboard-rank rank-${idx + 1}`}>{idx + 1}</span>
                          <div className="leaderboard-info">
                            <h4 className="leaderboard-name">{item.name}</h4>
                          </div>
                        </div>
                        <span className="leaderboard-score">{item.total} Leads</span>
                      </div>
                    ))
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      </main>

      {/* FOOTER WATERMARK */}
      <footer style={{ background: '#ffffff', borderTop: '1px solid var(--border)', padding: '16px', textAlign: 'center', fontSize: '11px', color: 'var(--text-muted)' }}>
        <p>Leads Monitoring App v1.0.0 &bull; <strong>Khairil Anwar PENS Sumenep</strong></p>
      </footer>

      {/* --- MODAL DIALOGS --- */}

      {/* 1. Add/Edit Lead Modal */}
      {isLeadModalOpen && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h3 className="modal-title">
                {editingLead 
                  ? (activeDivisi === 'marketing' ? 'Edit Data Lead Marketing' : 'Edit Data Lead Tour') 
                  : (activeDivisi === 'marketing' ? 'Input Data Lead Marketing' : 'Input Data Lead Tour')}
              </h3>
              <button className="modal-close" onClick={() => setIsLeadModalOpen(false)}>
                <X size={18} />
              </button>
            </div>

            {formError && (
              <div className="alert alert-danger" style={{ padding: '10px 14px', marginBottom: '16px' }}>
                <AlertCircle size={16} />
                <span>{formError}</span>
              </div>
            )}

            <form onSubmit={handleSaveLead}>
              {activeDivisi === 'marketing' ? (
                <>
                  <div className="form-group">
                    <label className="form-label">WILAYAH TUJUAN</label>
                    <CustomSelect 
                      value={formWilayahId} 
                      onChange={setFormWilayahId} 
                      options={wilayah.map(w => ({ value: String(w.id), label: w.nama_wilayah }))} 
                      placeholder="Pilih Wilayah" 
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">SUMBER LEADS</label>
                    <CustomSelect 
                      value={formSumberId} 
                      onChange={setFormSumberId} 
                      options={sumber.map(s => ({ value: String(s.id), label: s.nama_sumber }))} 
                      placeholder="Pilih Sumber" 
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">TANGGAL INPUT</label>
                    <input type="date" className="form-control" value={formTanggal} onChange={(e) => setFormTanggal(e.target.value)} required />
                  </div>

                  <div className="form-group">
                    <label className="form-label">JUMLAH LEADS</label>
                    <input 
                      type="number" 
                      min="1"
                      className="form-control" 
                      placeholder="Masukkan jumlah leads"
                      value={formJumlah} 
                      onChange={(e) => setFormJumlah(e.target.value)} 
                      required 
                    />
                  </div>
                </>
              ) : (
                <>
                  <div className="form-group">
                    <label className="form-label">LOKASI / DAERAH TUJUAN</label>
                    <CustomSelect 
                      value={formLokasi} 
                      onChange={setFormLokasi} 
                      options={[
                        { value: 'Bogor', label: 'Bogor' },
                        { value: 'Bandung', label: 'Bandung' },
                        { value: 'Jogja', label: 'Jogja' },
                        { value: 'Malang', label: 'Malang' },
                        { value: 'Bromo', label: 'Bromo' },
                        { value: 'Banyuwangi', label: 'Banyuwangi' },
                        { value: 'Bali', label: 'Bali' },
                        { value: 'Lombok', label: 'Lombok' },
                        { value: 'Labuan Bajo', label: 'Labuan Bajo' }
                      ]} 
                      placeholder="Pilih Lokasi" 
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">SUMBER LEADS</label>
                    <CustomSelect 
                      value={formSumberId} 
                      onChange={setFormSumberId} 
                      options={sumber.map(s => ({ value: String(s.id), label: s.nama_sumber }))} 
                      placeholder="Pilih Sumber" 
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">TANGGAL INPUT</label>
                    <input type="date" className="form-control" value={formTanggal} onChange={(e) => setFormTanggal(e.target.value)} required />
                  </div>

                  <div className="form-group">
                    <label className="form-label">NAMA / INSTANSI CLIENT</label>
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="Contoh: SMA 1 Surabaya / Bpk. Adi"
                      value={formNamaClient} 
                      onChange={(e) => setFormNamaClient(e.target.value)} 
                      required 
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">ASAL CLIENT (KOTA)</label>
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="Contoh: Sidoarjo"
                      value={formAsalClient} 
                      onChange={(e) => setFormAsalClient(e.target.value)} 
                      required 
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">NOMOR HP CLIENT</label>
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="Contoh: 08123456789"
                      value={formNoHpClient} 
                      onChange={(e) => setFormNoHpClient(e.target.value)} 
                      required 
                    />
                  </div>
                </>
              )}

              <div style={{ display: 'flex', gap: '12px', marginTop: '24px' }}>
                <button type="button" onClick={() => setIsLeadModalOpen(false)} className="btn btn-outline" style={{ flex: 1 }}>Batal</button>
                <button type="submit" className="btn btn-primary" style={{ flex: 1 }} disabled={formLoading}>
                  {formLoading ? 'Menyimpan...' : 'Simpan Data'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 2. Manage Wilayah Modal */}
      {isWilayahModalOpen && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h3 className="modal-title">Kelola Wilayah Pariwisata</h3>
              <button className="modal-close" onClick={() => setIsWilayahModalOpen(false)}>
                <X size={18} />
              </button>
            </div>

            {manageError && (
              <div className="alert alert-danger" style={{ padding: '10px 14px', marginBottom: '16px' }}>
                <AlertCircle size={16} />
                <span>{manageError}</span>
              </div>
            )}

            <form onSubmit={handleAddWilayah} style={{ display: 'flex', gap: '8px', marginBottom: '20px' }}>
              <input 
                type="text" 
                className="form-control" 
                placeholder="Nama wilayah baru"
                value={newWilayahName}
                onChange={(e) => setNewWilayahName(e.target.value)}
                required
              />
              <button type="submit" className="btn btn-primary" style={{ padding: '10px 18px' }}>Tambah</button>
            </form>

            <h4 className="form-label">DAFTAR WILAYAH</h4>
            <div className="manage-list">
              {wilayah.map(w => (
                <div key={w.id} className="manage-item">
                  <span className="manage-name">{w.nama_wilayah}</span>
                  <button onClick={() => handleDeleteWilayah(w.id)} className="btn-icon btn-icon-danger" title="Hapus">
                    <Trash2 size={12} />
                  </button>
                </div>
              ))}
            </div>

            <button type="button" onClick={() => setIsWilayahModalOpen(false)} className="btn btn-outline btn-block">Tutup</button>
          </div>
        </div>
      )}

      {/* 3. Manage Sumber Modal */}
      {isSumberModalOpen && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h3 className="modal-title">Kelola Sumber Leads</h3>
              <button className="modal-close" onClick={() => setIsSumberModalOpen(false)}>
                <X size={18} />
              </button>
            </div>

            {manageError && (
              <div className="alert alert-danger" style={{ padding: '10px 14px', marginBottom: '16px' }}>
                <AlertCircle size={16} />
                <span>{manageError}</span>
              </div>
            )}

            <form onSubmit={handleAddSumber} style={{ display: 'flex', gap: '8px', marginBottom: '20px' }}>
              <input 
                type="text" 
                className="form-control" 
                placeholder="Nama sumber baru"
                value={newSumberName}
                onChange={(e) => setNewSumberName(e.target.value)}
                required
              />
              <button type="submit" className="btn btn-primary" style={{ padding: '10px 18px' }}>Tambah</button>
            </form>

            <h4 className="form-label">DAFTAR SUMBER LEADS</h4>
            <div className="manage-list">
              {sumber.map(s => (
                <div key={s.id} className="manage-item">
                  <span className="manage-name">{s.nama_sumber}</span>
                  <button onClick={() => handleDeleteSumber(s.id)} className="btn-icon btn-icon-danger" title="Hapus">
                    <Trash2 size={12} />
                  </button>
                </div>
              ))}
            </div>

            <button type="button" onClick={() => setIsSumberModalOpen(false)} className="btn btn-outline btn-block">Tutup</button>
          </div>
        </div>
      )}

      {/* 4. Manage Users Modal (Admin Only) */}
      {isUserModalOpen && user.role === 'admin' && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '600px' }}>
            <div className="modal-header">
              <h3 className="modal-title">Kelola Akun User</h3>
              <button className="modal-close" onClick={() => setIsUserModalOpen(false)}>
                <X size={18} />
              </button>
            </div>

            {userError && (
              <div className="alert alert-danger" style={{ padding: '10px 14px', marginBottom: '16px' }}>
                <AlertCircle size={16} />
                <span>{userError}</span>
              </div>
            )}

            <form onSubmit={handleAddUser} style={{ marginBottom: '24px', background: '#F8FAFC', padding: '16px', borderRadius: '8px', border: '1px solid var(--border)' }}>
              <h4 className="form-label" style={{ marginBottom: '12px', color: 'var(--primary)', fontWeight: 'bold' }}>BUAT AKUN BARU</h4>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label" style={{ fontSize: '10.5px' }}>NAMA LENGKAP</label>
                  <input 
                    type="text" 
                    className="form-control" 
                    placeholder="Nama Karyawan"
                    value={newUserName}
                    onChange={(e) => setNewUserName(e.target.value)}
                    required
                  />
                </div>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label" style={{ fontSize: '10.5px' }}>USERNAME</label>
                  <input 
                    type="text" 
                    className="form-control" 
                    placeholder="Masukkan username"
                    value={newUserUsername}
                    onChange={(e) => setNewUserUsername(e.target.value)}
                    required
                  />
                </div>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '16px' }}>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label" style={{ fontSize: '10.5px' }}>PASSWORD</label>
                  <input 
                    type="password" 
                    className="form-control" 
                    placeholder="Minimal 6 karakter"
                    value={newUserPassword}
                    onChange={(e) => setNewUserPassword(e.target.value)}
                    required
                  />
                </div>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label" style={{ fontSize: '10.5px' }}>ROLE/HAK AKSES</label>
                  <CustomSelect 
                    value={newUserRole} 
                    onChange={setNewUserRole} 
                    options={[
                      { value: 'karyawan', label: 'Karyawan' },
                      { value: 'admin', label: 'Admin' },
                      { value: 'owner', label: 'Owner' }
                    ]} 
                    placeholder="Pilih Role" 
                  />
                </div>
              </div>
              {newUserRole === 'karyawan' && (
                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label className="form-label" style={{ fontSize: '10.5px' }}>BAGIAN/DIVISI</label>
                  <CustomSelect 
                    value={newUserBagian} 
                    onChange={setNewUserBagian} 
                    options={[
                      { value: 'marketing', label: 'Marketing' },
                      { value: 'tour', label: 'Tour' }
                    ]} 
                    placeholder="Pilih Bagian" 
                  />
                </div>
              )}
              <button type="submit" className="btn btn-primary btn-block">Tambah Akun Baru</button>
            </form>

            <h4 className="form-label">DAFTAR USER / KARYAWAN</h4>
            <div className="manage-list" style={{ maxHeight: '200px', overflowY: 'auto' }}>
              {usersList.map(u => (
                <div key={u.id} className="manage-item" style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 12px' }}>
                  <div>
                    <strong style={{ fontSize: '13.5px' }}>{u.nama_lengkap}</strong>
                    <div style={{ fontSize: '11.5px', color: 'var(--text-muted)' }}>
                      {u.username} &bull; <span className={`badge ${u.role === 'admin' ? 'badge-danger' : 'badge-primary'}`} style={{ fontSize: '10px', padding: '1px 6px', borderRadius: '4px', textTransform: 'uppercase' }}>{u.role}</span>
                      {u.bagian && <span className="badge" style={{ fontSize: '10px', padding: '1px 6px', borderRadius: '4px', textTransform: 'uppercase', background: 'rgba(13, 148, 136, 0.08)', color: 'var(--secondary)', marginLeft: '6px' }}>{u.bagian}</span>}
                    </div>
                  </div>
                  {user.id !== u.id && (
                    <button onClick={() => handleDeleteUser(u.id)} className="btn-icon btn-icon-danger" title="Hapus Akun">
                      <Trash2 size={12} />
                    </button>
                  )}
                </div>
              ))}
            </div>

            <button type="button" onClick={() => setIsUserModalOpen(false)} className="btn btn-outline btn-block" style={{ marginTop: '16px' }}>Tutup</button>
          </div>
        </div>
      )}

      {/* Floating Toast Notification */}
      {toast && (
        <div className={`toast-notification toast-${toast.type}`}>
          {toast.type === 'success' ? <Check size={16} /> : <AlertCircle size={16} />}
          <span>{toast.message}</span>
        </div>
      )}
    </div>
  );
}
