import axios from 'axios'

const api = axios.create({
  // Use relative URL so requests go through Vite's proxy to Flask.
  // Vite forwards  /api/*  →  http://localhost:8080/api/*
  // This avoids CORS issues entirely since the browser sees one origin.
  // To override (e.g. production), set VITE_API_BASE_URL in your .env file.
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  headers: { 'Content-Type': 'application/json' },
})

// Attach JWT to every request
api.interceptors.request.use(config => {
  const token = localStorage.getItem('dd_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// Handle 401 globally — clear stored credentials and redirect to login
api.interceptors.response.use(
  res => res,
  err => {
    if (err.response?.status === 401) {
      localStorage.removeItem('dd_token')
      localStorage.removeItem('dd_user')
      localStorage.removeItem('dd_profile')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export default api
