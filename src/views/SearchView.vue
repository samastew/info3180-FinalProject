<template>
  <div class="container" style="padding-top:32px; padding-bottom:60px;">
    <h1 style="font-size:1.8rem; font-weight:800; margin-bottom:24px;">Search & Discover 🔍</h1>

    <div class="search-panel card mb-3">
      <div class="search-bar">
        <input
          v-model="filters.q"
          class="form-control"
          placeholder="Search by name, bio, occupation…"
          @keydown.enter="runSearch"
        />
        <button class="btn btn-primary" @click="runSearch" :disabled="loading">
          <span v-if="loading" class="spinner"></span>
          Search
        </button>
      </div>

      <div class="filter-grid mt-2">
        <div class="form-group">
          <label>City</label>
          <input v-model="filters.city" class="form-control" placeholder="e.g. Kingston" />
        </div>
        <div class="form-group">
          <label>Gender</label>
          <select v-model="filters.gender" class="form-control">
            <option value="">Any</option>
            <option value="male">Men</option>
            <option value="female">Women</option>
            <option value="non_binary">Non-Binary</option>
          </select>
        </div>
        <div class="form-group">
          <label>Min Age</label>
          <input v-model.number="filters.min_age" type="number" class="form-control" min="18" max="99" />
        </div>
        <div class="form-group">
          <label>Max Age</label>
          <input v-model.number="filters.max_age" type="number" class="form-control" min="18" max="99" />
        </div>
        <div class="form-group">
          <label>Relationship Goal</label>
          <select v-model="filters.relationship_goal" class="form-control">
            <option value="">Any</option>
            <option value="casual">Casual</option>
            <option value="serious">Serious</option>
            <option value="friendship">Friendship</option>
            <option value="marriage">Marriage</option>
          </select>
        </div>
        <div class="form-group">
          <label>Sort By</label>
          <select v-model="filters.sort" class="form-control">
            <option value="newest">Newest</option>
            <option value="most_similar">Most Similar</option>
          </select>
        </div>
      </div>

      <div style="margin-top:8px;">
        <label style="font-weight:600; font-size:0.88rem; color:#495057;">Filter by Interests</label>
        <div class="interests-filter mt-1">
          <button
            v-for="interest in allInterests" :key="interest.interest_id"
            type="button"
            class="interest-btn"
            :class="{ selected: filters.interest_ids.includes(interest.interest_id) }"
            @click="toggleInterest(interest.interest_id)"
          >{{ interest.name }}</button>
        </div>
      </div>

      <div style="display:flex; gap:10px; margin-top:16px;">
        <button class="btn btn-primary" @click="runSearch" :disabled="loading">Search</button>
        <button class="btn btn-secondary" @click="clearFilters">Clear</button>
      </div>
    </div>

    <!-- Results -->
    <div v-if="hasSearched">
      <div v-if="loading" class="text-center" style="padding:40px;">
        <div class="spinner" style="width:36px;height:36px;border-width:3px;margin:0 auto;"></div>
      </div>

      <div v-else>
        <p class="text-muted mb-2">{{ total }} result{{ total !== 1 ? 's' : '' }} found</p>

        <div v-if="profiles.length === 0" class="empty-state">
          <div style="font-size:3rem;">🔍</div>
          <h2>No results found</h2>
          <p class="text-muted">Try different filters or search terms.</p>
        </div>

        <div v-else class="results-grid">
          <RouterLink
            v-for="profile in profiles"
            :key="profile.user_id"
            :to="`/users/${profile.user_id}`"
            class="result-card"
          >
            <div class="result-photo">
              <img :src="getPhoto(profile)" :alt="getName(profile)" @error="onImgErr" />
            </div>
            <div class="result-info">
              <div class="result-name">{{ getName(profile) }}</div>
              <div class="result-meta text-muted">
                <span v-if="profile.age">{{ profile.age }} yrs</span>
                <span v-if="profile.city">📍 {{ profile.city }}</span>
                <span v-if="profile.relationship_goal">{{ cap(profile.relationship_goal) }}</span>
              </div>
              <p v-if="profile.bio" class="result-bio">{{ truncate(profile.bio, 60) }}</p>
              <div v-if="profile.shared_interests > 0" class="shared-badge">
                ✨ {{ profile.shared_interests }} shared
              </div>
              <div v-if="profile.interests?.length" class="result-tags">
                <span v-for="i in profile.interests.slice(0,3)" :key="i.interest_id" class="tag">{{ i.name }}</span>
              </div>
            </div>
          </RouterLink>
        </div>

        <!-- Pagination -->
        <div v-if="totalPages > 1" class="pagination mt-3">
          <button class="btn btn-outline btn-sm" @click="changePage(page-1)" :disabled="page <= 1">← Prev</button>
          <span class="text-muted">Page {{ page }} of {{ totalPages }}</span>
          <button class="btn btn-outline btn-sm" @click="changePage(page+1)" :disabled="page >= totalPages">Next →</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import api from '@/utils/api'

const allInterests = ref([])
const profiles     = ref([])
const loading      = ref(false)
const hasSearched  = ref(false)
const total        = ref(0)
const page         = ref(1)
const totalPages   = ref(1)

const filters = ref({
  q: '', city: '', gender: '', min_age: '', max_age: '',
  relationship_goal: '', sort: 'newest', interest_ids: []
})

function getName(p) {
  if (p.first_name) return `${p.first_name} ${p.last_name}`
  return p.user?.username || 'Unknown'
}

function getPhoto(p) {
  const photos = p.photos || p.user?.photos || []
  const primary = photos.find(ph => ph.is_primary)
  return (primary || photos[0])?.photo_url ||
    `https://ui-avatars.com/api/?name=${encodeURIComponent(getName(p))}&background=e91e8c&color=fff&size=100`
}

function onImgErr(e) { e.target.src = 'https://ui-avatars.com/api/?name=?&background=e91e8c&color=fff&size=100' }

function truncate(s, l) { return s && s.length > l ? s.slice(0, l) + '…' : s }
function cap(s) { return s ? s.replace(/_/g,' ').replace(/\b\w/g, c => c.toUpperCase()) : '' }

function toggleInterest(id) {
  const idx = filters.value.interest_ids.indexOf(id)
  if (idx === -1) filters.value.interest_ids.push(id)
  else filters.value.interest_ids.splice(idx, 1)
}

async function runSearch(pageNum) {
  // pageNum may be a MouseEvent when called directly from @click — normalize to a number
  if (typeof pageNum !== 'number') pageNum = 1
  loading.value   = true
  hasSearched.value = true
  const params = new URLSearchParams({ page: pageNum, limit: 16, sort: filters.value.sort })
  if (filters.value.q)                 params.set('q',                 filters.value.q)
  if (filters.value.city)              params.set('city',              filters.value.city)
  if (filters.value.gender)            params.set('gender',            filters.value.gender)
  if (filters.value.min_age)           params.set('min_age',           filters.value.min_age)
  if (filters.value.max_age)           params.set('max_age',           filters.value.max_age)
  if (filters.value.relationship_goal) params.set('relationship_goal', filters.value.relationship_goal)
  filters.value.interest_ids.forEach(id => params.append('interest_ids', id))

  try {
    const { data } = await api.get(`/search?${params}`)
    profiles.value   = data.profiles  || []
    total.value      = data.total     || 0
    page.value       = data.page      || pageNum
    totalPages.value = data.pages     || 1
  } catch (err) {
    console.error('Search failed:', err)
    profiles.value   = []
    total.value      = 0
    totalPages.value = 1
  } finally {
    loading.value = false
  }
}

function changePage(p) {
  if (typeof p !== 'number' || p < 1 || p > totalPages.value) return
  runSearch(p)
}

function clearFilters() {
  filters.value = { q: '', city: '', gender: '', min_age: '', max_age: '', relationship_goal: '', sort: 'newest', interest_ids: [] }
  profiles.value = []
  hasSearched.value = false
}

onMounted(async () => {
  const { data } = await api.get('/interests')
  allInterests.value = data
})
</script>

<style scoped>
.search-bar { display: flex; gap: 10px; }
.search-bar .form-control { flex: 1; }

.filter-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 10px;
}

.interests-filter { display: flex; flex-wrap: wrap; gap: 6px; }
.interest-btn {
  padding: 4px 12px;
  border: 2px solid #dee2e6;
  border-radius: 20px;
  background: none;
  cursor: pointer;
  font-size: 0.8rem;
  transition: all 0.15s;
}
.interest-btn.selected { border-color: #e91e8c; background: #fce4ec; color: #c2157a; font-weight: 600; }

.results-grid {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.result-card {
  display: flex;
  gap: 16px;
  background: #fff;
  border-radius: 14px;
  padding: 16px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.07);
  text-decoration: none;
  color: inherit;
  transition: transform 0.2s, box-shadow 0.2s;
}
.result-card:hover { transform: translateY(-2px); box-shadow: 0 6px 18px rgba(0,0,0,0.1); }

.result-photo {
  width: 80px; height: 80px;
  border-radius: 12px;
  overflow: hidden;
  flex-shrink: 0;
}
.result-photo img { width: 100%; height: 100%; object-fit: cover; }

.result-info { flex: 1; min-width: 0; }
.result-name { font-weight: 700; font-size: 1rem; }
.result-meta { font-size: 0.82rem; display: flex; flex-wrap: wrap; gap: 8px; margin-top: 4px; }
.result-bio  { font-size: 0.85rem; color: #495057; margin-top: 4px; }
.shared-badge { font-size: 0.8rem; color: #e91e8c; font-weight: 600; margin-top: 4px; }
.result-tags { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 6px; }
.tag {
  background: #f0f0f0;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 0.75rem;
}

.empty-state { text-align: center; padding: 60px 20px; }
.empty-state h2 { margin: 12px 0 8px; font-size: 1.4rem; font-weight: 700; }

.pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
}
</style>
