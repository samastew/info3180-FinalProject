<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'

const router = useRouter()
const auth   = useAuthStore()

const form    = ref({ username: '', email: '', password: '', confirm: '' })
const errors  = ref([])
const loading = ref(false)

async function handleRegister() {
  errors.value  = []
  if (form.value.password !== form.value.confirm) {
    errors.value = ['Passwords do not match.']
    return
  }
  loading.value = true
  try {
    const { confirm, ...payload } = form.value
    const res = await api.post('/auth/register', payload)
    auth.setAuth(res.data)
    router.push({ name: 'setup-profile' })
  } catch (e) {
    const data = e.response?.data
    if (data?.errors) errors.value = Array.isArray(data.errors) ? data.errors : [data.errors]
    else errors.value = ['Registration failed.']
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
        <h2>Find your<br><em>perfect drift</em></h2>
        <p>Join thousands finding real connections every day.</p>
      </div>
    </div>
    <div class="auth-right">
      <div class="auth-card">
        <h1 class="auth-title">Create Account</h1>
        <p class="auth-sub">Already a member? <RouterLink to="/login">Sign in</RouterLink></p>

        <ul v-if="errors.length" class="error-list">
          <li v-for="err in errors" :key="err">{{ err }}</li>
        </ul>

        <div class="form-group">
          <label class="form-label">Username</label>
          <input v-model="form.username" type="text" class="form-control" placeholder="cool_drifter" />
        </div>
        <div class="form-group">
          <label class="form-label">Email</label>
          <input v-model="form.email" type="email" class="form-control" placeholder="you@example.com" />
        </div>
        <div class="form-group">
          <label class="form-label">Password</label>
          <input v-model="form.password" type="password" class="form-control" placeholder="••••••••" />
        </div>
        <div class="form-group">
          <label class="form-label">Confirm Password</label>
          <input v-model="form.confirm" type="password" class="form-control" placeholder="••••••••" @keyup.enter="handleRegister" />
        </div>

        <button class="btn btn-primary w-full" :disabled="loading" @click="handleRegister">
          <span v-if="loading" class="btn-spinner"></span>
          <span v-else>Create Account →</span>
        </button>

        <p class="tos">By joining you agree to our <a href="#">Terms</a> and <a href="#">Privacy Policy</a>.</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.auth-page { min-height: 100vh; display: grid; grid-template-columns: 1fr 1fr; }
.auth-left {
  background: linear-gradient(160deg, var(--coral) 0%, #FF4E4E 50%, #C0392B 100%);
  display: flex; align-items: center; justify-content: center; padding: 60px;
  position: relative; overflow: hidden;
}
.auth-left::before {
  content: ''; position: absolute; width: 400px; height: 400px;
  background: rgba(255,255,255,0.08); border-radius: 50%; top: -100px; right: -100px;
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
.auth-card { width: 100%; max-width: 400px; }
.auth-title { font-family: var(--font-display); font-size: 36px; margin-bottom: 8px; }
.auth-sub { color: var(--mist); margin-bottom: 28px; font-size: 15px; }
.auth-sub a { color: var(--coral); text-decoration: none; font-weight: 600; }
.w-full { width: 100%; justify-content: center; }
.tos { margin-top: 16px; font-size: 12px; color: var(--mist); text-align: center; }
.tos a { color: var(--coral); }
.btn-spinner { width: 16px; height: 16px; border-radius: 50%; border: 2px solid rgba(255,255,255,0.4); border-top-color: white; animation: spin 0.7s linear infinite; }
@media (max-width: 700px) { .auth-page { grid-template-columns: 1fr; } .auth-left { display: none; } }
</style>
