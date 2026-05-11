<template>
  <footer class="footer">
    <div class="footer-inner">
      <div class="footer-brand">
        <span>💕</span>
        <strong>DriftDater</strong>
        <span class="text-muted">— Find your drift</span>
      </div>
      <nav class="footer-nav">
        <RouterLink to="/about">About</RouterLink>
        <RouterLink to="/discover" v-if="auth.isLoggedIn">Discover</RouterLink>
        <RouterLink to="/search"   v-if="auth.isLoggedIn">Search</RouterLink>
        <RouterLink to="/login"    v-if="!auth.isLoggedIn">Login</RouterLink>
        <RouterLink to="/register" v-if="!auth.isLoggedIn">Sign Up</RouterLink>
      </nav>
      <p class="footer-copy">&copy; {{ year }} DriftDater. INFO3180 Group Project.</p>
    </div>
  </footer>
</template>

<script setup>
import { RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
const auth = useAuthStore()
const year = new Date().getFullYear()
</script>

<style scoped>
.footer {
  background: #1a1a2e;
  color: #adb5bd;
  padding: 32px 20px;
  margin-top: 60px;
}
.footer-inner {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  text-align: center;
}
.footer-brand {
  display: flex; align-items: center; gap: 8px;
  font-size: 1rem;
}
.footer-brand strong { color: #fff; }

.footer-nav { display: flex; gap: 20px; flex-wrap: wrap; justify-content: center; }
.footer-nav a {
  color: #adb5bd; text-decoration: none; font-size: 0.88rem;
  transition: color 0.2s;
}
.footer-nav a:hover { color: #e91e8c; }

.footer-copy { font-size: 0.82rem; margin-top: 4px; }
</style>
