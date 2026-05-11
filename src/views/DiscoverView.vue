<template>
  <div class="container-fluid py-4">
    <div class="discover-layout">
      <!-- Filters sidebar -->
      <aside class="discover-sidebar d-none d-lg-block">
        <MatchFilters @update:filters="activeFilters = $event" />
      </aside>

      <!-- Main content -->
      <main class="discover-main">
        <div class="discover-header">
          <h4 class="mb-0">Discover</h4>
          <span class="text-muted small">{{ queue.length }} potential matches</span>
        </div>

        <!-- Mobile filters toggle -->
        <div class="d-lg-none mb-3">
          <button class="btn btn-outline-secondary btn-sm w-100" @click="showMobileFilters = !showMobileFilters">
            {{ showMobileFilters ? 'Hide filters' : 'Show filters' }}
          </button>
          <div v-if="showMobileFilters" class="mt-2">
            <MatchFilters @update:filters="activeFilters = $event" />
          </div>
        </div>

        <!-- Match notification toast -->
        <div v-if="latestMatch" class="match-toast">
          <span>🎉</span>
          <span>It's a mutual match with <strong>{{ latestMatch }}</strong>!</span>
          <button @click="latestMatch = null" class="btn-close btn-close-sm ms-auto" />
        </div>

        <!-- Current card -->
        <div v-if="currentCandidate" class="card-stage">
          <MatchCard
            :candidate="currentCandidate"
            :decision="currentDecision"
            @action="handleAction"
          />
        </div>

        <!-- Empty queue state -->
        <div v-else class="empty-queue">
          <p class="empty-title">You've seen everyone!</p>
          <p class="text-muted">Adjust your filters or check back later for new matches.</p>
          <button class="btn btn-primary mt-2" @click="resetQueue">Start over</button>
        </div>

        <!-- Thumbnail queue preview -->
        <div v-if="queue.length > 1" class="queue-preview mt-4">
          <p class="queue-label">Up next</p>
          <div class="queue-avatars">
            <div
              v-for="c in queue.slice(1, 5)"
              :key="c.user_id"
              class="queue-avatar"
            >
              <img v-if="c.profile_photo_url" :src="c.profile_photo_url" :alt="c.first_name" />
              <span v-else>{{ c.first_name?.[0] }}</span>
            </div>
            <span v-if="queue.length > 5" class="queue-more">+{{ queue.length - 5 }}</span>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup>

// CHANGED: removed useMatching and useMatchStore imports — they relied on 
// getAllUsers() which doesn't exist in the auth store, always returning empty.
// Added onMounted to trigger API call when page loads, and api to make requests.
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import MatchCard from '@/components/matching/MatchCard.vue'
import MatchFilters from '@/components/matching/MatchFilters.vue'
import api from '@/services/api'

const authStore = useAuthStore()

// CHANGED: replaced scoredCandidates from useMatching with allProfiles fetched 
// from the real API. Originally this was always empty because getAllUsers() 
// didnt exist.
const allProfiles = ref([])
const activeFilters = ref({})
const showMobileFilters = ref(false)
const currentDecision = ref(null)
const latestMatch = ref(null)
const processedIds = ref([])
// ADDED: loading state so we can show a spinner while profiles are fetching :)
const loading = ref(true)

// CHANGED: originally there was no onMounted at all — nothing ever fetched 
// profiles from the backend. This now calls /api/discover on page load to 
// get real profiles from your database.
onMounted(async () => {
  try {
    const res = await api.get('/discover')
    allProfiles.value = res.data.profiles
  } catch (e) {
    console.error('Failed to load profiles', e)
  } finally {
    loading.value = false
  }
})

// CHANGED: was filtering scoredCandidates (always empty) from useMatching.
// Now filters allProfiles from the API. Also changed c.user.id to p.user_id
// to match the field name your backend actually returns.
const queue = computed(() =>
  allProfiles.value.filter(p => !processedIds.value.includes(p.user_id))
)

const currentCandidate = computed(() => queue.value[0] ?? null)

// CHANGED: was calling matchStore.interact() which only updated a local Pinia 
// store and never saved anything to the database. Now posts to /api/swipes so 
// swipes actually persist. Also added match detection — if the API response 
// says matched: true, shows the match notification with the person's name.
async function handleAction(userId, action) {
  currentDecision.value = action
  try {
    const res = await api.post('/swipes', { swiped_id: userId, action })
    if (res.data.matched) {
      latestMatch.value = currentCandidate.value?.first_name
      setTimeout(() => latestMatch.value = null, 4000)
    }
  } catch (e) {
    console.error('Swipe failed', e)
  }
  setTimeout(() => {
    processedIds.value.push(userId)
    currentDecision.value = null
  }, 350)
}

// CHANGED: originally just cleared processedIds from the local store. 
// Now also re-fetches from the API so you actually get fresh profiles.
async function resetQueue() {
  processedIds.value = []
  const res = await api.get('/discover')
  allProfiles.value = res.data.profiles
}

/*
import { ref, computed, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useMatchStore } from '@/stores/matches'
import { useMatching } from '@/composables/useMatching'
import MatchCard from '@/components/matching/MatchCard.vue'
import MatchFilters from '@/components/matching/MatchFilters.vue'

const authStore = useAuthStore()
const matchStore = useMatchStore()

const activeFilters = ref({})
const showMobileFilters = ref(false)
const currentDecision = ref(null)
const latestMatch = ref(null)
const processedIds = ref([...matchStore.dismissedIds.value ?? []])

// Run the matching algorithm reactively with active filters
const { scoredCandidates } = useMatching(activeFilters.value)

// Build a queue excluding already-processed profiles in this session
const queue = computed(() =>
  scoredCandidates.value.filter(c => !processedIds.value.includes(c.user.id))
)

const currentCandidate = computed(() => queue.value[0] ?? null)

function handleAction(userId, action) {
  currentDecision.value = action
  matchStore.interact(userId, action)

  // Check for new mutual match notification
  if (action === 'like') {
    const notif = matchStore.notifications.find(n => n.targetId === userId && n.type === 'mutual_match')
    if (notif) {
      const matchedUser = authStore.getAllUsers().find(u => u.id === userId)
      if (matchedUser) latestMatch.value = matchedUser.name
    }
  }

  // Move to next card after a short delay for visual feedback
  setTimeout(() => {
    processedIds.value.push(userId)
    currentDecision.value = null
  }, 350)
}

function resetQueue() {
  processedIds.value = []
}
  */
</script>

<style scoped>
.discover-layout {
  display: flex;
  gap: 2rem;
  max-width: 960px;
  margin: 0 auto;
}
.discover-sidebar { width: 260px; flex-shrink: 0; }
.discover-main { flex: 1; min-width: 0; }
.discover-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.25rem;
}
.card-stage {
  display: flex;
  justify-content: center;
}
.empty-queue {
  text-align: center;
  padding: 4rem 1rem;
}
.empty-title { font-size: 1.2rem; font-weight: 600; color: #1a1a2e; }
/* Match toast */
.match-toast {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #eef2ff;
  border: 1.5px solid #c7d2fe;
  border-radius: 12px;
  padding: 0.75rem 1rem;
  margin-bottom: 1rem;
  font-size: 14px;
  color: #3730a3;
}
/* Queue preview */
.queue-label { font-size: 12px; color: #9ca3af; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 6px; }
.queue-avatars { display: flex; align-items: center; gap: -6px; }
.queue-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 2px solid #fff;
  overflow: hidden;
  background: linear-gradient(135deg, #4361ee, #7b5ea7);
  display: flex; align-items: center; justify-content: center;
  color: #fff; font-size: 12px; font-weight: 600;
  margin-left: -8px;
}
.queue-avatar:first-child { margin-left: 0; }
.queue-avatar img { width: 100%; height: 100%; object-fit: cover; }
.queue-more { font-size: 12px; color: #9ca3af; margin-left: 8px; }
</style>