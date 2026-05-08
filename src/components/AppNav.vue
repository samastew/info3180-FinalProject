<script setup>
import { RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'

const auth   = useAuthStore()
const router = useRouter()

async function handleLogout() {
  try { await api.post('/auth/logout') } catch {}
  auth.logout()
  router.push({ name: 'home' })
}

const initials = () => {
  const p = auth.profile
  if (p) return `${p.first_name?.[0] || ''}${p.last_name?.[0] || ''}`.toUpperCase()
  return auth.user?.username?.[0]?.toUpperCase() || '?'
}
</script>

<template>
  <nav class="nav">
    <div class="nav-inner">
      <RouterLink to="/discover" class="nav-brand">
        <span class="brand-icon">💕</span>
        <span class="brand-name">DriftDater</span>
      </RouterLink>

      <div class="nav-links">
        <RouterLink to="/discover" class="nav-link" active-class="active">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
          Discover
        </RouterLink>
        <RouterLink to="/matches" class="nav-link" active-class="active">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
          Matches
        </RouterLink>
        <RouterLink to="/messages" class="nav-link" active-class="active">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
          Messages
        </RouterLink>
        <RouterLink to="/favorites" class="nav-link" active-class="active">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
          Favorites
        </RouterLink>
        <RouterLink to="/search" class="nav-link" active-class="active">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
          Search
        </RouterLink>
      </div>

      <div class="nav-right">
        <RouterLink :to="`/profile/${auth.currentUserId}`" class="nav-avatar">
          <img v-if="auth.profile?.profile_photo_url" :src="auth.profile.profile_photo_url" :alt="initials()" />
          <span v-else>{{ initials() }}</span>
        </RouterLink>
        <button class="nav-logout" @click="handleLogout" title="Logout">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
        </button>
      </div>
    </div>
  </nav>
</template>

<style scoped>
.nav {
  position: fixed; top: 0; left: 0; right: 0; z-index: 100;
  background: rgba(255,255,255,0.95); backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(229,231,235,0.8);
  height: var(--nav-height);
}
.nav-inner {
  max-width: 1200px; margin: 0 auto; padding: 0 24px;
  height: 100%; display: flex; align-items: center; gap: 32px;
}
.nav-brand {
  display: flex; align-items: center; gap: 8px; text-decoration: none;
  font-family: var(--font-display); font-size: 20px; color: var(--coral);
  font-weight: 700;
}
.brand-icon { font-size: 22px; }
.nav-links {
  display: flex; gap: 4px; flex: 1;
}
.nav-link {
  display: flex; align-items: center; gap: 6px;
  padding: 8px 14px; border-radius: 50px;
  text-decoration: none; font-size: 14px; font-weight: 500;
  color: var(--mist); transition: all 0.2s;
}
.nav-link:hover { color: var(--coral); background: var(--blush); }
.nav-link.active { color: var(--coral); background: var(--blush); font-weight: 600; }
.nav-right { display: flex; align-items: center; gap: 12px; margin-left: auto; }
.nav-avatar {
  width: 36px; height: 36px; border-radius: 50%; overflow: hidden;
  background: var(--blush); display: flex; align-items: center; justify-content: center;
  color: var(--coral); font-weight: 700; font-size: 14px; text-decoration: none;
  border: 2px solid var(--coral); transition: transform 0.2s;
}
.nav-avatar:hover { transform: scale(1.05); }
.nav-avatar img { width: 100%; height: 100%; object-fit: cover; }
.nav-logout {
  padding: 8px; border-radius: 50%; border: none; background: transparent;
  color: var(--mist); cursor: pointer; display: flex; align-items: center;
  transition: all 0.2s;
}
.nav-logout:hover { color: var(--coral); background: var(--blush); }
</style>
