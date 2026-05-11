<template>
  <div class="container" style="padding-top:32px; padding-bottom:60px;">
    <div v-if="loading" class="text-center" style="padding:60px;">
      <div class="spinner" style="width:40px;height:40px;border-width:4px;margin:0 auto;"></div>
    </div>
    <div v-else-if="!userData" class="text-center" style="padding:60px;">
      <h2>User not found</h2>
    </div>
    <div v-else class="user-profile-layout">
      <!-- Photos sidebar -->
      <div class="user-sidebar">
        <div class="photo-carousel">
          <img
            :src="currentPhoto || fallback"
            :alt="fullName"
            class="main-photo"
            @error="e => e.target.src = fallback"
          />
          <div v-if="userData.photos.length > 1" class="photo-nav">
            <button @click="prevPhoto">‹</button>
            <span>{{ photoIdx + 1 }} / {{ userData.photos.length }}</span>
            <button @click="nextPhoto">›</button>
          </div>
        </div>

        <!-- Thumbnails -->
        <div class="photo-dots" v-if="userData.photos.length > 1">
          <span
            v-for="(p, i) in userData.photos" :key="p.photo_id"
            class="dot" :class="{ active: i === photoIdx }"
            @click="photoIdx = i"
          ></span>
        </div>

        <!-- Action buttons -->
        <div class="sidebar-actions" v-if="!isMe">
          <button
            class="btn btn-success"
            :class="{ 'btn-secondary': swipeAction === 'like' }"
            @click="doSwipe('like')"
            :disabled="swipeLoading"
          >
            {{ swipeAction === 'like' ? '❤️ Liked' : '❤️ Like' }}
          </button>
          <button
            class="btn btn-danger"
            :class="{ 'btn-secondary': swipeAction === 'dislike' }"
            @click="doSwipe('dislike')"
            :disabled="swipeLoading"
          >
            ❌ Dislike
          </button>
          <button
            :class="isFavorited ? 'btn btn-outline' : 'btn btn-outline'"
            @click="toggleFavorite"
            :disabled="favLoading"
          >
            {{ isFavorited ? '⭐ Saved' : '☆ Save' }}
          </button>
        </div>

        <!-- Report/Block -->
        <div v-if="!isMe" style="margin-top:12px; display:flex; gap:8px; flex-wrap:wrap;">
          <button class="btn btn-secondary btn-sm" @click="showReport = true">🚩 Report</button>
          <button class="btn btn-danger btn-sm" @click="doBlock">🚫 Block</button>
        </div>
      </div>

      <!-- Profile details -->
      <div class="user-main">
        <div class="card mb-2">
          <h1 style="font-size:1.8rem; font-weight:800;">
            {{ fullName }}
            <span v-if="userData.profile?.age" style="font-weight:400; font-size:1rem; color:#6c757d;">
              {{ userData.profile.age }}
            </span>
          </h1>
          <p class="text-muted" v-if="userData.profile?.city">
            📍 {{ userData.profile.city }}, {{ userData.profile.country }}
          </p>

          <p v-if="userData.profile?.bio" style="margin-top:12px; line-height:1.6;">
            {{ userData.profile.bio }}
          </p>
        </div>

        <div class="card mb-2">
          <h3 style="font-weight:700; margin-bottom:14px;">About</h3>
          <div class="detail-grid">
            <div v-if="userData.profile?.gender" class="detail-item">
              <span class="detail-label">Gender</span>
              <span>{{ cap(userData.profile.gender) }}</span>
            </div>
            <div v-if="userData.profile?.occupation" class="detail-item">
              <span class="detail-label">Occupation</span>
              <span>{{ userData.profile.occupation }}</span>
            </div>
            <div v-if="userData.profile?.education_level" class="detail-item">
              <span class="detail-label">Education</span>
              <span>{{ cap(userData.profile.education_level) }}</span>
            </div>
            <div v-if="userData.profile?.relationship_goal" class="detail-item">
              <span class="detail-label">Looking for</span>
              <span>{{ cap(userData.profile.relationship_goal) }}</span>
            </div>
          </div>
        </div>

        <div class="card" v-if="userData.interests?.length">
          <h3 style="font-weight:700; margin-bottom:12px;">Interests</h3>
          <div class="tags-wrap">
            <span
              v-for="i in userData.interests" :key="i.interest_id"
              class="tag"
              :class="{ shared: myInterestIds.has(i.interest_id) }"
            >
              {{ myInterestIds.has(i.interest_id) ? '✨' : '' }} {{ i.name }}
            </span>
          </div>
          <p v-if="sharedCount > 0" class="text-muted" style="font-size:0.85rem; margin-top:8px;">
            You share {{ sharedCount }} interest{{ sharedCount > 1 ? 's' : '' }}!
          </p>
        </div>

        <!-- Match notification -->
        <div v-if="matchBanner" class="match-banner alert alert-success mt-2">
          🎉 It's a match! <RouterLink :to="`/messages/${matchBanner.conversation_id}`">Send a message →</RouterLink>
        </div>
      </div>
    </div>

    <!-- Report modal -->
    <div v-if="showReport" class="modal-overlay" @click.self="showReport = false">
      <div class="modal-box card">
        <h3>Report User</h3>
        <div class="form-group mt-2">
          <label>Reason</label>
          <select v-model="reportReason" class="form-control">
            <option value="">Select reason…</option>
            <option>Spam account</option>
            <option>Harassment</option>
            <option>Fake profile</option>
            <option>Inappropriate messages</option>
            <option>Offensive content</option>
          </select>
        </div>
        <div style="display:flex; gap:10px; margin-top:16px;">
          <button class="btn btn-secondary" @click="showReport = false">Cancel</button>
          <button class="btn btn-danger" @click="submitReport" :disabled="!reportReason">Submit Report</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/utils/api'

const route  = useRoute()
const router = useRouter()
const auth   = useAuthStore()

const userId     = computed(() => Number(route.params.userId))
const isMe       = computed(() => auth.user?.user_id === userId.value)
const userData   = ref(null)
const loading    = ref(true)
const photoIdx   = ref(0)
const swipeAction = ref(null)
const swipeLoading = ref(false)
const isFavorited  = ref(false)
const favLoading   = ref(false)
const matchBanner  = ref(null)
const showReport   = ref(false)
const reportReason = ref('')

const fallback = computed(() =>
  `https://ui-avatars.com/api/?name=${encodeURIComponent(fullName.value || '?')}&background=e91e8c&color=fff&size=300`
)

const fullName = computed(() => {
  const p = userData.value?.profile
  if (p?.first_name) return `${p.first_name} ${p.last_name}`
  return userData.value?.user?.username || 'User'
})

const currentPhoto = computed(() => {
  const photos = userData.value?.photos || []
  return photos[photoIdx.value]?.photo_url || null
})

const myInterestIds = computed(() => new Set(auth.interests.map(i => i.interest_id)))

const sharedCount = computed(() => {
  if (!userData.value?.interests) return 0
  return userData.value.interests.filter(i => myInterestIds.value.has(i.interest_id)).length
})

function prevPhoto() {
  const l = userData.value?.photos?.length || 1
  photoIdx.value = (photoIdx.value - 1 + l) % l
}
function nextPhoto() {
  const l = userData.value?.photos?.length || 1
  photoIdx.value = (photoIdx.value + 1) % l
}

function cap(s) { return s ? s.replace(/_/g,' ').replace(/\b\w/g,c=>c.toUpperCase()) : '' }

async function doSwipe(action) {
  swipeLoading.value = true
  try {
    const { data } = await api.post('/swipe', { user_id: userId.value, action })
    swipeAction.value = action
    if (data.matched && data.match) matchBanner.value = data.match
  } finally {
    swipeLoading.value = false
  }
}

async function toggleFavorite() {
  favLoading.value = true
  try {
    if (isFavorited.value) {
      await api.delete(`/favorites/${userId.value}`)
      isFavorited.value = false
    } else {
      await api.post(`/favorites/${userId.value}`)
      isFavorited.value = true
    }
  } finally {
    favLoading.value = false
  }
}

async function doBlock() {
  if (!confirm('Block this user? They will no longer appear in your discover feed.')) return
  await api.post(`/users/${userId.value}/block`)
  router.push('/discover')
}

async function submitReport() {
  await api.post(`/users/${userId.value}/report`, { reason: reportReason.value })
  showReport.value = false
  reportReason.value = ''
  alert('Report submitted. Thank you.')
}

onMounted(async () => {
  try {
    const { data } = await api.get(`/users/${userId.value}`)
    userData.value    = data
    swipeAction.value = data.swipe_action
    isFavorited.value = data.is_favorited
    // Set primary photo index
    const primaryIdx = data.photos?.findIndex(p => p.is_primary)
    if (primaryIdx > -1) photoIdx.value = primaryIdx
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.user-profile-layout {
  display: grid;
  grid-template-columns: 300px 1fr;
  gap: 24px;
  align-items: flex-start;
}
@media (max-width: 768px) {
  .user-profile-layout { grid-template-columns: 1fr; }
}

.user-sidebar { display: flex; flex-direction: column; gap: 12px; }

.photo-carousel {
  position: relative;
  border-radius: 16px;
  overflow: hidden;
  height: 340px;
}
.main-photo { width: 100%; height: 100%; object-fit: cover; }

.photo-nav {
  position: absolute;
  bottom: 10px; left: 50%; transform: translateX(-50%);
  background: rgba(0,0,0,0.5);
  color: #fff;
  border-radius: 20px;
  padding: 4px 12px;
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 0.85rem;
}
.photo-nav button {
  background: none; border: none; color: #fff;
  font-size: 1.2rem; cursor: pointer; padding: 0;
}

.photo-dots { display: flex; gap: 6px; justify-content: center; }
.dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  background: #dee2e6;
  cursor: pointer;
  transition: background 0.2s;
}
.dot.active { background: #e91e8c; }

.sidebar-actions { display: flex; flex-direction: column; gap: 8px; }
.sidebar-actions .btn { justify-content: center; }

.detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.detail-item { display: flex; flex-direction: column; gap: 2px; }
.detail-label { font-size: 0.75rem; font-weight: 700; color: #6c757d; text-transform: uppercase; }

.tags-wrap { display: flex; flex-wrap: wrap; gap: 8px; }
.tag {
  background: #f0f0f0;
  color: #495057;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.85rem;
  font-weight: 500;
}
.tag.shared { background: #fce4ec; color: #c2157a; font-weight: 700; }

.match-banner { font-weight: 600; }
.match-banner a { color: #155724; font-weight: 700; }

.modal-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex; align-items: center; justify-content: center;
  z-index: 9999;
}
.modal-box { max-width: 400px; width: 90%; }
</style>
