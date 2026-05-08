<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'

const router = useRouter()
const auth   = useAuthStore()

const form = ref({ username: '', password: '' })
const errors   = ref([])
const loading  = ref(false)

async function handleLogin() {
  errors.value  = []
  loading.value = true
  try {
    const res = await api.post('/auth/login', form.value)
    auth.setAuth(res.data)
    if (!auth.hasProfile) {
      router.push({ name: 'setup-profile' })
    } else {
      router.push({ name: 'discover' })
    }
  } catch (e) {
    const data = e.response?.data
    if (data?.errors) errors.value = Array.isArray(data.errors) ? data.errors : [data.errors]
    else errors.value = ['Login failed. Please try again.']
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="auth-page">
    <div class="auth-left">
      <div class="auth-branding">
        <div class="auth-logo">💕 DriftDater</div>
        <h2>Welcome back,<br><em>drifter</em></h2>
        <p>Your perfect match is waiting for you.</p>
      </div>
    </div>

    <div class="auth-right">
      <div class="auth-card">
        <h1 class="auth-title">Sign In</h1>
        <p class="auth-sub">Don't have an account? <RouterLink to="/register">Join free</RouterLink></p>

        <ul v-if="errors.length" class="error-list">
          <li v-for="err in errors" :key="err">{{ err }}</li>
        </ul>

        <div class="form-group">
          <label class="form-label">Username</label>
          <input v-model="form.username" type="text" class="form-control" placeholder="your_username" autocomplete="username" @keyup.enter="handleLogin" />
        </div>

        <div class="form-group">
          <label class="form-label">Password</label>
          <input v-model="form.password" type="password" class="form-control" placeholder="••••••••" autocomplete="current-password" @keyup.enter="handleLogin" />
        </div>

        <button class="btn btn-primary w-full" :disabled="loading" @click="handleLogin">
          <span v-if="loading" class="btn-spinner"></span>
          <span v-else>Sign In</span>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.auth-page {
  min-height: 100vh; display: grid; grid-template-columns: 1fr 1fr;
}
.auth-left {
  background: linear-gradient(160deg, var(--coral) 0%, #FF4E4E 50%, #C0392B 100%);
  display: flex; align-items: center; justify-content: center; padding: 60px;
  position: relative; overflow: hidden;
}
.auth-left::before {
  content: ''; position: absolute; width: 400px; height: 400px;
  background: rgba(255,255,255,0.08); border-radius: 50%;
  top: -100px; right: -100px;
}
.auth-left::after {
  content: ''; position: absolute; width: 300px; height: 300px;
  background: rgba(255,255,255,0.06); border-radius: 50%;
  bottom: -80px; left: -80px;
}
.auth-branding { position: relative; z-index: 1; color: white; }
.auth-logo { font-family: var(--font-display); font-size: 28px; margin-bottom: 40px; opacity: 0.9; }
.auth-branding h2 { font-family: var(--font-display); font-size: 48px; line-height: 1.2; margin-bottom: 16px; }
.auth-branding em { font-style: italic; }
.auth-branding p { font-size: 18px; opacity: 0.8; }
.auth-right {
  display: flex; align-items: center; justify-content: center;
  padding: 60px; background: var(--nude);
}
.auth-card {
  width: 100%; max-width: 400px;
}
.auth-title { font-family: var(--font-display); font-size: 36px; margin-bottom: 8px; }
.auth-sub { color: var(--mist); margin-bottom: 32px; font-size: 15px; }
.auth-sub a { color: var(--coral); text-decoration: none; font-weight: 600; }
.auth-sub a:hover { text-decoration: underline; }
.w-full { width: 100%; justify-content: center; }
.btn-spinner {
  width: 16px; height: 16px; border-radius: 50%;
  border: 2px solid rgba(255,255,255,0.4); border-top-color: white;
  animation: spin 0.7s linear infinite;
}
@media (max-width: 700px) {
  .auth-page { grid-template-columns: 1fr; }
  .auth-left { display: none; }
}
</style>
