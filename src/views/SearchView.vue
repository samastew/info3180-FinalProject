<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/services/api'

const router   = useRouter()
const results  = ref([])
const loading  = ref(false)
const searched = ref(false)

const filters = ref({ name: '', city: '', gender: '' })

async function search() {
  loading.value  = true
  searched.value = true
  try {
    const params = new URLSearchParams()
    if (filters.value.name)   params.set('name', filters.value.name)
    if (filters.value.city)   params.set('city', filters.value.city)
    if (filters.value.gender) params.set('gender', filters.value.gender)
    const res = await api.get(`/profiles/search?${params}`)
    results.value = res.data.profiles
  } catch {}
  loading.value = false
}

function viewProfile(uid) {
  router.push({ name: 'profile', params: { userId: uid } })
}

function initials(p) {
  return `${p?.first_name?.[0] || ''}${p?.last_name?.[0] || ''}`.toUpperCase()
}

async function sendLike(uid) {
  try { await api.post('/swipes', { swiped_id: uid, action: 'like' }) } catch {}
}

async function addFav(uid) {
  try { await api.post(`/favorites/${uid}`) } catch {}
}
</script>

<template>
  <div class="search-page">
    <div class="search-inner">
      <h1 class="section-title">Search Profiles</h1>
      <p class="section-sub">Find people by name, city, or gender</p>

      <!-- Search Form -->
      <div class="search-form card">
        <div class="search-row">
          <div class="form-group">
            <label class="form-label">Name</label>
            <input v-model="filters.name" type="text" class="form-control" placeholder="Search by name…" @keyup.enter="search" />
          </div>
          <div class="form-group">
            <label class="form-label">City</label>
            <input v-model="filters.city" type="text" class="form-control" placeholder="e.g. Kingston" @keyup.enter="search" />
          </div>
          <div class="form-group">
            <label class="form-label">Gender</label>
            <select v-model="filters.gender" class="form-control">
              <option value="">Any gender</option>
              <option value="female">Female</option>
              <option value="male">Male</option>
              <option value="non-binary">Non-binary</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div class="form-group search-btn-group">
            <label class="form-label" style="opacity:0">Search</label>
            <button class="btn btn-primary" @click="search" :disabled="loading">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
              {{ loading ? 'Searching…' : 'Search' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Results -->
      <div v-if="loading" style="text-align:center;padding:60px 0">
        <div class="spinner"></div>
      </div>

      <div v-else-if="searched && !results.length" class="search-empty">
        <div class="empty-icon">🔍</div>
        <h2>No results found</h2>
        <p>Try different search terms.</p>
      </div>

      <div v-else-if="results.length" class="search-results">
        <p class="results-count">{{ results.length }} profile{{ results.length !== 1 ? 's' : '' }} found</p>
        <div class="results-grid">
          <div v-for="p in results" :key="p.user_id" class="result-card">
            <div class="result-photo" @click="viewProfile(p.user_id)">
              <img v-if="p.profile_photo_url" :src="p.profile_photo_url" :alt="p.first_name" />
              <div v-else class="result-photo-placeholder">{{ initials(p) }}</div>
            </div>
            <div class="result-info">
              <h3>{{ p.first_name }} {{ p.last_name }}</h3>
              <p class="result-meta">
                <span v-if="p.age">{{ p.age }} yrs</span>
                <span v-if="p.city"> · {{ p.city }}</span>
              </p>
              <p v-if="p.bio" class="result-bio">{{ p.bio.slice(0, 80) }}{{ p.bio.length > 80 ? '…' : '' }}</p>
              <div class="result-tags">
                <span v-for="i in (p.interests || []).slice(0,4)" :key="i.interest_id" class="r-tag">{{ i.name }}</span>
              </div>
              <div class="result-actions">
                <button class="btn btn-primary btn-xs" @click="sendLike(p.user_id)">❤️ Like</button>
                <button class="btn btn-secondary btn-xs" @click="addFav(p.user_id)">⭐ Save</button>
                <button class="btn btn-ghost btn-xs" @click="viewProfile(p.user_id)">View →</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.search-page { min-height: calc(100vh - var(--nav-height)); background: var(--nude); padding: 40px 24px; }
.search-inner { max-width: 1100px; margin: 0 auto; }

.search-form { padding: 24px; margin-bottom: 28px; }
.search-row {
  display: grid; grid-template-columns: 1fr 1fr 1fr auto; gap: 16px; align-items: start;
}
.search-btn-group { display: flex; flex-direction: column; }

.search-empty { text-align: center; padding: 60px 24px; }
.empty-icon { font-size: 56px; margin-bottom: 12px; }
.search-empty h2 { font-family: var(--font-display); font-size: 24px; margin-bottom: 8px; }
.search-empty p { color: var(--mist); }

.results-count { color: var(--mist); font-size: 14px; margin-bottom: 16px; }
.results-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }

.result-card {
  background: white; border-radius: var(--radius-lg); box-shadow: var(--shadow-sm);
  display: flex; gap: 0; overflow: hidden; transition: transform 0.2s, box-shadow 0.2s;
}
.result-card:hover { transform: translateY(-2px); box-shadow: var(--shadow-md); }

.result-photo {
  width: 110px; flex-shrink: 0; cursor: pointer; background: var(--blush);
}
.result-photo img { width: 100%; height: 100%; object-fit: cover; display: block; }
.result-photo-placeholder {
  width: 100%; height: 100%; min-height: 140px; display: flex; align-items: center; justify-content: center;
  font-family: var(--font-display); font-size: 40px; color: var(--coral);
  background: linear-gradient(135deg, var(--blush), #FFD6D6);
}

.result-info { padding: 14px; flex: 1; }
.result-info h3 { font-family: var(--font-display); font-size: 17px; margin-bottom: 2px; }
.result-meta { color: var(--mist); font-size: 13px; margin-bottom: 6px; }
.result-bio { font-size: 13px; color: var(--slate); line-height: 1.4; margin-bottom: 8px; }
.result-tags { display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 10px; }
.r-tag { padding: 2px 8px; background: var(--blush); color: var(--crimson); border-radius: 50px; font-size: 11px; font-weight: 600; }
.result-actions { display: flex; gap: 6px; flex-wrap: wrap; }
.btn-xs { padding: 5px 12px; font-size: 12px; }

@media (max-width: 768px) {
  .search-row { grid-template-columns: 1fr 1fr; }
  .search-btn-group { grid-column: 1 / -1; }
}
</style>
