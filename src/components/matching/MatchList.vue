<template>
  <div>
    <div v-if="matches.length === 0" class="empty-state">
      <div class="empty-icon">💬</div>
      <p class="empty-text">No mutual matches yet. Keep exploring!</p>
    </div>

    <div v-else class="match-list">
      <div
        v-for="match in matches"
        :key="match.id"
        class="match-list-item"
        @click="emit('select', match)"
      >
        <div class="match-list-item__photo">
          <img v-if="match.profilePicture" :src="match.profilePicture" :alt="match.name" />
          <div v-else class="match-list-item__avatar">{{ initials(match.name) }}</div>
          <span class="match-dot" />
        </div>
        <div class="match-list-item__info">
          <p class="match-list-item__name">{{ match.name }}, {{ match.age }}</p>
          <p class="match-list-item__city">{{ match.location?.city || '—' }}</p>
        </div>
        <div class="match-list-item__arrow">›</div>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  matches: { type: Array, default: () => [] },
})
const emit = defineEmits(['select'])

function initials(name) {
  return (name || '').split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2)
}
</script>

<style scoped>
.empty-state { text-align: center; padding: 3rem 1rem; }
.empty-icon { font-size: 3rem; margin-bottom: 1rem; }
.empty-text { color: #9ca3af; font-size: 14px; }
.match-list { display: flex; flex-direction: column; gap: 4px; }
.match-list-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  border-radius: 12px;
  background: #fff;
  cursor: pointer;
  transition: background 0.15s;
  box-shadow: 0 1px 4px rgba(0,0,0,0.05);
}
.match-list-item:hover { background: #f5f7ff; }
.match-list-item__photo { position: relative; flex-shrink: 0; width: 48px; height: 48px; border-radius: 50%; overflow: hidden; }
.match-list-item__photo img { width: 100%; height: 100%; object-fit: cover; }
.match-list-item__avatar {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #4361ee, #7b5ea7);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-weight: 600;
  font-size: 0.9rem;
}
.match-dot {
  position: absolute;
  bottom: 2px;
  right: 2px;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #22c55e;
  border: 2px solid #fff;
}
.match-list-item__info { flex: 1; }
.match-list-item__name { font-size: 14px; font-weight: 600; color: #1a1a2e; margin: 0; }
.match-list-item__city { font-size: 12px; color: #9ca3af; margin: 0; }
.match-list-item__arrow { color: #d1d5db; font-size: 1.2rem; }
</style>