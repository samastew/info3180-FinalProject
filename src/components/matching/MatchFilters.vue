<template>
  <div class="match-filters">
    <h6 class="filters-title">Filter matches</h6>

    <!-- Age range -->
    <div class="filter-group">
      <label class="filter-label">Age range</label>
      <div class="d-flex gap-2 align-items-center">
        <input v-model.number="local.minAge" type="number" class="form-control form-control-sm" min="18" max="99" style="width:70px" />
        <span class="text-muted">–</span>
        <input v-model.number="local.maxAge" type="number" class="form-control form-control-sm" min="18" max="99" style="width:70px" />
      </div>
    </div>

    <!-- Max distance -->
    <div class="filter-group">
      <label class="filter-label">Max distance: <strong>{{ local.maxDistanceKm }} km</strong></label>
      <input v-model.number="local.maxDistanceKm" type="range" class="form-range" min="5" max="500" step="5" />
    </div>

    <!-- Interests -->
    <div class="filter-group">
      <label class="filter-label">Must share interests</label>
      <div class="interest-grid">
        <button
          v-for="tag in INTEREST_OPTIONS.slice(0, 12)"
          :key="tag"
          type="button"
          class="filter-tag"
          :class="{ active: local.interests.includes(tag) }"
          @click="toggleInterest(tag)"
        >
          {{ tag }}
        </button>
      </div>
    </div>

    <!-- Looking for -->
    <div class="filter-group">
      <label class="filter-label">Looking for</label>
      <select v-model="local.lookingFor" class="form-select form-select-sm">
        <option value="">Any</option>
        <option v-for="opt in LOOKING_FOR_OPTIONS" :key="opt" :value="opt">{{ opt }}</option>
      </select>
    </div>

    <!-- Actions -->
    <div class="d-flex gap-2 mt-3">
      <button class="btn btn-primary btn-sm flex-fill" @click="applyFilters">Apply</button>
      <button class="btn btn-outline-secondary btn-sm" @click="resetFilters">Reset</button>
    </div>
  </div>
</template>

<script setup>
import { reactive } from 'vue'
import { INTEREST_OPTIONS, LOOKING_FOR_OPTIONS } from '@/data/mockData'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const me = authStore.currentUser

const emit = defineEmits(['update:filters'])

// Default filter values from user preferences
const defaults = () => ({
  minAge: me?.agePreference?.min || 18,
  maxAge: me?.agePreference?.max || 60,
  maxDistanceKm: me?.maxDistanceKm || 50,
  interests: [],
  lookingFor: '',
})

const local = reactive(defaults())

function toggleInterest(tag) {
  const idx = local.interests.indexOf(tag)
  if (idx === -1) local.interests.push(tag)
  else local.interests.splice(idx, 1)
}

function applyFilters() {
  emit('update:filters', { ...local })
}

function resetFilters() {
  Object.assign(local, defaults())
  emit('update:filters', { ...local })
}
</script>

<style scoped>
.match-filters {
  background: #fff;
  border-radius: 16px;
  padding: 1.25rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
}
.filters-title {
  font-size: 0.9rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #9ca3af;
  margin-bottom: 1rem;
}
.filter-group { margin-bottom: 1.1rem; }
.filter-label { font-size: 13px; font-weight: 500; color: #374151; margin-bottom: 6px; display: block; }
.interest-grid { display: flex; flex-wrap: wrap; gap: 5px; }
.filter-tag {
  font-size: 11px;
  padding: 3px 11px;
  border-radius: 16px;
  border: 1.5px solid #e5e7eb;
  background: #f9fafb;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.12s;
}
.filter-tag:hover { border-color: #4361ee; color: #4361ee; }
.filter-tag.active { background: #4361ee; border-color: #4361ee; color: #fff; }
</style>