import React, { useState, useEffect, useCallback } from 'react';
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
  Bus
} from 'lucide-react';

const API_URL = 'http://localhost:3000/api';

export default function App() {
  const [token, setToken] = useState(localStorage.getItem('token') || '');
  const [user, setUser] = useState(null);
  
  // Auth state
  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [authError, setAuthError] = useState('');
  const [authLoading, setAuthLoading] = useState(false);

  // App data state
  const [leads, setLeads] = useState([]);
  const [wilayah, setWilayah] = useState([]);
  const [sumber, setSumber] = useState([]);
  const [dashboardStats, setDashboardStats] = useState(null);
  const [loading, setLoading] = useState(false);

  // Filters
  const [filterWilayah, setFilterWilayah] = useState('');
  const [filterSumber, setFilterSumber] = useState('');
  const [filterStartDate, setFilterStartDate] = useState('');
  const [filterEndDate, setFilterEndDate] = useState('');

  // Modals state
  const [isLeadModalOpen, setIsLeadModalOpen] = useState(false);
  const [editingLead, setEditingLead] = useState(null);
  const [isWilayahModalOpen, setIsWilayahModalOpen] = useState(false);
  const [isSumberModalOpen, setIsSumberModalOpen] = useState(false);

  // Lead Form
  const [formWilayahId, setFormWilayahId] = useState('');
  const [formSumberId, setFormSumberId] = useState('');
  const [formTanggal, setFormTanggal] = useState(new Date().toISOString().split('T')[0]);
  const [formJumlah, setFormJumlah] = useState('');
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
      if (filterWilayah) params.push(`wilayah_id=${filterWilayah}`);
      if (filterSumber) params.push(`sumber_id=${filterSumber}`);
      if (filterStartDate) params.push(`startDate=${filterStartDate}`);
      if (filterEndDate) params.push(`endDate=${filterEndDate}`);
      if (params.length > 0) query = '?' + params.join('&');

      // Parallel requests
      const [resStats, resLeads, resWilayah, resSumber] = await Promise.all([
        fetch(`${API_URL}/dashboard`, { headers }),
        fetch(`${API_URL}/leads${query}`, { headers }),
        fetch(`${API_URL}/wilayah`, { headers }),
        fetch(`${API_URL}/sumber`, { headers })
      ]);

      const dataStats = await resStats.json();
      const dataLeads = await resLeads.json();
      const dataWilayah = await resWilayah.json();
      const dataSumber = await resSumber.json();

      if (resStats.ok) setDashboardStats(dataStats);
      if (resLeads.ok) setLeads(dataLeads);
      if (resWilayah.ok) setWilayah(dataWilayah);
      if (resSumber.ok) setSumber(dataSumber);

    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  }, [token, filterWilayah, filterSumber, filterStartDate, filterEndDate]);

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
    if (!loginEmail || !loginPassword) {
      setAuthError('Email dan password wajib diisi.');
      return;
    }
    setAuthLoading(true);
    setAuthError('');
    try {
      const res = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: loginEmail, password: loginPassword })
      });
      const data = await res.json();
      if (res.ok) {
        localStorage.setItem('token', data.token);
        setToken(data.token);
        setUser(data.user);
        setLoginPassword('');
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
      setFormWilayahId(lead.wilayah_id);
      setFormSumberId(lead.sumber_id);
      setFormTanggal(lead.tanggal.split('T')[0]);
      setFormJumlah(lead.jumlah);
    } else {
      setEditingLead(null);
      setFormWilayahId('');
      setFormSumberId('');
      setFormTanggal(new Date().toISOString().split('T')[0]);
      setFormJumlah('');
    }
    setFormError('');
    setIsLeadModalOpen(true);
  };

  const handleSaveLead = async (e) => {
    e.preventDefault();
    if (!formWilayahId || !formSumberId || !formTanggal || formJumlah === '') {
      setFormError('Semua kolom wajib diisi.');
      return;
    }

    setFormLoading(true);
    setFormError('');
    try {
      const method = editingLead ? 'PUT' : 'POST';
      const url = editingLead ? `${API_URL}/leads/${editingLead.id}` : `${API_URL}/leads`;
      
      const res = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          wilayah_id: parseInt(formWilayahId),
          sumber_id: parseInt(formSumberId),
          tanggal: formTanggal,
          jumlah: parseInt(formJumlah)
        })
      });

      const data = await res.json();
      if (res.ok) {
        setIsLeadModalOpen(false);
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
      const res = await fetch(`${API_URL}/leads/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.ok) {
        fetchData();
      } else {
        const data = await res.json();
        alert(data.error || 'Gagal menghapus lead.');
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
        fetchData();
      } else {
        setManageError(data.error || 'Gagal menambahkan wilayah.');
      }
    } catch (e) {
      setManageError('Gagal terhubung ke server.');
    }
  };

  const handleDeleteWilayah = async (id) => {
    setManageError('');
    try {
      const res = await fetch(`${API_URL}/wilayah/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) {
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
        fetchData();
      } else {
        setManageError(data.error || 'Gagal menambahkan sumber.');
      }
    } catch (e) {
      setManageError('Gagal terhubung ke server.');
    }
  };

  const handleDeleteSumber = async (id) => {
    setManageError('');
    try {
      const res = await fetch(`${API_URL}/sumber/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) {
        fetchData();
      } else {
        setManageError(data.error || 'Gagal menghapus sumber.');
      }
    } catch (e) {
      setManageError('Gagal terhubung ke server.');
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
            <div className="auth-logo">
              <Bus size={28} />
            </div>
            <h1 className="auth-title">Leads Monitoring</h1>
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
              <label className="form-label">EMAIL</label>
              <div className="input-wrapper">
                <Mail className="input-icon" size={16} />
                <input 
                  type="email" 
                  className="form-control has-icon" 
                  placeholder="admin@leads.com"
                  value={loginEmail}
                  onChange={(e) => setLoginEmail(e.target.value)}
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
                  placeholder="••••••••"
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
    <div className="dashboard-wrapper">
      {/* Header */}
      <header className="header">
        <div className="brand-wrapper">
          <div className="brand-logo">
            <Bus size={22} />
          </div>
          <div>
            <h1 className="brand-title">Leads Pariwisata</h1>
            <p className="brand-subtitle">WEB PORTAL MONITORING</p>
          </div>
        </div>

        <div className="user-toolbar">
          <div className="user-badge">
            <div className="user-avatar">
              {user.name.substring(0, 2).toUpperCase()}
            </div>
            <div className="user-info">
              <span className="user-name">{user.name}</span>
              <span className="user-role">{user.role}</span>
            </div>
          </div>
          <button onClick={handleLogout} className="btn btn-outline" style={{ padding: '8px 16px', fontSize: '13.5px' }}>
            <LogOut size={16} />
            <span>Keluar</span>
          </button>
        </div>
      </header>

      {/* Main Body */}
      <main className="main-content">
        
        {/* Filter Bar */}
        <section className="filter-bar">
          <div className="filter-item">
            <label className="form-label" style={{ marginBottom: '6px' }}>WILAYAH</label>
            <select className="form-control" value={filterWilayah} onChange={(e) => setFilterWilayah(e.target.value)}>
              <option value="">Semua Wilayah</option>
              {wilayah.map(w => <option key={w.id} value={w.id}>{w.nama_wilayah}</option>)}
            </select>
          </div>

          <div className="filter-item">
            <label className="form-label" style={{ marginBottom: '6px' }}>SUMBER LEADS</label>
            <select className="form-control" value={filterSumber} onChange={(e) => setFilterSumber(e.target.value)}>
              <option value="">Semua Sumber</option>
              {sumber.map(s => <option key={s.id} value={s.id}>{s.nama_sumber}</option>)}
            </select>
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
                <p className="stat-label">Top Wilayah</p>
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
                <button onClick={() => handleOpenLeadModal()} className="btn btn-primary" style={{ padding: '8px 16px', fontSize: '13.5px' }}>
                  <Plus size={16} />
                  <span>Input Leads</span>
                </button>
                {user.role === 'admin' && (
                  <>
                    <button onClick={() => setIsWilayahModalOpen(true)} className="btn btn-outline" style={{ padding: '8px 16px', fontSize: '13.5px' }}>
                      Kelola Wilayah
                    </button>
                    <button onClick={() => setIsSumberModalOpen(true)} className="btn btn-outline" style={{ padding: '8px 16px', fontSize: '13.5px' }}>
                      Kelola Sumber
                    </button>
                  </>
                )}
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
                    <tr>
                      <th>Tanggal</th>
                      <th>Wilayah</th>
                      <th>Sumber Leads</th>
                      <th>Inputter</th>
                      <th>Jumlah</th>
                      <th style={{ textAlign: 'right' }}>Aksi</th>
                    </tr>
                  </thead>
                  <tbody>
                    {leads.map((lead, idx) => (
                      <tr key={lead.id} className={idx % 2 === 1 ? 'table-row-odd' : ''}>
                        <td>{formatDateStr(lead.tanggal)}</td>
                        <td><strong>{lead.nama_wilayah}</strong></td>
                        <td><span className="text-muted">{lead.nama_sumber}</span></td>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                            <User size={12} className="text-muted" />
                            <span style={{ fontSize: '12px' }}>{lead.nama_inputter}</span>
                          </div>
                        </td>
                        <td className="badge-lead">{lead.jumlah}</td>
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
                      </tr>
                    ))}
                    {/* Total Row */}
                    <tr className="total-row">
                      <td colSpan="4">TOTAL JUMLAH LEADS</td>
                      <td className="badge-lead" style={{ fontSize: '14.5px', color: 'var(--primary)' }}>{totalLeadsSum}</td>
                      <td></td>
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
                <span>Wilayah Teraktif (Top 5)</span>
              </h2>
              <div className="chart-container">
                {renderBarChart()}
              </div>
            </div>

            {/* Leaderboard Panel (Admin Only) */}
            {user.role === 'admin' && dashboardStats && dashboardStats.leaderboard && (
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
              <h3 className="modal-title">{editingLead ? 'Edit Data Lead' : 'Input Data Lead'}</h3>
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
              <div className="form-group">
                <label className="form-label">WILAYAH TUJUAN</label>
                <select className="form-control" value={formWilayahId} onChange={(e) => setFormWilayahId(e.target.value)} required>
                  <option value="">Pilih Wilayah</option>
                  {wilayah.map(w => <option key={w.id} value={w.id}>{w.nama_wilayah}</option>)}
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">SUMBER LEADS</label>
                <select className="form-control" value={formSumberId} onChange={(e) => setFormSumberId(e.target.value)} required>
                  <option value="">Pilih Sumber</option>
                  {sumber.map(s => <option key={s.id} value={s.id}>{s.nama_sumber}</option>)}
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">TANGGAL INPUT</label>
                <input type="date" className="form-control" value={formTanggal} onChange={(e) => setFormTanggal(e.target.value)} required />
              </div>

              <div className="form-group">
                <label className="form-label">JUMLAH LEADS</label>
                <input 
                  type="number" 
                  min="0"
                  className="form-control" 
                  placeholder="Masukkan jumlah leads"
                  value={formJumlah} 
                  onChange={(e) => setFormJumlah(e.target.value)} 
                  required 
                />
              </div>

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
    </div>
  );
}
