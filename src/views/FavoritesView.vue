<!-- This view shows a user's favourites -->
 
<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/services/api'

const router    = useRouter()
const favorites = ref([])
const loading   = ref(true)

onMounted(async () => {
  try {
    const res = await api.get('/favorites')
    favorites.value = res.data.favorites
  } catch {}
  loading.value = false
})

async function removeFavorite(id) {
  try {
    await api.delete(`/favorites/${id}`)
    favorites.value = favorites.value.filter(f => f.favorited_id !== id)
  } catch {}
}

function viewProfile(uid) {
  router.push({ name: 'profile', params: { userId: uid } })
}

function initials(p) {
  return `${p?.first_name?.[0] || ''}${p?.last_name?.[0] || ''}`.toUpperCase()
}
</script>

<template>
  <div class="favs-page">
    <div class="favs-inner">
      <h1 class="section-title">Favourites ⭐</h1>
      <p class="section-sub">Profiles you've saved</p>

      <div v-if="loading" style="text-align:center;padding:80px 0">
        <div class="spinner"></div>
      </div>

      <div v-else-if="!favorites.length" class="empty-state">
        <div class="empty-icon">⭐</div>
        <h2>No favourites yet</h2>
        <p>Tap the star on a profile to save it here.</p>
        <RouterLink to="/discover" class="btn btn-primary">Go Discover</RouterLink>
      </div>

      <div v-else class="favs-grid">
        <div v-for="fav in favorites" :key="fav.favorited_id" class="fav-card">
          <button class="fav-remove" @click.stop="removeFavorite(fav.favorited_id)" title="Remove">✕</button>

          <div class="fav-photo" @click="viewProfile(fav.favorited_id)">
            <img
              v-if="fav.profile?.profile_photo_url"
              :src="fav.profile.profile_photo_url"
              :alt="fav.profile?.first_name"
            />
            <div v-else class="fav-photo-placeholder">{{ initials(fav.profile) }}</div>
          </div>

          <div class="fav-info">
            <h3>{{ fav.profile?.first_name }} {{ fav.profile?.last_name }}</h3>
            <p class="fav-meta">
              <span v-if="fav.profile?.age">{{ fav.profile.age }}</span>
              <span v-if="fav.profile?.city"> · {{ fav.profile.city }}</span>
            </p>
            <div class="fav-tags">
              <span v-for="i in (fav.profile?.interests || []).slice(0, 3)" :key="i.interest_id" class="fav-tag">
                {{ i.name }}
              </span>
            </div>
            <button class="btn btn-primary btn-sm w100" @click="viewProfile(fav.favorited_id)">View Profile</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.favs-page { min-height: calc(100vh - var(--nav-height)); background: var(--nude); padding: 40px 24px; }
.favs-inner { max-width: 1100px; margin: 0 auto; }
.empty-state { text-align: center; padding: 80px 24px; }
.empty-icon { font-size: 64px; margin-bottom: 16px; }
.empty-state h2 { font-family: var(--font-display); font-size: 28px; margin-bottom: 8px; }
.empty-state p { color: var(--mist); margin-bottom: 24px; }

.favs-grid {
  display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 20px;
}
.fav-card {
  background: white; border-radius: var(--radius-lg); box-shadow: var(--shadow-sm);
  overflow: hidden; position: relative; transition: transform 0.2s, box-shadow 0.2s;
}
.fav-card:hover { transform: translateY(-3px); box-shadow: var(--shadow-md); }

.fav-remove {
  position: absolute; top: 10px; right: 10px; z-index: 5;
  width: 28px; height: 28px; border-radius: 50%; border: none;
  background: rgba(0,0,0,0.5); color: white; font-size: 14px;
  cursor: pointer; display: flex; align-items: center; justify-content: center;
  transition: background 0.2s;
}
.fav-remove:hover { background: var(--coral); }

.fav-photo { height: 200px; overflow: hidden; cursor: pointer; background: var(--blush); }
.fav-photo img { width: 100%; height: 100%; object-fit: cover; display: block; transition: transform 0.3s; }
.fav-photo:hover img { transform: scale(1.04); }
.fav-photo-placeholder {
  width: 100%; height: 100%; display: flex; align-items: center; justify-content: center;
  font-family: var(--font-display); font-size: 56px; color: var(--coral);
  background: linear-gradient(135deg, var(--blush), #FFD6D6);
}
.fav-info { padding: 14px 16px 16px; }
.fav-info h3 { font-family: var(--font-display); font-size: 18px; margin-bottom: 4px; }
.fav-meta { color: var(--mist); font-size: 13px; margin-bottom: 8px; }
.fav-tags { display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 12px; }
.fav-tag { padding: 2px 10px; background: var(--blush); color: var(--crimson); border-radius: 50px; font-size: 12px; font-weight: 600; }
.btn-sm { padding: 8px 16px; font-size: 13px; }
.w100 { width: 100%; justify-content: center; }
</style>
