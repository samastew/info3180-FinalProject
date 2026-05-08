<template>
  <div class="profile-card">
    <div class="profile-card__photo">
      <img v-if="user.profilePicture" :src="user.profilePicture" :alt="user.name" />
      <div v-else class="profile-card__avatar">{{ initials }}</div>
    </div>
    <div class="profile-card__body">
      <div class="profile-card__header">
        <h5 class="profile-card__name">{{ user.name }}, {{ user.age }}</h5>
        <span v-if="matchInfo" class="profile-card__score">{{ matchInfo.score }}% match</span>
      </div>
      <p class="profile-card__location">{{ user.location?.city || 'Location unknown' }}</p>
      <p v-if="user.bio" class="profile-card__bio">{{ truncatedBio }}</p>
      <div v-if="matchInfo?.sharedInterests?.length" class="profile-card__shared">
        <span
          v-for="interest in matchInfo.sharedInterests.slice(0, 3)"
          :key="interest"
          class="interest-pill"
        >{{ interest }}</span>
        <span v-if="matchInfo.sharedInterests.length > 3" class="interest-pill interest-pill--more">
          +{{ matchInfo.sharedInterests.length - 3 }}
        </span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  user: { type: Object, required: true },
  matchInfo: { type: Object, default: null }, // { score, sharedInterests, reasons }
})

const initials = computed(() =>
  props.user.name?.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2) || '?'
)

const truncatedBio = computed(() => {
  const bio = props.user.bio || ''
  return bio.length > 100 ? bio.slice(0, 100) + '…' : bio
})
</script>

<style scoped>
.profile-card {
  display: flex;
  gap: 1rem;
  align-items: flex-start;
  padding: 1rem;
  border-radius: 12px;
  background: #fff;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
}
.profile-card__photo {
  flex-shrink: 0;
  width: 64px;
  height: 64px;
  border-radius: 50%;
  overflow: hidden;
}
.profile-card__photo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.profile-card__avatar {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #4361ee, #7b5ea7);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-weight: 600;
  font-size: 1.1rem;
}
.profile-card__body { flex: 1; min-width: 0; }
.profile-card__header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}
.profile-card__name {
  font-size: 1rem;
  font-weight: 600;
  color: #1a1a2e;
  margin: 0;
}
.profile-card__score {
  font-size: 12px;
  font-weight: 600;
  color: #4361ee;
}
.profile-card__location {
  font-size: 12px;
  color: #9ca3af;
  margin: 2px 0 4px;
}
.profile-card__bio {
  font-size: 13px;
  color: #6b7280;
  margin: 0 0 8px;
}
.profile-card__shared { display: flex; flex-wrap: wrap; gap: 4px; }
.interest-pill {
  font-size: 11px;
  padding: 2px 10px;
  border-radius: 12px;
  background: #eef2ff;
  color: #4361ee;
  font-weight: 500;
}
.interest-pill--more { background: #f3f4f6; color: #6b7280; }
</style>