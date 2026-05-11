<template>
  <div class="container-sm" style="padding-top: 60px; padding-bottom: 60px;">
    <div class="card">
      <div class="text-center mb-3">
        <div style="font-size:3rem;">💕</div>
        <h1 style="font-size:1.8rem; font-weight:800;">Welcome Back</h1>
        <p class="text-muted">Sign in to your DriftDater account</p>
      </div>

      <div v-if="error" class="alert alert-danger">{{ error }}</div>

      <form @submit.prevent="handleLogin">
        <div class="form-group">
          <label>Email or Username</label>
          <input v-model="credentials.email" class="form-control" placeholder="you@example.com" required />
        </div>
        <div class="form-group">
          <label>Password</label>
          <div class="password-wrap">
            <input v-model="credentials.password" :type="showPw ? 'text' : 'password'"
              class="form-control" placeholder="Your password" required />
            <button type="button" class="pw-toggle" @click="showPw = !showPw">
              {{ showPw ? '🙈' : '👁️' }}
            </button>
          </div>
        </div>

        <button type="submit" class="btn btn-primary" style="width:100%; margin-top:8px;"
          :disabled="loading">
          <span v-if="loading" class="spinner"></span>
          {{ loading ? 'Signing in…' : 'Sign In' }}
        </button>
      </form>

      <p class="text-center mt-2 text-muted" style="font-size:0.9rem;">
        Don't have an account?
        <RouterLink to="/register" style="color:#e91e8c; font-weight:600;">Create one free</RouterLink>
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { RouterLink, useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth   = useAuthStore()
const router = useRouter()
const route  = useRoute()

const loading     = ref(false)
const error       = ref('')
const showPw      = ref(false)
const credentials = ref({ email: '', password: '' })

async function handleLogin() {
  loading.value = true
  error.value   = ''
  try {
    await auth.login(credentials.value)
    const redirect = route.query.redirect || '/discover'
    router.push(redirect)
  } catch (e) {
    error.value = e.response?.data?.error || 'Login failed. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.password-wrap { position: relative; }
.pw-toggle {
  position: absolute; right: 12px; top: 50%; transform: translateY(-50%);
  background: none; border: none; cursor: pointer; font-size: 1rem;
}
</style>
