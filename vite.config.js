import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  // Relative asset URLs work whether ReactApp is served at / or /ReactApp/.
  base: './',
  build: {
    // Giữ đúng tên thư mục mà deploy.bat trong đề bài sử dụng.
    outDir: 'build',
    emptyOutDir: true,
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.js',
  },
})
