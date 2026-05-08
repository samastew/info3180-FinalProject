<template>
  <div class="auth-form">
    <h2 class="auth-title">Welcome back</h2>
    <p class="auth-subtitle">Sign in to DriftDater</p>

    <div v-if="authStore.error" class="alert alert-danger">
      {{ authStore.error }}
    </div>

    <form @submit.prevent="handleSubmit">
      <div class="mb-3">
        <label class="form-label">Email</label>
        <input
          v-model="form.email"
          type="email"
          class="form-control"
          :class="{ 'is-invalid': errors.email }"
          placeholder="you@example.com"
          autocomplete="email"
        />
        <div v-if="errors.email" class="invalid-feedback">{{ errors.email }}</div>
      </div>

      <div class="mb-3">
        <label class="form-label">Password</label>
        <div class="input-group">
          <input
            v-model="form.password"
            :type="showPassword ? 'text' : 'password'"
            class="form-control"
            :class="{ 'is-invalid': errors.password }"
            placeholder="Your password"
            autocomplete="current-password"
          />
          <button
            type="button"
            class="btn btn-outline-secondary"
            @click="showPassword = !showPassword"
          >
            {{ showPassword ? 'Hide' : 'Show' }}
          </button>
          <div v-if="errors.password" class="invalid-feedback">{{ errors.password }}</div>
        </div>
      </div>

      <button
        type="submit"
        class="btn btn-primary w-100 mt-2"
        :disabled="authStore.loading"
      >
        <span v-if="authStore.loading" class="spinner-border spinner-border-sm me-2" />
        Sign in
      </button>
    </form>

    <p class="text-center mt-3 text-muted small">
      Don't have an account?
      <RouterLink to="/register">Create one</RouterLink>
    </p>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const router = useRouter()

const form = reactive({ email: '', password: '' })
const errors = reactive({ email: '', password: '' })
const showPassword = ref(false)

function validate() {
  let valid = true
  errors.email = ''
  errors.password = ''

  if (!form.email) {
    errors.email = 'Email is required.'
    valid = false
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    errors.email = 'Please enter a valid email.'
    valid = false
  }
  if (!form.password) {
    errors.password = 'Password is required.'
    valid = false
  }
  return valid
}

async function handleSubmit() {
  if (!validate()) return
  const result = await authStore.login(form.email, form.password)
  if (result.success) {
    router.push('/discover')
  }
}
</script>

<style scoped>
.auth-form {
  max-width: 420px;
  margin: 0 auto;
  padding: 2rem;
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 4px 24px rgba(0,0,0,0.07);
}
.auth-title {
  font-size: 1.6rem;
  font-weight: 600;
  color: #1a1a2e;
  margin-bottom: 0.25rem;
}
.auth-subtitle {
  color: #6c757d;
  margin-bottom: 1.5rem;
}
</style>