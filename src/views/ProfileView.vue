<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'

const route  = useRoute()
const router = useRouter()
const auth   = useAuthStore()

const userId  = computed(() => Number(route.params.userId))
const isOwn   = computed(() => userId.value === auth.currentUserId)
const profile = ref(null)
const loading = ref(true)
const isFav   = ref(false)
const swiping = ref(false)

onMounted(async () => {
  try {
    const res = await api.get(`/profiles/${userId.value}`)
    profile.value = res.data.profile
    // Check if in favorites
    const favRes = await api.get('/favorites')
    isFav.value = favRes.data.favorites.some(f => f.favorited_id === userId.value)
  } catch {}
  loading.value = false
})

async function toggleFav() {
  if (isFav.value) {
    await api.delete(`/favorites/${userId.value}`)
    isFav.value = false
  } else {
    await api.post(`/favorites/${userId.value}`)
    isFav.value = true
  }
}

async function sendLike() {
  swiping.value = true
  try {
    const res = await api.post('/swipes', { swiped_id: userId.value, action: 'like' })
    if (res.data.matched) alert(`🎉 You matched with ${profile.value?.first_name}!`)
  } catch {}
  swiping.value = false
}

function initials(p) {
  return `${p?.first_name?.[0] || ''}${p?.last_name?.[0] || ''}`.toUpperCase()
}

const catEmoji = {
  outdoors: '🏞️', arts: '🎨', tech: '💻', food: '🍕', travel: '✈️',
  music: '🎵', education: '📚', sports: '⚽', entertainment: '🎬',
  wellness: '🧘', social: '🤝', lifestyle: '👗',
}
</script>

<template>
  <div class="profile-page">
    <div v-if="loading" style="text-align:center;padding:80px 0">
      <div class="spinner"></div>
    </div>

    <div v-else-if="!profile" class="not-found">
      <h2>Profile not found</h2>
      <button class="btn btn-primary" @click="router.back()">Go Back</button>
    </div>

    <template v-else>
      <!-- Hero banner -->
      <div class="profile-hero">
        <div class="profile-hero-photo">
          <img v-if="profile.profile_photo_url" :src="profile.profile_photo_url" :alt="profile.first_name" />
          <div v-else class="profile-photo-placeholder">{{ initials(profile) }}</div>
        </div>
        <div class="profile-hero-overlay">
          <div class="profile-hero-content">
            <h1>{{ profile.first_name }} {{ profile.last_name }}, {{ profile.age }}</h1>
            <p v-if="profile.city">📍 {{ profile.city }}, {{ profile.country }}</p>
          </div>

          <div v-if="!isOwn" class="profile-hero-actions">
            <button class="hero-action-btn fav" :class="{ active: isFav }" @click="toggleFav" :title="isFav ? 'Remove from favourites' : 'Add to favourites'">
              {{ isFav ? '⭐' : '☆' }}
            </button>
            <button class="hero-action-btn like" @click="sendLike" :disabled="swiping">
              ❤️ Like
            </button>
          </div>

          <div v-else class="profile-hero-actions">
            <RouterLink to="/profile/edit" class="btn btn-secondary btn-sm">✏️ Edit Profile</RouterLink>
          </div>
        </div>
      </div>

      <!-- Profile content -->
      <div class="profile-content">
        <div class="profile-main">
          <!-- About -->
          <div class="profile-section card">
            <h2 class="profile-section-title">About Me</h2>
            <p v-if="profile.bio" class="profile-bio">{{ profile.bio }}</p>
            <p v-else class="profile-empty">No bio yet.</p>

            <div class="profile-details-grid">
              <div v-if="profile.occupation" class="detail-item">
                <span class="detail-label">💼 Occupation</span>
                <span class="detail-value">{{ profile.occupation }}</span>
              </div>
              <div v-if="profile.education_level" class="detail-item">
                <span class="detail-label">🎓 Education</span>
                <span class="detail-value">{{ profile.education_level }}</span>
              </div>
              <div v-if="profile.relationship_goal" class="detail-item">
                <span class="detail-label">💕 Looking for</span>
                <span class="detail-value">{{ profile.relationship_goal }}</span>
              </div>
              <div v-if="profile.gender" class="detail-item">
                <span class="detail-label">👤 Gender</span>
                <span class="detail-value">{{ profile.gender }}</span>
              </div>
            </div>
          </div>

          <!-- Interests -->
          <div v-if="profile.interests?.length" class="profile-section card">
            <h2 class="profile-section-title">Interests</h2>
            <div class="interests-grouped">
              <div
                v-for="i in profile.interests"
                :key="i.interest_id"
                class="interest-chip"
              >
                {{ catEmoji[i.category] || '⭐' }} {{ i.name }}
              </div>
            </div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="profile-sidebar">
          <div class="profile-section card sidebar-card">
            <h2 class="profile-section-title">Quick Info</h2>
            <div class="quick-info">
              <div class="qi-item"><span>🎂</span> {{ profile.age }} years old</div>
              <div class="qi-item" v-if="profile.city"><span>📍</span> {{ profile.city }}, {{ profile.country }}</div>
              <div class="qi-item" v-if="profile.looking_for"><span>👀</span> Looking for {{ profile.looking_for }}</div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.profile-page { min-height: calc(100vh - var(--nav-height)); background: var(--nude); }
.not-found { text-align: center; padding: 80px; }

.profile-hero {
  position: relative; height: 420px; overflow: hidden;
  background: var(--blush);
}
.profile-hero-photo { width: 100%; height: 100%; }
.profile-hero-photo img { width: 100%; height: 100%; object-fit: cover; }
.profile-photo-placeholder {
  width: 100%; height: 100%; display: flex; align-items: center; justify-content: center;
  font-family: var(--font-display); font-size: 100px; color: var(--coral);
  background: linear-gradient(135deg, var(--blush), #FFD6D6);
}
.profile-hero-overlay {
  position: absolute; inset: 0;
  background: linear-gradient(transparent 30%, rgba(0,0,0,0.75) 100%);
  display: flex; flex-direction: column; justify-content: flex-end;
  padding: 32px; gap: 16px;
}
.profile-hero-content { color: white; }
.profile-hero-content h1 { font-family: var(--font-display); font-size: 36px; margin-bottom: 6px; }
.profile-hero-content p { font-size: 16px; opacity: 0.9; }
.profile-hero-actions { display: flex; gap: 12px; align-items: center; }

.hero-action-btn {
  border: none; cursor: pointer; border-radius: 50px; font-size: 16px;
  font-weight: 700; font-family: var(--font-body); transition: all 0.2s;
  display: flex; align-items: center; gap: 6px;
}
.hero-action-btn.fav {
  width: 48px; height: 48px; border-radius: 50%; background: rgba(255,255,255,0.2);
  backdrop-filter: blur(8px); color: white; font-size: 22px; justify-content: center;
  border: 2px solid rgba(255,255,255,0.4);
}
.hero-action-btn.fav.active { background: var(--gold); border-color: var(--gold); }
.hero-action-btn.fav:hover { background: rgba(255,255,255,0.35); }
.hero-action-btn.like {
  padding: 12px 28px;
  background: linear-gradient(135deg, var(--coral), #FF4E4E);
  color: white; box-shadow: 0 4px 16px rgba(255,107,107,0.4);
  border-radius: 50px;
}
.hero-action-btn.like:hover { transform: scale(1.04); }
.hero-action-btn.like:disabled { opacity: 0.5; cursor: not-allowed; }

.profile-content {
  max-width: 1000px; margin: 0 auto; padding: 32px 24px;
  display: grid; grid-template-columns: 1fr 300px; gap: 24px;
}
.profile-section { padding: 24px; margin-bottom: 20px; }
.profile-section-title { font-family: var(--font-display); font-size: 22px; margin-bottom: 16px; }
.profile-bio { color: var(--slate); line-height: 1.7; font-size: 16px; }
.profile-empty { color: var(--mist); font-style: italic; }

.profile-details-grid {
  display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-top: 20px;
}
.detail-item { display: flex; flex-direction: column; gap: 2px; }
.detail-label { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: var(--mist); }
.detail-value { font-size: 15px; color: var(--ink); font-weight: 500; }

.interests-grouped { display: flex; flex-wrap: wrap; gap: 8px; }
.interest-chip {
  padding: 6px 14px; background: var(--blush); color: var(--crimson);
  border-radius: 50px; font-size: 14px; font-weight: 600;
}

.sidebar-card { margin-bottom: 0; }
.quick-info { display: flex; flex-direction: column; gap: 12px; }
.qi-item { display: flex; align-items: center; gap: 10px; font-size: 15px; color: var(--slate); }
.qi-item span { font-size: 18px; }

@media (max-width: 768px) {
  .profile-content { grid-template-columns: 1fr; }
  .profile-sidebar { order: -1; }
}
</style>
