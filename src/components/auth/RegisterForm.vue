<template>
  <div class="auth-form">
    <h2 class="auth-title">Create your account</h2>
    <p class="auth-subtitle">Join DriftDater — free forever</p>

    <div v-if="authStore.error" class="alert alert-danger">
      {{ authStore.error }}
    </div>

    <form @submit.prevent="handleSubmit">
      <div class="mb-3">
        <label class="form-label">Full name</label>
        <input
          v-model="form.name"
          type="text"
          class="form-control"
          :class="{ 'is-invalid': errors.name }"
          placeholder="Your name"
          autocomplete="name"
        />
        <div v-if="errors.name" class="invalid-feedback">{{ errors.name }}</div>
      </div>

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
        <label class="form-label">Age</label>
        <input
          v-model.number="form.age"
          type="number"
          class="form-control"
          :class="{ 'is-invalid': errors.age }"
          min="18" max="99"
          placeholder="Your age"
        />
        <div v-if="errors.age" class="invalid-feedback">{{ errors.age }}</div>
      </div>

      <div class="mb-3">
        <label class="form-label">Password</label>
        <input
          v-model="form.password"
          type="password"
          class="form-control"
          :class="{ 'is-invalid': errors.password }"
          placeholder="Min 8 characters"
          autocomplete="new-password"
        />
        <div v-if="errors.password" class="invalid-feedback">{{ errors.password }}</div>
      </div>

      <div class="mb-3">
        <label class="form-label">Confirm password</label>
        <input
          v-model="form.confirmPassword"
          type="password"
          class="form-control"
          :class="{ 'is-invalid': errors.confirmPassword }"
          placeholder="Repeat password"
          autocomplete="new-password"
        />
        <div v-if="errors.confirmPassword" class="invalid-feedback">{{ errors.confirmPassword }}</div>
      </div>

      <button
        type="submit"
        class="btn btn-primary w-100 mt-2"
        :disabled="authStore.loading"
      >
        <span v-if="authStore.loading" class="spinner-border spinner-border-sm me-2" />
        Create account
      </button>
    </form>

    <p class="text-center mt-3 text-muted small">
      Already have an account?
      <RouterLink to="/login">Sign in</RouterLink>
    </p>
  </div>
</template>

<script setup>
import { reactive } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const router = useRouter()

const form = reactive({ name: '', email: '', age: '', password: '', confirmPassword: '' })
const errors = reactive({ name: '', email: '', age: '', password: '', confirmPassword: '' })

function validate() {
  let valid = true
  Object.keys(errors).forEach(k => (errors[k] = ''))

  if (!form.name.trim()) { errors.name = 'Name is required.'; valid = false }
  if (!form.email) {
    errors.email = 'Email is required.'; valid = false
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    errors.email = 'Enter a valid email address.'; valid = false
  }
  if (!form.age || form.age < 18 || form.age > 99) {
    errors.age = 'You must be at least 18 years old.'; valid = false
  }
  if (!form.password || form.password.length < 8) {
    errors.password = 'Password must be at least 8 characters.'; valid = false
  }
  if (form.password !== form.confirmPassword) {
    errors.confirmPassword = 'Passwords do not match.'; valid = false
  }
  return valid
}

async function handleSubmit() {
  if (!validate()) return
  const result = await authStore.register(form)
  if (result.success) {
    router.push('/profile/edit')
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