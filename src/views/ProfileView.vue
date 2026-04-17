<template>
  <div class="container py-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <h2 class="mb-0">My profile</h2>
      <button v-if="!editing" class="btn btn-outline-primary btn-sm" @click="editing = true">
        Edit profile
      </button>
      <button v-else class="btn btn-outline-secondary btn-sm" @click="editing = false">
        Cancel
      </button>
    </div>

    <!-- View mode -->
    <div v-if="!editing && user" class="profile-view">
      <div class="profile-view__header">
        <div class="profile-view__photo">
          <img v-if="user.profilePicture" :src="user.profilePicture" alt="You" />
          <div v-else class="profile-view__avatar">{{ initials }}</div>
        </div>
        <div>
          <h3 class="mb-0">{{ user.name }}, {{ user.age }}</h3>
          <p class="text-muted mb-1">{{ user.location?.city || 'No location set' }}</p>
          <span class="badge" :class="user.isPublic ? 'bg-success' : 'bg-secondary'">
            {{ user.isPublic ? 'Public' : 'Private' }}
          </span>
        </div>
      </div>

      <div v-if="user.bio" class="profile-section">
        <h6 class="section-label">About</h6>
        <p>{{ user.bio }}</p>
      </div>

      <div class="profile-section row g-3">
        <div v-if="user.occupation" class="col-md-6">
          <h6 class="section-label">Occupation</h6>
          <p>{{ user.occupation }}</p>
        </div>
        <div v-if="user.lookingFor" class="col-md-6">
          <h6 class="section-label">Looking for</h6>
          <p>{{ user.lookingFor }}</p>
        </div>
      </div>

      <div v-if="user.interests?.length" class="profile-section">
        <h6 class="section-label">Interests</h6>
        <div class="interest-grid">
          <span v-for="tag in user.interests" :key="tag" class="interest-pill">{{ tag }}</span>
        </div>
      </div>

      <div v-if="!user.profileComplete" class="alert alert-warning mt-3">
        Your profile is incomplete — <RouterLink to="/profile/edit">finish setting it up</RouterLink> to start matching.
      </div>
    </div>

    <!-- Edit mode -->
    <ProfileEditor v-if="editing" @saved="editing = false" />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import ProfileEditor from '@/components/profile/ProfileEditor.vue'

const authStore = useAuthStore()
const editing = ref(false)
const user = computed(() => authStore.currentUser)

const initials = computed(() =>
  (user.value?.name || '').split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2)
)
</script>

<style scoped>
.profile-view__header { display: flex; align-items: center; gap: 1.5rem; margin-bottom: 1.5rem; flex-wrap: wrap; }
.profile-view__photo { width: 90px; height: 90px; border-radius: 50%; overflow: hidden; flex-shrink: 0; }
.profile-view__photo img { width: 100%; height: 100%; object-fit: cover; }
.profile-view__avatar {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #4361ee, #7b5ea7);
  display: flex; align-items: center; justify-content: center;
  color: #fff; font-size: 1.6rem; font-weight: 700;
}
.profile-section { margin-bottom: 1.5rem; }
.section-label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.06em; color: #9ca3af; margin-bottom: 6px; }
.interest-grid { display: flex; flex-wrap: wrap; gap: 6px; }
.interest-pill {
  padding: 4px 14px; border-radius: 20px; background: #eef2ff; color: #4361ee; font-size: 13px; font-weight: 500;
}
</style>