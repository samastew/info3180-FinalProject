<!--MatchCard.vue was rewritten to use the actual API data shape.
  The original version expected a nested { user, score, reasons, sharedInterests } object
  from a local matching algorithm (useMatching) that was never connected to the backend.
  It is now updated to work with the flat profile object returned by GET /api/discover,
  using fields like first_name, last_name, user_id, date_of_birth, and interests directly.
-->

<template>
  <div class="match-card" :class="{ 'match-card--liked': decision === 'like', 'match-card--disliked': decision === 'dislike' }">
    <!-- Photo / avatar -->
    <div class="match-card__photo">
      <img v-if="candidate.profile_photo_url" :src="candidate.profile_photo_url" :alt="fullName" />
      <div v-else class="match-card__avatar">{{ initials }}</div>
    </div>

    <!-- Info -->
    <div class="match-card__info">
      <div class="match-card__name-row">
        <h4 class="match-card__name">{{ fullName }}, {{ age }}</h4>
        <span class="match-card__city">{{ candidate.city || '—' }}</span>
      </div>

      <p v-if="candidate.occupation" class="match-card__occupation">{{ candidate.occupation }}</p>

      <p v-if="candidate.bio" class="match-card__bio">{{ candidate.bio }}</p>

      <!-- Interests from API -->
      <div class="match-card__interests">
        <span
          v-for="interest in candidate.interests"
          :key="interest.interest_id"
          class="interest-tag"
        >{{ interest.name }}</span>
      </div>
    </div>

    <!-- Action buttons -->
    <div class="match-card__actions">
      <button class="action-btn action-btn--pass" @click="emit('action', candidate.user_id, 'pass')" title="Pass">
        <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M10 10l5-5M10 10l-5 5M10 10l-5-5M10 10l5 5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
      </button>
      <button class="action-btn action-btn--dislike" @click="emit('action', candidate.user_id, 'dislike')" title="Dislike">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M18 6L6 18M6 6l12 12" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"/></svg>
      </button>
      <button class="action-btn action-btn--like" @click="emit('action', candidate.user_id, 'like')" title="Like">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M12 21C12 21 3 14.5 3 8.5C3 5.42 5.42 3 8.5 3C10.24 3 11.81 3.89 12 5C12.19 3.89 13.76 3 15.5 3C18.58 3 21 5.42 21 8.5C21 14.5 12 21 12 21Z" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  candidate: { type: Object, required: true },
  decision: { type: String, default: null },
})

const emit = defineEmits(['action'])

const fullName = computed(() =>
  `${props.candidate.first_name} ${props.candidate.last_name}`
)

const age = computed(() => {
  if (!props.candidate.date_of_birth) return ''
  const today = new Date()
  const dob = new Date(props.candidate.date_of_birth)
  let a = today.getFullYear() - dob.getFullYear()
  if (today < new Date(today.getFullYear(), dob.getMonth(), dob.getDate())) a--
  return a
})

const initials = computed(() =>
  ((props.candidate.first_name?.[0] || '') + (props.candidate.last_name?.[0] || '')).toUpperCase() || '?'
)
</script>

<style scoped>
.match-card {
  background: #fff;
  border-radius: 20px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.08);
  overflow: hidden;
  transition: transform 0.2s, box-shadow 0.2s;
  max-width: 440px;
  width: 100%;
}
.match-card:hover { transform: translateY(-2px); box-shadow: 0 8px 28px rgba(0,0,0,0.1); }
.match-card--liked { box-shadow: 0 4px 20px rgba(67,97,238,0.25); }
.match-card--disliked { opacity: 0.5; }

.match-card__photo {
  position: relative;
  height: 280px;
  background: linear-gradient(135deg, #4361ee22, #7b5ea722);
  overflow: hidden;
}
.match-card__photo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.match-card__avatar {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 3rem;
  font-weight: 700;
  color: #4361ee;
  background: linear-gradient(135deg, #eef2ff, #ede9f9);
}

.match-card__info { padding: 1rem 1.25rem 0.5rem; }
.match-card__name-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 2px;
}
.match-card__name { font-size: 1.2rem; font-weight: 600; color: #1a1a2e; margin: 0; }
.match-card__city { font-size: 12px; color: #9ca3af; }
.match-card__occupation { font-size: 13px; color: #6b7280; margin: 0 0 6px; }
.match-card__bio { font-size: 14px; color: #4b5563; margin: 0 0 10px; line-height: 1.5; }

.match-card__interests { display: flex; flex-wrap: wrap; gap: 5px; }
.interest-tag {
  font-size: 11px;
  padding: 3px 10px;
  border-radius: 12px;
  background: #eef2ff;
  color: #4361ee;
}

.match-card__actions {
  display: flex;
  justify-content: center;
  gap: 1.5rem;
  padding: 1rem 1.25rem 1.25rem;
}
.action-btn {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: transform 0.15s, box-shadow 0.15s;
}
.action-btn:hover { transform: scale(1.1); }
.action-btn--pass {
  background: #f3f4f6;
  color: #9ca3af;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}
.action-btn--dislike {
  background: #fff;
  color: #ef4444;
  box-shadow: 0 2px 12px rgba(239,68,68,0.2);
  border: 2px solid #fee2e2;
}
.action-btn--like {
  background: #4361ee;
  color: #fff;
  box-shadow: 0 4px 16px rgba(67,97,238,0.35);
}
.action-btn--like:hover { box-shadow: 0 6px 20px rgba(67,97,238,0.5); }
</style>