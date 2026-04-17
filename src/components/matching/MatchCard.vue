<template>
  <div class="match-card" :class="{ 'match-card--liked': decision === 'like', 'match-card--disliked': decision === 'dislike' }">
    <!-- Photo / avatar -->
    <div class="match-card__photo">
      <img v-if="candidate.user.profilePicture" :src="candidate.user.profilePicture" :alt="candidate.user.name" />
      <div v-else class="match-card__avatar">{{ initials }}</div>
      <div class="match-card__score-badge">{{ scorePercent }}% match</div>
    </div>

    <!-- Info -->
    <div class="match-card__info">
      <div class="match-card__name-row">
        <h4 class="match-card__name">{{ candidate.user.name }}, {{ candidate.user.age }}</h4>
        <span class="match-card__city">{{ candidate.user.location?.city || '—' }}</span>
      </div>

      <p v-if="candidate.user.occupation" class="match-card__occupation">
        {{ candidate.user.occupation }}
      </p>

      <p v-if="candidate.user.bio" class="match-card__bio">{{ candidate.user.bio }}</p>

      <!-- Why matched -->
      <div v-if="candidate.reasons?.length" class="match-card__reasons">
        <span v-for="r in candidate.reasons" :key="r" class="reason-pill">{{ r }}</span>
      </div>

      <!-- Shared interests -->
      <div class="match-card__interests">
        <span
          v-for="tag in candidate.sharedInterests"
          :key="tag"
          class="interest-tag"
        >{{ tag }}</span>
      </div>
    </div>

    <!-- Action buttons -->
    <div class="match-card__actions">
      <button class="action-btn action-btn--pass" @click="emit('action', candidate.user.id, 'pass')" title="Pass">
        <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M10 10l5-5M10 10l-5 5M10 10l-5-5M10 10l5 5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
      </button>
      <button class="action-btn action-btn--dislike" @click="emit('action', candidate.user.id, 'dislike')" title="Dislike">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M18 6L6 18M6 6l12 12" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"/></svg>
      </button>
      <button class="action-btn action-btn--like" @click="emit('action', candidate.user.id, 'like')" title="Like">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M12 21C12 21 3 14.5 3 8.5C3 5.42 5.42 3 8.5 3C10.24 3 11.81 3.89 12 5C12.19 3.89 13.76 3 15.5 3C18.58 3 21 5.42 21 8.5C21 14.5 12 21 12 21Z" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  candidate: { type: Object, required: true }, // { user, score, reasons, sharedInterests }
  decision: { type: String, default: null },   // 'like' | 'dislike' | 'pass' | null
})

const emit = defineEmits(['action'])

const initials = computed(() =>
  props.candidate.user.name?.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2) || '?'
)

// Normalise score to a 0–100 percentage (max possible score is 100)
const scorePercent = computed(() => Math.min(100, Math.round(props.candidate.score)))
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

/* Photo */
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
.match-card__score-badge {
  position: absolute;
  top: 12px;
  right: 12px;
  background: rgba(255,255,255,0.92);
  backdrop-filter: blur(4px);
  border-radius: 20px;
  padding: 4px 12px;
  font-size: 12px;
  font-weight: 600;
  color: #4361ee;
}

/* Info */
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

.match-card__reasons { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 8px; }
.reason-pill {
  font-size: 11px;
  padding: 3px 10px;
  border-radius: 12px;
  background: #f0fdf4;
  color: #15803d;
  border: 1px solid #bbf7d0;
}
.match-card__interests { display: flex; flex-wrap: wrap; gap: 5px; }
.interest-tag {
  font-size: 11px;
  padding: 3px 10px;
  border-radius: 12px;
  background: #eef2ff;
  color: #4361ee;
}

/* Actions */
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