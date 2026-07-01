import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],

  server: {
    // Frontend dev server berjalan di port 3001
    port: 3001,

    // Proxy untuk development: permintaan ke /api diteruskan ke backend (port 3000)
    // sehingga tidak ada masalah CORS saat menjalankan `npm run dev`
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
    },
  },
})
