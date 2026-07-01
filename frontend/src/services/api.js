const API_URL = import.meta.env.VITE_API_URL || 'http://202.10.41.37:18791/api';

async function request(path, options = {}) {
  const token = localStorage.getItem('token');
  const headers = {
    'Content-Type': 'application/json',
    ...(token && { 'Authorization': `Bearer ${token}` }),
    ...options.headers,
  };

  let res;
  try {
    res = await fetch(`${API_URL}${path}`, {
      ...options,
      headers,
    });
  } catch (networkErr) {
    // Gagal terhubung ke server (server mati, CORS preflight gagal, dll.)
    throw new Error('Tidak dapat terhubung ke server. Pastikan server backend sedang berjalan.');
  }

  if (res.status === 401) {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.reload();
    throw new Error('Sesi habis. Silakan login ulang.');
  }

  const json = await res.json();

  if (!res.ok) {
    // Pesan error bisa ada di json.error atau json.message
    throw new Error(json.error || json.message || 'Terjadi kesalahan pada server.');
  }

  // Auto-unwrap: jika response menggunakan pola ok() helper { success, message, data },
  // kembalikan hanya isi 'data'-nya. Kalau tidak ada field 'data', kembalikan json apa adanya.
  return json.data !== undefined ? json.data : json;
}

const api = {
  get:    (path, options)       => request(path, { ...options, method: 'GET' }),
  post:   (path, body, options) => request(path, { ...options, method: 'POST',   body: JSON.stringify(body) }),
  put:    (path, body, options) => request(path, { ...options, method: 'PUT',    body: JSON.stringify(body) }),
  delete: (path, options)       => request(path, { ...options, method: 'DELETE' }),
};

export default api;
export { API_URL };
