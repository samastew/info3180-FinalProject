<template>
  <div class="profile-card" :class="{ 'card-lg': large }">
    <!-- Photo -->
    <div class="card-photo" @click.stop>
      <img
        :src="currentPhoto || fallback"
        :alt="displayName"
        @error="e => e.target.src = fallback"
      />
      <!-- Photo dots if multiple -->
      <div v-if="photos.length > 1" class="photo-dots">
        <span
          v-for="(_, i) in photos" :key="i"
          class="dot" :class="{ active: photoIdx === i }"
          @click.stop="photoIdx = i"
        ></span>
      </div>
      <!-- Distance badge -->
      <div v-if="profile.distance_km != null" class="distance-badge">
        📍 {{ profile.distance_km }} km
      </div>
      <!-- Shared interests badge -->
      <div v-if="profile.shared_interests > 0" class="shared-badge">
        ✨ {{ profile.shared_interests }} shared
      </div>
    </div>

    <!-- Body -->
    <div class="card-body">
      <div class="card-name">
        {{ displayName }}
        <span v-if="age" class="age-pill">{{ age }}</span>
      </div>

      <div v-if="profile.city" class="card-location">
        📍 {{ profile.city }}{{ profile.country ? ', ' + profile.country : '' }}
      </div>

      <div v-if="profile.occupation" class="card-occupation text-muted">
        💼 {{ profile.occupation }}
      </div>

      <p v-if="profile.bio" class="card-bio">{{ truncate(profile.bio, 90) }}</p>

      <!-- Interest tags -->
      <div v-if="interests.length" class="card-tags">
        <span
          v-for="interest in interests.slice(0, 4)"
          :key="interest.interest_id || interest"
          class="tag"
        >{{ interest.name || interest }}</span>
        <span v-if="interests.length > 4" class="tag tag-more">+{{ interests.length - 4 }}</span>
      </div>

      <!-- Action buttons (discover mode) -->
      <div v-if="showActions" class="card-actions" @click.stop>
        <button class="action-btn pass"    @click="$emit('pass',    userId)" title="Pass">🤷</button>
        <button class="action-btn dislike" @click="$emit('dislike', userId)" title="Dislike">❌</button>
        <button class="action-btn like"    @click="$emit('like',    userId)" title="Like ❤️">❤️</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  profile:     { type: Object, required: true },
  showActions: { type: Boolean, default: false },
  large:       { type: Boolean, default: false },
})
defineEmits(['like', 'dislike', 'pass'])

const photoIdx = ref(0)

const photos = computed(() => {
  const p = props.profile
  return p.photos || p.user?.photos || []
})

const currentPhoto = computed(() => photos.value[photoIdx.value]?.photo_url || null)

const fallback = computed(() =>
  `https://ui-avatars.com/api/?name=${encodeURIComponent(displayName.value)}&background=e91e8c&color=fff&size=300&bold=true`
)

const userId = computed(() => props.profile.user_id)

const displayName = computed(() => {
  const p = props.profile
  if (p.first_name) return `${p.first_name} ${p.last_name}`
  return p.user?.username || 'User'
})

const age = computed(() => props.profile.age || props.profile.profile?.age || null)

const interests = computed(() => {
  const p = props.profile
  return p.interests || p.user?.interests || []
})

function truncate(s, len) {
  if (!s) return ''
  return s.length > len ? s.slice(0, len) + '…' : s
}
</script>

<style scoped>
.profile-card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.09);
  overflow: hidden;
  transition: transform 0.2s, box-shadow 0.2s;
  height: 100%;
  display: flex;
  flex-direction: column;
}
.profile-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 28px rgba(0,0,0,0.14);
}

/* Photo */
.card-photo {
  position: relative;
  height: 230px;
  overflow: hidden;
  flex-shrink: 0;
}
.card-lg .card-photo { height: 300px; }

.card-photo img {
  width: 100%; height: 100%;
  object-fit: cover;
  transition: transform 0.3s;
}
.profile-card:hover .card-photo img { transform: scale(1.03); }

.photo-dots {
  position: absolute; bottom: 8px; left: 50%; transform: translateX(-50%);
  display: flex; gap: 5px;
}
.dot {
  width: 7px; height: 7px; border-radius: 50%;
  background: rgba(255,255,255,0.6); cursor: pointer;
  transition: background 0.2s;
}
.dot.active { background: #fff; }

.distance-badge {
  position: absolute; top: 10px; left: 10px;
  background: rgba(0,0,0,0.55); color: #fff;
  padding: 3px 10px; border-radius: 20px; font-size: 0.75rem; font-weight: 600;
}
.shared-badge {
  position: absolute; top: 10px; right: 10px;
  background: rgba(233,30,140,0.85); color: #fff;
  padding: 3px 10px; border-radius: 20px; font-size: 0.75rem; font-weight: 700;
}

/* Body */
.card-body { padding: 16px; display: flex; flex-direction: column; gap: 4px; flex: 1; }

.card-name {
  font-size: 1.1rem; font-weight: 800;
  display: flex; align-items: center; gap: 8px;
}
.age-pill {
  background: #fce4ec; color: #c2157a;
  padding: 1px 8px; border-radius: 20px;
  font-size: 0.8rem; font-weight: 600;
}
.card-location  { font-size: 0.83rem; color: #6c757d; }
.card-occupation { font-size: 0.82rem; }
.card-bio       { font-size: 0.87rem; color: #495057; line-height: 1.45; margin-top: 2px; }

.card-tags { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 6px; }
.tag {
  background: #f0f0f0; color: #495057;
  padding: 2px 9px; border-radius: 20px; font-size: 0.75rem; font-weight: 500;
}
.tag-more { background: #fce4ec; color: #c2157a; }

/* Swipe actions */
.card-actions {
  display: flex; justify-content: center; gap: 16px;
  margin-top: auto; padding-top: 12px;
  border-top: 1px solid #f0f0f0;
}
.action-btn {
  background: none; border: 2px solid #dee2e6;
  width: 50px; height: 50px; border-radius: 50%;
  font-size: 1.3rem; cursor: pointer; transition: all 0.18s;
  display: flex; align-items: center; justify-content: center;
}
.action-btn:hover             { transform: scale(1.18); }
.action-btn.like:hover        { border-color: #e91e8c; background: #fce4ec; }
.action-btn.dislike:hover     { border-color: #dc3545; background: #f8d7da; }
.action-btn.pass:hover        { border-color: #6c757d; background: #f0f0f0; }
</style>
