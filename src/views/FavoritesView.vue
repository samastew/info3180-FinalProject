<template>
  <div class="container" style="padding-top:32px; padding-bottom:60px;">
    <h1 style="font-size:1.8rem; font-weight:800; margin-bottom:24px;">Saved Profiles ⭐</h1>

    <div v-if="loading" class="text-center" style="padding:60px;">
      <div class="spinner" style="width:40px;height:40px;border-width:4px;margin:0 auto;"></div>
    </div>

    <div v-else-if="favorites.length === 0" class="empty-state">
      <div style="font-size:3.5rem;">⭐</div>
      <h2>No saved profiles yet</h2>
      <p class="text-muted">Tap the ☆ Save button on any profile to bookmark them here.</p>
      <RouterLink to="/discover" class="btn btn-primary mt-2">Start Discovering</RouterLink>
    </div>

    <div v-else class="favorites-grid">
      <div v-for="fav in favorites" :key="fav.user?.user_id" class="fav-card card">
        <RouterLink :to="`/users/${fav.user?.user_id}`" class="fav-link">
          <div class="fav-photo">
            <img :src="getPhoto(fav)" :alt="getName(fav)" @error="onImgErr" />
          </div>
          <div class="fav-info">
            <div class="fav-name">{{ getName(fav) }}</div>
            <div class="fav-meta text-muted">
              <span v-if="fav.profile?.age">{{ fav.profile.age }} yrs</span>
              <span v-if="fav.profile?.city">📍 {{ fav.profile.city }}</span>
            </div>
            <p v-if="fav.profile?.bio" class="fav-bio">{{ truncate(fav.profile.bio, 70) }}</p>
          </div>
        </RouterLink>
        <div class="fav-actions">
          <RouterLink :to="`/users/${fav.user?.user_id}`" class="btn btn-outline btn-sm">View Profile</RouterLink>
          <button class="btn btn-secondary btn-sm" @click="removeFavorite(fav.user?.user_id)">✕ Remove</button>
        </div>
        <div class="fav-date text-muted">Saved {{ formatDate(fav.favorited_at) }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import api from '@/utils/api'

const favorites = ref([])
const loading   = ref(true)

function getName(fav) {
  const p = fav.profile
  const u = fav.user
  if (p?.first_name) return `${p.first_name} ${p.last_name}`
  return u?.username || 'Unknown'
}

function getPhoto(fav) {
  return fav.user?.photo ||
    `https://ui-avatars.com/api/?name=${encodeURIComponent(getName(fav))}&background=e91e8c&color=fff&size=120`
}

function onImgErr(e) { e.target.src = 'https://ui-avatars.com/api/?name=?&background=e91e8c&color=fff&size=120' }

function truncate(s, l) { return s && s.length > l ? s.slice(0, l) + '…' : s }

function formatDate(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString('en-JM', { month: 'short', day: 'numeric' })
}

async function removeFavorite(userId) {
  await api.delete(`/favorites/${userId}`)
  favorites.value = favorites.value.filter(f => f.user?.user_id !== userId)
}

onMounted(async () => {
  try {
    const { data } = await api.get('/favorites')
    favorites.value = data
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.favorites-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}

.fav-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 0;
  overflow: hidden;
}

.fav-link {
  display: flex;
  gap: 14px;
  text-decoration: none;
  color: inherit;
  padding: 16px;
  transition: background 0.2s;
}
.fav-link:hover { background: #fafafa; }

.fav-photo {
  width: 70px; height: 70px;
  border-radius: 12px;
  overflow: hidden;
  flex-shrink: 0;
}
.fav-photo img { width: 100%; height: 100%; object-fit: cover; }

.fav-info { flex: 1; min-width: 0; }
.fav-name { font-weight: 700; font-size: 0.95rem; }
.fav-meta { font-size: 0.8rem; display: flex; gap: 8px; margin-top: 2px; }
.fav-bio  { font-size: 0.82rem; color: #495057; margin-top: 4px; }

.fav-actions {
  display: flex;
  gap: 8px;
  padding: 0 16px;
}

.fav-date {
  font-size: 0.78rem;
  padding: 0 16px 12px;
}

.empty-state { text-align: center; padding: 80px 20px; }
.empty-state h2 { font-size: 1.5rem; font-weight: 700; margin: 12px 0; }
</style>
