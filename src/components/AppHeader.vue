<template>
  <header class="header">
    <nav class="nav-container">
      <RouterLink to="/" class="brand">
        <span class="brand-icon">💕</span>
        <span class="brand-name">DriftDater</span>
      </RouterLink>

      <button class="hamburger" @click="menuOpen = !menuOpen" aria-label="Menu">
        <span></span><span></span><span></span>
      </button>

      <div class="nav-links" :class="{ open: menuOpen }">
        <template v-if="auth.isLoggedIn">
          <RouterLink to="/discover"  class="nav-link" @click="close">Discover</RouterLink>
          <RouterLink to="/matches"   class="nav-link" @click="close">
            Matches
            <span v-if="newMatchCount > 0" class="badge-dot">{{ newMatchCount }}</span>
          </RouterLink>
          <RouterLink to="/messages"  class="nav-link" @click="close">
            Messages
            <span v-if="unreadMessages > 0" class="badge-dot">{{ unreadMessages }}</span>
          </RouterLink>
          <RouterLink to="/search"    class="nav-link" @click="close">Search</RouterLink>
          <RouterLink to="/favorites" class="nav-link" @click="close">Saved</RouterLink>
          <RouterLink to="/notifications" class="nav-link" @click="close">
            <span class="notif-icon-wrap">
              🔔
              <span v-if="unreadNotifs > 0" class="badge-dot">{{ unreadNotifs }}</span>
            </span>
          </RouterLink>
          <div class="nav-divider"></div>
          <RouterLink to="/profile" class="nav-link nav-user" @click="close">
            <img v-if="primaryPhoto" :src="primaryPhoto" class="avatar-sm" alt="me"
                 @error="e => e.target.style.display='none'" />
            <span v-else class="avatar-placeholder">{{ initials }}</span>
            {{ auth.profile?.first_name || auth.user?.username }}
          </RouterLink>
          <button class="btn btn-outline btn-sm" @click="handleLogout">Logout</button>
        </template>
        <template v-else>
          <RouterLink to="/login"    class="nav-link" @click="close">Login</RouterLink>
          <RouterLink to="/register" class="btn btn-primary btn-sm" @click="close">Sign Up Free</RouterLink>
        </template>
      </div>
    </nav>
  </header>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/utils/api'

const auth           = useAuthStore()
const router         = useRouter()
const menuOpen       = ref(false)
const unreadMessages = ref(0)
const unreadNotifs   = ref(0)
const newMatchCount  = ref(0)

const close = () => { menuOpen.value = false }

const initials = computed(() => {
  const p = auth.profile
  if (!p) return '?'
  return (p.first_name?.[0] || '') + (p.last_name?.[0] || '')
})

const primaryPhoto = computed(() => {
  const photos = auth.photos || []
  const primary = photos.find(p => p.is_primary)
  return (primary || photos[0])?.photo_url || auth.user?.photo || null
})

async function handleLogout() {
  close()
  await auth.logout()
  router.push('/')
}

async function pollCounts() {
  if (!auth.isLoggedIn) return
  try {
    const [convRes, notifRes] = await Promise.all([
      api.get('/conversations'),
      api.get('/notifications')
    ])
    unreadMessages.value = convRes.data.reduce((acc, c) => acc + (c.unread_count || 0), 0)
    unreadNotifs.value   = notifRes.data.unread_count || 0
  } catch {}
}

let pollTimer = null
onMounted(() => {
  pollCounts()
  pollTimer = setInterval(pollCounts, 30000)
})
onUnmounted(() => clearInterval(pollTimer))
</script>

<style scoped>
.header {
  position: fixed; top: 0; left: 0; right: 0;
  height: 65px; background: #fff;
  box-shadow: 0 2px 12px rgba(0,0,0,0.1); z-index: 1000;
}
.nav-container {
  max-width: 1200px; margin: 0 auto; padding: 0 20px;
  height: 100%; display: flex; align-items: center;
  justify-content: space-between; gap: 12px;
}
.brand {
  display: flex; align-items: center; gap: 8px;
  text-decoration: none; flex-shrink: 0;
}
.brand-icon { font-size: 1.5rem; }
.brand-name {
  font-size: 1.4rem; font-weight: 800;
  background: linear-gradient(135deg, #e91e8c, #ff6b35);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
}
.nav-links {
  display: flex; align-items: center; gap: 4px; flex-wrap: wrap;
}
.nav-link {
  text-decoration: none; color: #495057; font-weight: 600;
  padding: 6px 10px; border-radius: 8px; transition: all 0.2s;
  display: flex; align-items: center; gap: 4px; position: relative;
  font-size: 0.92rem;
}
.nav-link:hover,
.nav-link.router-link-active { color: #e91e8c; background: #fce4ec; }

.badge-dot {
  background: #e91e8c; color: #fff; border-radius: 50%;
  min-width: 17px; height: 17px; font-size: 0.68rem; font-weight: 700;
  display: inline-flex; align-items: center; justify-content: center;
}
.notif-icon-wrap { position: relative; display: inline-flex; }
.notif-icon-wrap .badge-dot {
  position: absolute; top: -6px; right: -8px; font-size: 0.6rem;
}
.nav-divider { width: 1px; height: 24px; background: #dee2e6; margin: 0 4px; }
.nav-user { font-weight: 700; }
.avatar-sm {
  width: 26px; height: 26px; border-radius: 50%;
  object-fit: cover; border: 2px solid #e91e8c;
}
.avatar-placeholder {
  width: 26px; height: 26px; border-radius: 50%;
  background: linear-gradient(135deg, #e91e8c, #ff6b35);
  color: #fff; font-size: 0.65rem; font-weight: 700;
  display: inline-flex; align-items: center; justify-content: center;
}
.hamburger {
  display: none; flex-direction: column; gap: 5px;
  background: none; border: none; cursor: pointer; padding: 4px;
}
.hamburger span { display: block; width: 24px; height: 2px; background: #495057; border-radius: 2px; }

@media (max-width: 900px) {
  .hamburger { display: flex; }
  .nav-links {
    position: fixed; top: 65px; left: 0; right: 0;
    background: #fff; padding: 16px 20px; flex-direction: column;
    align-items: flex-start; box-shadow: 0 8px 20px rgba(0,0,0,0.12);
    display: none; z-index: 999;
  }
  .nav-links.open { display: flex; }
  .nav-link { width: 100%; }
  .nav-divider { width: 100%; height: 1px; margin: 6px 0; }
}
</style>
