<template>
  <header>
    <nav class="navbar navbar-expand-lg navbar-light dd-navbar fixed-top">
      <div class="container-fluid">
        <RouterLink class="navbar-brand dd-brand" to="/">
          <span class="brand-dot" />
          DriftDater
        </RouterLink>

        <button
          class="navbar-toggler"
          type="button"
          data-bs-toggle="collapse"
          data-bs-target="#ddNav"
          aria-controls="ddNav"
          aria-expanded="false"
          aria-label="Toggle navigation"
        >
          <span class="navbar-toggler-icon" />
        </button>

        <div class="collapse navbar-collapse" id="ddNav">
          <!-- Auth'd nav -->
          <ul v-if="authStore.isLoggedIn" class="navbar-nav me-auto">
            <li class="nav-item">
              <RouterLink to="/discover" class="nav-link">Discover</RouterLink>
            </li>
            <li class="nav-item">
              <RouterLink to="/matches" class="nav-link">
                Matches
                <span v-if="matchStore.mutualMatchIds.length" class="badge-count">
                  {{ matchStore.mutualMatchIds.length }}
                </span>
              </RouterLink>
            </li>
          </ul>

          <!-- Right side -->
          <ul class="navbar-nav ms-auto">
            <template v-if="authStore.isLoggedIn">
              <!-- Notification bell -->
              <li class="nav-item d-flex align-items-center me-2" style="position:relative">
                <button class="btn btn-link nav-link p-0" @click="showNotifs = !showNotifs">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 01-3.46 0"/></svg>
                  <span v-if="unreadCount" class="notif-badge">{{ unreadCount }}</span>
                </button>
                <!-- Notification dropdown -->
                <div v-if="showNotifs" class="notif-panel">
                  <div v-if="!matchStore.notifications.length" class="notif-empty">No new notifications</div>
                  <div v-for="n in matchStore.notifications" :key="n.id" class="notif-item">
                    <span>{{ n.message }}</span>
                    <button class="notif-dismiss" @click="matchStore.dismissNotification(n.id)">✕</button>
                  </div>
                </div>
              </li>

              <li class="nav-item">
                <RouterLink to="/profile" class="nav-link d-flex align-items-center gap-2">
                  <div class="nav-avatar">
                    <img v-if="authStore.currentUser.profilePicture" :src="authStore.currentUser.profilePicture" alt="You" />
                    <span v-else>{{ userInitials }}</span>
                  </div>
                </RouterLink>
              </li>
              <li class="nav-item">
                <button class="btn btn-outline-secondary btn-sm ms-2" @click="handleLogout">
                  Log out
                </button>
              </li>
            </template>

            <template v-else>
              <li class="nav-item">
                <RouterLink to="/login" class="nav-link">Sign in</RouterLink>
              </li>
              <li class="nav-item">
                <RouterLink to="/register" class="btn btn-primary btn-sm ms-2">Get started</RouterLink>
              </li>
            </template>
          </ul>
        </div>
      </div>
    </nav>
  </header>
</template>

<script setup>
import { ref, computed } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useMatchStore } from '@/stores/matches'

const authStore = useAuthStore()
const matchStore = useMatchStore()
const router = useRouter()
const showNotifs = ref(false)

const userInitials = computed(() =>
  (authStore.currentUser?.name || '').split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2)
)

const unreadCount = computed(() =>
  matchStore.notifications.filter(n => !n.read).length
)

function handleLogout() {
  authStore.logout()
  router.push('/login')
}
</script>

<style scoped>
.dd-navbar {
  background: rgba(255,255,255,0.97);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid #f0f0f5;
  padding: 0.6rem 0;
}
.dd-brand {
  font-weight: 700;
  font-size: 1.2rem;
  color: #4361ee !important;
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
}
.brand-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #4361ee;
  box-shadow: 0 0 0 3px #4361ee33;
}
.badge-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: #4361ee;
  color: #fff;
  font-size: 10px;
  font-weight: 700;
  margin-left: 4px;
}
/* Notification panel */
.notif-badge {
  position: absolute;
  top: -4px;
  right: -4px;
  width: 16px;
  height: 16px;
  background: #ef4444;
  color: #fff;
  border-radius: 50%;
  font-size: 9px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.notif-panel {
  position: absolute;
  top: 36px;
  right: 0;
  width: 260px;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
  z-index: 200;
  overflow: hidden;
}
.notif-empty { padding: 1rem; font-size: 13px; color: #9ca3af; text-align: center; }
.notif-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  font-size: 13px;
  border-bottom: 1px solid #f3f4f6;
}
.notif-dismiss {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  font-size: 12px;
  padding: 0 4px;
}
/* Nav avatar */
.nav-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  overflow: hidden;
  background: linear-gradient(135deg, #4361ee, #7b5ea7);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 12px;
  font-weight: 600;
}
.nav-avatar img { width: 100%; height: 100%; object-fit: cover; }
</style>