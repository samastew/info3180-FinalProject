<script setup>
import { RouterView, useRouter } from 'vue-router'
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import AppNav from '@/components/AppNav.vue'

const auth   = useAuthStore()
const router = useRouter()

const showNav = computed(() => auth.isLoggedIn)
</script>

<template>
  <div class="app-shell" :class="{ 'has-nav': showNav }">
    <AppNav v-if="showNav" />
    <main class="app-main">
      <RouterView />
    </main>
  </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;1,400&family=DM+Sans:wght@300;400;500;600&display=swap');

:root {
  --coral:    #FF6B6B;
  --rose:     #FF8E8E;
  --crimson:  #C0392B;
  --blush:    #FFE0E0;
  --nude:     #FFF5F5;
  --ink:      #1A1A2E;
  --slate:    #2D2D44;
  --mist:     #6B7280;
  --snow:     #FFFFFF;
  --gold:     #F5A623;
  --mint:     #10B981;
  --shadow-sm: 0 2px 8px rgba(26,26,46,0.08);
  --shadow-md: 0 8px 24px rgba(26,26,46,0.12);
  --shadow-lg: 0 16px 48px rgba(26,26,46,0.18);
  --radius-sm: 8px;
  --radius-md: 16px;
  --radius-lg: 24px;
  --radius-xl: 32px;
  --nav-height: 64px;
  --font-display: 'Playfair Display', serif;
  --font-body: 'DM Sans', sans-serif;
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

html { scroll-behavior: smooth; }

body {
  font-family: var(--font-body);
  background: var(--nude);
  color: var(--ink);
  min-height: 100vh;
  -webkit-font-smoothing: antialiased;
}

.app-shell { min-height: 100vh; display: flex; flex-direction: column; }
.app-shell.has-nav .app-main { padding-top: var(--nav-height); }
.app-main { flex: 1; }

/* Utility */
.btn {
  display: inline-flex; align-items: center; gap: 8px;
  padding: 12px 24px; border-radius: 50px; border: none;
  font-family: var(--font-body); font-size: 15px; font-weight: 600;
  cursor: pointer; transition: all 0.2s ease; text-decoration: none;
  white-space: nowrap;
}
.btn-primary {
  background: linear-gradient(135deg, var(--coral), #FF4E4E);
  color: white; box-shadow: 0 4px 16px rgba(255,107,107,0.4);
}
.btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(255,107,107,0.5); }
.btn-primary:active { transform: translateY(0); }
.btn-secondary {
  background: white; color: var(--ink); border: 2px solid #E5E7EB;
}
.btn-secondary:hover { border-color: var(--coral); color: var(--coral); }
.btn-ghost {
  background: transparent; color: var(--mist); padding: 8px 16px;
}
.btn-ghost:hover { color: var(--coral); background: var(--blush); }

.card {
  background: white; border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm); overflow: hidden;
}

.avatar {
  border-radius: 50%; object-fit: cover; background: var(--blush);
  display: flex; align-items: center; justify-content: center;
  color: var(--coral); font-weight: 700; font-family: var(--font-display);
}

.badge {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 12px; border-radius: 50px; font-size: 12px; font-weight: 600;
}
.badge-coral { background: var(--blush); color: var(--crimson); }
.badge-mint  { background: #D1FAE5; color: #065F46; }
.badge-gold  { background: #FEF3C7; color: #92400E; }

.section-title {
  font-family: var(--font-display); font-size: 28px;
  color: var(--ink); margin-bottom: 8px;
}
.section-sub { color: var(--mist); font-size: 15px; margin-bottom: 24px; }

.form-group { margin-bottom: 20px; }
.form-label { display: block; font-size: 13px; font-weight: 600; color: var(--slate); margin-bottom: 6px; letter-spacing: 0.5px; text-transform: uppercase; }
.form-control {
  width: 100%; padding: 12px 16px; border-radius: var(--radius-sm);
  border: 2px solid #E5E7EB; font-family: var(--font-body); font-size: 15px;
  color: var(--ink); background: white; transition: border-color 0.2s;
  outline: none;
}
.form-control:focus { border-color: var(--coral); box-shadow: 0 0 0 3px rgba(255,107,107,0.1); }
.form-control::placeholder { color: #9CA3AF; }
select.form-control { cursor: pointer; }

.error-list { list-style: none; }
.error-list li {
  background: #FEF2F2; color: #DC2626; padding: 10px 14px;
  border-radius: var(--radius-sm); font-size: 14px; margin-bottom: 6px;
  border-left: 3px solid #DC2626;
}

.spinner {
  width: 40px; height: 40px; border-radius: 50%;
  border: 3px solid var(--blush); border-top-color: var(--coral);
  animation: spin 0.8s linear infinite; margin: 0 auto;
}
@keyframes spin { to { transform: rotate(360deg); } }
</style>
