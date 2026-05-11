<template>
  <div class="container" style="padding-top:32px; padding-bottom:60px;">
    <h1 style="font-size:1.8rem; font-weight:800; margin-bottom:24px;">Your Matches 💕</h1>

    <div v-if="loading" class="text-center" style="padding:60px;">
      <div class="spinner" style="width:40px;height:40px;border-width:4px;margin:0 auto 16px;"></div>
      <p class="text-muted">Loading matches…</p>
    </div>

    <div v-else-if="matches.length === 0" class="empty-state">
      <div style="font-size:4rem;">🌟</div>
      <h2>No matches yet</h2>
      <p class="text-muted">Keep swiping! Your matches will appear here when you and someone else both like each other.</p>
      <RouterLink to="/discover" class="btn btn-primary mt-2">Start Discovering</RouterLink>
    </div>

    <div v-else class="matches-grid">
      <div v-for="match in matches" :key="match.match_id" class="match-card card">
        <div class="match-photo">
          <img :src="getPhoto(match.other_user)" :alt="getName(match)" @error="onImgErr" />
        </div>
        <div class="match-info">
          <div class="match-name">{{ getName(match) }}</div>
          <div class="match-meta" v-if="match.other_profile">
            <span v-if="match.other_profile.age">{{ match.other_profile.age }} yrs</span>
            <span v-if="match.other_profile.city">📍 {{ match.other_profile.city }}</span>
          </div>
          <div class="match-date text-muted">
            Matched {{ formatDate(match.matched_at) }}
          </div>
        </div>
        <div class="match-actions">
          <RouterLink :to="`/messages/${match.conversation_id}`" class="btn btn-primary btn-sm">
            💬 Message
          </RouterLink>
          <RouterLink :to="`/users/${match.other_user?.user_id}`" class="btn btn-outline btn-sm">
            View Profile
          </RouterLink>
          <button class="btn btn-danger btn-sm" @click="confirmUnmatch(match)">Unmatch</button>
        </div>
      </div>
    </div>

    <!-- Confirm unmatch dialog -->
    <div v-if="unmatchTarget" class="modal-overlay" @click.self="unmatchTarget = null">
      <div class="modal-box card">
        <h3>Unmatch with {{ getName(unmatchTarget) }}?</h3>
        <p class="text-muted mt-1">This will remove the match and delete your conversation history.</p>
        <div style="display:flex; gap:12px; margin-top:20px;">
          <button class="btn btn-secondary" @click="unmatchTarget = null">Cancel</button>
          <button class="btn btn-danger" @click="doUnmatch" :disabled="unmatchLoading">
            <span v-if="unmatchLoading" class="spinner"></span>
            Unmatch
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import api from '@/utils/api'

const matches       = ref([])
const loading       = ref(true)
const unmatchTarget = ref(null)
const unmatchLoading = ref(false)

function getName(m) {
  const p = m.other_profile
  const u = m.other_user
  if (p?.first_name) return `${p.first_name} ${p.last_name}`
  return u?.username || 'Unknown'
}

function getPhoto(user) {
  if (!user) return null
  return user.photo || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.username || '?')}&background=e91e8c&color=fff&size=200`
}

function onImgErr(e) { e.target.src = 'https://ui-avatars.com/api/?name=?&background=e91e8c&color=fff&size=200' }

function formatDate(iso) {
  if (!iso) return ''
  const d = new Date(iso)
  return d.toLocaleDateString('en-JM', { month: 'short', day: 'numeric', year: 'numeric' })
}

async function fetchMatches() {
  const { data } = await api.get('/matches')
  matches.value = data
}

function confirmUnmatch(match) { unmatchTarget.value = match }

async function doUnmatch() {
  unmatchLoading.value = true
  try {
    await api.delete(`/matches/${unmatchTarget.value.match_id}`)
    matches.value = matches.value.filter(m => m.match_id !== unmatchTarget.value.match_id)
    unmatchTarget.value = null
  } finally {
    unmatchLoading.value = false
  }
}

onMounted(async () => {
  try { await fetchMatches() }
  finally { loading.value = false }
})
</script>

<style scoped>
.matches-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.match-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.match-photo {
  height: 180px;
  border-radius: 12px;
  overflow: hidden;
}
.match-photo img { width: 100%; height: 100%; object-fit: cover; }

.match-name { font-size: 1.1rem; font-weight: 700; }
.match-meta { display: flex; gap: 12px; color: #6c757d; font-size: 0.88rem; margin-top: 4px; }
.match-date { font-size: 0.8rem; margin-top: 4px; }

.match-actions { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 4px; }

.empty-state { text-align: center; padding: 80px 20px; }
.empty-state h2 { font-size: 1.5rem; font-weight: 700; margin: 12px 0; }

.modal-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex; align-items: center; justify-content: center;
  z-index: 9999;
}
.modal-box { max-width: 420px; width: 90%; }
</style>
