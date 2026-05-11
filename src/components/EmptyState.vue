<template>
  <div class="empty-state">
    <div class="empty-icon">{{ icon }}</div>
    <h2>{{ title }}</h2>
    <p class="text-muted" v-if="description">{{ description }}</p>
    <slot />
  </div>
</template>

<script setup>
defineProps({
  icon:        { type: String, default: '🌟' },
  title:       { type: String, required: true },
  description: { type: String, default: '' },
})
</script>

<style scoped>
.empty-state {
  text-align: center;
  padding: 80px 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}
.empty-icon { font-size: 4rem; line-height: 1; }
h2 { font-size: 1.5rem; font-weight: 800; color: #212529; }
.text-muted { max-width: 360px; line-height: 1.5; }
</style>
