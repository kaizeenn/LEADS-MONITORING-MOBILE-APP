/**
 * Helper untuk format response API yang konsisten.
 * Semua endpoint menggunakan fungsi ini agar format response seragam.
 */

/**
 * Response sukses.
 * @param {object} res  - Express response object
 * @param {*}      data - Data yang dikembalikan
 * @param {string} message - Pesan sukses (opsional)
 * @param {number} status  - HTTP status code (default 200)
 */
function ok(res, data = null, message = 'Berhasil', status = 200) {
  return res.status(status).json({
    success: true,
    message,
    ...(data !== null && { data }),
  });
}

/**
 * Response error.
 * @param {object} res     - Express response object
 * @param {string} message - Pesan error
 * @param {number} status  - HTTP status code (default 400)
 * @param {*}      details - Detail error tambahan (opsional, hanya di development)
 */
function fail(res, message = 'Terjadi kesalahan', status = 400, details = null) {
  const body = { success: false, error: message };
  if (details && process.env.NODE_ENV === 'development') {
    body.details = details;
  }
  return res.status(status).json(body);
}

module.exports = { ok, fail };
