<template>
  <div class="container py-4">
    <h4 class="mb-1">Your matches</h4>
    <p class="text-muted small mb-4">
      {{ matchedUsers.length }} mutual {{ matchedUsers.length === 1 ? 'match' : 'matches' }}
    </p>

    <MatchList :matches="matchedUsers" @select="selectedMatch = $event" />

    <!-- Selected match detail panel -->
    <div v-if="selectedMatch" class="match-detail-overlay" @click.self="selectedMatch = null">
      <div class="match-detail-panel">
        <button class="match-detail-close" @click="selectedMatch = null">✕</button>
        <ProfileCard :user="selectedMatch" />
        <div class="match-detail-actions mt-3">
          <RouterLink
            to="/matches"
            class="btn btn-primary w-100"
          >
            Message (coming soon)
          </RouterLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useMatchStore } from '@/stores/matches'
import MatchList from '@/components/matching/MatchList.vue'
import ProfileCard from '@/components/profile/ProfileCard.vue'

const authStore = useAuthStore()
const matchStore = useMatchStore()
const selectedMatch = ref(null)

const matchedUsers = computed(() => {
  const all = authStore.getAllUsers()
  return matchStore.mutualMatchIds.value
    .map(id => all.find(u => u.id === id))
    .filter(Boolean)
})
</script>

<style scoped>
.match-detail-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 300;
  padding: 1rem;
}
.match-detail-panel {
  background: #fff;
  border-radius: 20px;
  padding: 1.5rem;
  max-width: 400px;
  width: 100%;
  position: relative;
  box-shadow: 0 20px 60px rgba(0,0,0,0.15);
}
.match-detail-close {
  position: absolute;
  top: 12px; right: 16px;
  background: none; border: none;
  font-size: 16px; color: #9ca3af; cursor: pointer;
}
</style>