<template>
  <div class="discover-page">
    <div class="discover-layout">

      <!-- ── Sidebar ──────────────────────────────────────────────── -->
      <aside class="discover-sidebar">
        <div class="sidebar-header">
          <h2 class="sidebar-title">Discover 💕</h2>
          <span class="profile-count">{{ profiles.length }} profiles</span>
        </div>

        <div class="card filters-card">
          <div class="filters-title-row">
            <h3 class="filters-heading">Filters</h3>
            <span v-if="activeFilterCount" class="filter-badge">{{ activeFilterCount }}</span>
          </div>

          <div class="form-group">
            <label class="filter-label">Gender</label>
            <select v-model="filters.gender" class="form-control">
              <option value="">Any</option>
              <option value="male">Men</option>
              <option value="female">Women</option>
              <option value="non-binary">Non-Binary</option>
              <option value="other">Other</option>
            </select>
          </div>

          <div class="form-group">
            <label class="filter-label">Age range: <strong>{{ filters.min_age }} – {{ filters.max_age }}</strong></label>
            <div class="range-row">
              <input v-model.number="filters.min_age" type="range" min="18" max="99" class="range-input" />
              <input v-model.number="filters.max_age" type="range" min="18" max="99" class="range-input" />
            </div>
          </div>

          <div class="form-group">
            <label class="filter-label">Max distance (km)</label>
            <input v-model.number="filters.max_distance_km" type="number" class="form-control" min="1" max="500" />
          </div>

          <div class="form-group">
            <label class="filter-label">Relationship goal</label>
            <select v-model="filters.relationship_goal" class="form-control">
              <option value="">Any</option>
              <option value="casual">Casual</option>
              <option value="serious">Serious</option>
              <option value="friendship">Friendship</option>
              <option value="marriage">Marriage</option>
            </select>
          </div>

          <div class="filter-actions">
            <button class="btn btn-primary btn-sm" @click="applyFilters">Apply</button>
            <button class="btn btn-outline btn-sm" @click="resetFilters">Reset</button>
          </div>
        </div>

        <!-- Up-next preview thumbnails -->
        <div v-if="profiles.length > 1" class="up-next card">
          <p class="up-next-label">Up next</p>
          <div class="up-next-avatars">
            <div
              v-for="p in profiles.slice(1, 5)"
              :key="p.user_id"
              class="up-next-avatar"
              :title="`${p.first_name} ${p.last_name}`"
            >
              <img
                v-if="p.photos && p.photos[0]"
                :src="p.photos[0].photo_url"
                :alt="p.first_name"
              />
              <span v-else>{{ (p.first_name || '?')[0].toUpperCase() }}</span>
            </div>
            <span v-if="profiles.length > 5" class="up-next-more">+{{ profiles.length - 5 }}</span>
          </div>
        </div>
      </aside>

      <!-- ── Main content ─────────────────────────────────────────── -->
      <main class="discover-main">

        <!-- Mobile filter toggle -->
        <div class="mobile-filter-toggle">
          <h2 class="sidebar-title">Discover 💕</h2>
          <button class="btn btn-outline btn-sm" @click="mobileFilters = !mobileFilters">
            🔧 Filters{{ activeFilterCount ? ` (${activeFilterCount})` : '' }}
          </button>
        </div>

        <!-- Mobile filters panel -->
        <div v-if="mobileFilters" class="card mb-3">
          <div class="filter-grid">
            <div class="form-group">
              <label class="filter-label">Gender</label>
              <select v-model="filters.gender" class="form-control">
                <option value="">Any</option>
                <option value="male">Men</option>
                <option value="female">Women</option>
                <option value="non-binary">Non-Binary</option>
                <option value="other">Other</option>
              </select>
            </div>
            <div class="form-group">
              <label class="filter-label">Min Age</label>
              <input v-model.number="filters.min_age" type="number" class="form-control" min="18" max="99" />
            </div>
            <div class="form-group">
              <label class="filter-label">Max Age</label>
              <input v-model.number="filters.max_age" type="number" class="form-control" min="18" max="99" />
            </div>
            <div class="form-group">
              <label class="filter-label">Max Distance (km)</label>
              <input v-model.number="filters.max_distance_km" type="number" class="form-control" min="1" max="500" />
            </div>
            <div class="form-group">
              <label class="filter-label">Relationship Goal</label>
              <select v-model="filters.relationship_goal" class="form-control">
                <option value="">Any</option>
                <option value="casual">Casual</option>
                <option value="serious">Serious</option>
                <option value="friendship">Friendship</option>
                <option value="marriage">Marriage</option>
              </select>
            </div>
          </div>
          <div class="filter-actions">
            <button class="btn btn-primary btn-sm" @click="applyFilters">Apply</button>
            <button class="btn btn-outline btn-sm" @click="resetFilters">Reset</button>
          </div>
        </div>

        <!-- Loading state -->
        <div v-if="loading" class="state-center">
          <div class="spinner" style="width:44px;height:44px;border-width:4px;margin:0 auto 20px;"></div>
          <p class="text-muted">Finding great matches for you…</p>
        </div>

        <!-- Empty state -->
        <div v-else-if="profiles.length === 0" class="state-center empty-state">
          <div class="empty-icon">🎉</div>
          <h2 class="empty-title">You've seen everyone!</h2>
          <p class="text-muted">Adjust your filters or check back later for new profiles.</p>
          <button class="btn btn-primary mt-2" @click="resetFilters">Reset Filters</button>
        </div>

        <!-- Profile cards grid -->
        <div v-else class="profiles-grid">
          <div
            v-for="profile in profiles"
            :key="profile.user_id"
            class="profile-wrap"
            :class="{
              'swiping-like':    swipingId === profile.user_id && swipingAction === 'like',
              'swiping-dislike': swipingId === profile.user_id && swipingAction === 'dislike',
              'swiping-pass':    swipingId === profile.user_id && swipingAction === 'pass',
            }"
          >
            <RouterLink :to="`/users/${profile.user_id}`" class="profile-link">
              <ProfileCard :profile="profile" :show-actions="false" />
            </RouterLink>

            <div class="swipe-actions">
              <button
                class="action-btn pass"
                :disabled="!!swipingId"
                @click="doSwipe(profile.user_id, 'pass')"
                title="Pass"
              >🤷</button>
              <button
                class="action-btn dislike"
                :disabled="!!swipingId"
                @click="doSwipe(profile.user_id, 'dislike')"
                title="Dislike"
              >❌</button>
              <button
                class="action-btn like"
                :disabled="!!swipingId"
                @click="doSwipe(profile.user_id, 'like')"
                title="Like"
              >❤️</button>
            </div>
          </div>
        </div>

        <!-- Load more -->
        <div v-if="profiles.length > 0 && page < totalPages" class="load-more-wrap">
          <button class="btn btn-outline" @click="loadMore" :disabled="loadingMore">
            <span v-if="loadingMore" class="spinner" style="width:16px;height:16px;border-width:2px;"></span>
            {{ loadingMore ? 'Loading…' : 'Load More' }}
          </button>
        </div>
      </main>
    </div>

    <!-- ── Match notification overlay ──────────────────────────── -->
    <Transition name="pop">
      <div v-if="matchNotif" class="match-overlay" @click.self="matchNotif = null">
        <div class="match-modal">
          <button class="match-close" @click="matchNotif = null">✕</button>
          <div class="match-hearts">💕</div>
          <h2 class="match-title">It's a Match!</h2>
          <p class="match-sub">
            You and <strong>{{ matchNotif.other_name }}</strong> liked each other!
          </p>
          <div class="match-actions">
            <RouterLink
              :to="`/messages/${matchNotif.conversation_id}`"
              class="btn btn-primary"
              @click="matchNotif = null"
            >
              Send Message 💬
            </RouterLink>
            <button class="btn btn-outline match-keep" @click="matchNotif = null">Keep Swiping</button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import ProfileCard from '@/components/ProfileCard.vue'
import api from '@/utils/api'

// ── State ────────────────────────────────────────────────────────────────
const profiles      = ref([])
const loading       = ref(true)
const loadingMore   = ref(false)
const page          = ref(1)
const totalPages    = ref(1)
const mobileFilters = ref(false)
const matchNotif    = ref(null)
const swipingId     = ref(null)
const swipingAction = ref(null)

const filters = ref({
  gender: '',
  min_age: 18,
  max_age: 55,
  max_distance_km: 100,
  relationship_goal: '',
})

// ── Computed ─────────────────────────────────────────────────────────────
const activeFilterCount = computed(() => {
  let c = 0
  if (filters.value.gender) c++
  if (filters.value.relationship_goal) c++
  if (filters.value.min_age !== 18 || filters.value.max_age !== 55) c++
  if (filters.value.max_distance_km !== 100) c++
  return c
})

// ── API helpers ───────────────────────────────────────────────────────────
async function fetchProfiles(p = 1, append = false) {
  const params = new URLSearchParams({ page: p, limit: 12 })
  if (filters.value.gender)                    params.set('gender',            filters.value.gender)
  if (filters.value.min_age !== 18)            params.set('min_age',           filters.value.min_age)
  if (filters.value.max_age !== 55)            params.set('max_age',           filters.value.max_age)
  if (filters.value.max_distance_km !== 100)   params.set('max_distance_km',   filters.value.max_distance_km)
  if (filters.value.relationship_goal)         params.set('relationship_goal', filters.value.relationship_goal)

  const { data } = await api.get(`/discover?${params}`)
  const incoming = data.profiles || []
  if (append) profiles.value.push(...incoming)
  else profiles.value = incoming
  totalPages.value = data.pages ?? 1
  page.value = p
}

async function loadMore() {
  loadingMore.value = true
  try { await fetchProfiles(page.value + 1, true) }
  finally { loadingMore.value = false }
}

function applyFilters() {
  mobileFilters.value = false
  page.value = 1
  loading.value = true
  fetchProfiles(1).finally(() => { loading.value = false })
}

function resetFilters() {
  filters.value = { gender: '', min_age: 18, max_age: 55, max_distance_km: 100, relationship_goal: '' }
  applyFilters()
}

async function doSwipe(userId, action) {
  if (swipingId.value) return   // prevent double-tap while animating

  swipingId.value     = userId
  swipingAction.value = action

  // Let the CSS animation play, then remove the card
  await new Promise(r => setTimeout(r, 350))
  profiles.value      = profiles.value.filter(p => p.user_id !== userId)
  swipingId.value     = null
  swipingAction.value = null

  try {
    const { data } = await api.post('/swipe', { user_id: userId, action })
    if (data.matched && data.match) {
      matchNotif.value = data.match
      setTimeout(() => { if (matchNotif.value) matchNotif.value = null }, 10000)
    }
  } catch (e) {
    console.error('Swipe error', e)
  }
}

onMounted(async () => {
  try { await fetchProfiles() }
  finally { loading.value = false }
})
</script>

<style scoped>
/* ── Layout ──────────────────────────────────────────────────────────── */
.discover-page {
  min-height: calc(100vh - 140px);
  padding: 28px 20px 60px;
  background: #f8f9fa;
}

.discover-layout {
  display: grid;
  grid-template-columns: 272px 1fr;
  gap: 28px;
  max-width: 1200px;
  margin: 0 auto;
  align-items: start;
}

/* ── Sidebar ─────────────────────────────────────────────────────────── */
.discover-sidebar {
  position: sticky;
  top: 90px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.sidebar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.sidebar-title  { font-size: 1.5rem; font-weight: 800; }
.profile-count  { font-size: 0.82rem; color: #6c757d; font-weight: 600; }

.filters-card   { padding: 20px; }

.filters-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
}
.filters-heading {
  font-size: 0.82rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: #6c757d;
  margin: 0;
}
.filter-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 20px; height: 20px;
  border-radius: 50%;
  background: #e91e8c;
  color: #fff;
  font-size: 0.72rem;
  font-weight: 700;
}

.filter-label {
  display: block;
  font-size: 0.82rem;
  font-weight: 600;
  color: #495057;
  margin-bottom: 5px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
.form-group { margin-bottom: 14px; }

.range-row    { display: flex; flex-direction: column; gap: 6px; }
.range-input  { width: 100%; accent-color: #e91e8c; }

.filter-actions { display: flex; gap: 10px; margin-top: 6px; }

/* Up-next */
.up-next        { padding: 16px; }
.up-next-label  {
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: #6c757d;
  margin-bottom: 10px;
}
.up-next-avatars { display: flex; align-items: center; }
.up-next-avatar {
  width: 38px; height: 38px;
  border-radius: 50%;
  border: 2px solid #fff;
  background: #fce4ec;
  display: flex; align-items: center; justify-content: center;
  color: #e91e8c; font-size: 0.85rem; font-weight: 700;
  overflow: hidden;
  margin-left: -8px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.1);
  flex-shrink: 0;
}
.up-next-avatar:first-child { margin-left: 0; }
.up-next-avatar img { width: 100%; height: 100%; object-fit: cover; }
.up-next-more { font-size: 0.78rem; color: #6c757d; margin-left: 10px; font-weight: 600; }

/* ── Mobile filter toggle ────────────────────────────────────────────── */
.mobile-filter-toggle {
  display: none;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}
.filter-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 12px;
  margin-bottom: 12px;
}

/* ── States ──────────────────────────────────────────────────────────── */
.state-center { text-align: center; padding: 80px 20px; }
.empty-icon   { font-size: 4rem; margin-bottom: 16px; }
.empty-title  { font-size: 1.5rem; font-weight: 700; margin-bottom: 10px; }

/* ── Profile grid ────────────────────────────────────────────────────── */
.profiles-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 22px;
}

.profile-wrap {
  position: relative;
  transition: transform 0.35s ease, opacity 0.35s ease;
}

.swiping-like    { transform: translateX(70px) rotate(8deg);  opacity: 0; }
.swiping-dislike { transform: translateX(-70px) rotate(-8deg); opacity: 0; }
.swiping-pass    { transform: translateY(-50px);               opacity: 0; }

.profile-link { display: block; text-decoration: none; color: inherit; }

.swipe-actions {
  display: flex;
  justify-content: center;
  gap: 16px;
  padding: 12px 16px;
  background: #fff;
  border: 1px solid #f0f0f0;
  border-top: none;
  border-radius: 0 0 16px 16px;
  margin-top: -8px;
}

.action-btn {
  background: none;
  border: 2px solid #dee2e6;
  width: 50px; height: 50px;
  border-radius: 50%;
  font-size: 1.3rem;
  cursor: pointer;
  transition: all 0.18s;
  display: flex; align-items: center; justify-content: center;
}
.action-btn:disabled                     { opacity: 0.4; cursor: not-allowed; }
.action-btn:not(:disabled):hover         { transform: scale(1.15); }
.action-btn.like:not(:disabled):hover    { border-color: #e91e8c; background: #fce4ec; }
.action-btn.dislike:not(:disabled):hover { border-color: #dc3545; background: #f8d7da; }
.action-btn.pass:not(:disabled):hover    { border-color: #6c757d; background: #f0f0f0; }

.load-more-wrap { text-align: center; margin-top: 32px; }

/* ── Match overlay ───────────────────────────────────────────────────── */
.match-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.78);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 20px;
}
.match-modal {
  position: relative;
  background: linear-gradient(160deg, #1a1a2e 0%, #16213e 100%);
  color: #fff;
  border-radius: 28px;
  padding: 52px 44px;
  text-align: center;
  max-width: 400px;
  width: 100%;
  box-shadow: 0 24px 64px rgba(0,0,0,0.5);
}
.match-close {
  position: absolute;
  top: 16px; right: 20px;
  background: rgba(255,255,255,0.12);
  border: none;
  color: rgba(255,255,255,0.7);
  width: 32px; height: 32px;
  border-radius: 50%;
  font-size: 0.9rem;
  cursor: pointer;
  transition: background 0.2s;
}
.match-close:hover { background: rgba(255,255,255,0.25); }
.match-hearts { font-size: 3.5rem; margin-bottom: 12px; }
.match-title  { font-size: 2.2rem; font-weight: 800; margin-bottom: 10px; }
.match-sub    { font-size: 1.05rem; opacity: 0.85; margin-bottom: 28px; }
.match-actions {
  display: flex; gap: 12px; justify-content: center; flex-wrap: wrap;
}
.match-keep {
  border-color: rgba(255,255,255,0.4);
  color: #fff;
}
.match-keep:hover { background: rgba(255,255,255,0.15); }

/* Transition */
.pop-enter-active { animation: popIn  0.4s cubic-bezier(0.34, 1.56, 0.64, 1); }
.pop-leave-active { animation: popOut 0.25s ease forwards; }
@keyframes popIn  { from { transform: scale(0.4); opacity: 0; } to { transform: scale(1); opacity: 1; } }
@keyframes popOut { from { transform: scale(1);   opacity: 1; } to { transform: scale(0.8); opacity: 0; } }

/* ── Responsive ──────────────────────────────────────────────────────── */
@media (max-width: 860px) {
  .discover-layout       { grid-template-columns: 1fr; }
  .discover-sidebar      { display: none; }
  .mobile-filter-toggle  { display: flex; }
}
@media (max-width: 500px) {
  .profiles-grid         { grid-template-columns: 1fr; }
  .match-modal           { padding: 40px 24px; }
}
</style>
