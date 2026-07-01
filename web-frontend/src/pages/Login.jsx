import React, { useState } from 'react';
import { AlertCircle, User, Lock } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export default function Login() {
  const { login } = useAuth();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!username.trim() || !password) {
      setError('Username dan password wajib diisi.');
      return;
    }
    setError(null);
    setLoading(true);
    try {
      await login(username.trim(), password);
    } catch (err) {
      setError(err.message || 'Login gagal. Periksa username dan password Anda.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card">
        <div className="auth-header">
          <img src="/Icon Apps.png" alt="Apps Icon" style={{ height: '64px', marginBottom: '14px', objectFit: 'contain' }} />
          <h1 className="auth-title">Rekap Leads</h1>
          <p className="auth-subtitle">Masuk untuk mengelola data leads pariwisata</p>
        </div>

        {error && (
          <div className="alert alert-danger">
            <AlertCircle size={18} />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">USERNAME</label>
            <div className="input-wrapper">
              <User className="input-icon" size={16} />
              <input 
                type="text" 
                className="form-control has-icon" 
                placeholder="Masukkan username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
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
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
          </div>

          <button type="submit" className="btn btn-primary btn-block mt-4" disabled={loading}>
            {loading ? 'Menghubungkan...' : 'Masuk ke Dashboard'}
          </button>
        </form>
      </div>
    </div>
  );
}
