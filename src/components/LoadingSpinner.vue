<template>
  <div class="spinner-wrap">
    <div class="spinner" :style="{ width: size, height: size, borderWidth: `${parseInt(size)/10}px` }"></div>
    <p v-if="label" class="text-muted" style="margin-top:12px;">{{ label }}</p>
  </div>
</template>

<script setup>
defineProps({
  size:  { type: String, default: '40px' },
  label: { type: String, default: '' },
})
</script>

<style scoped>
.spinner-wrap { display: flex; flex-direction: column; align-items: center; padding: 60px 20px; }
.spinner {
  border-radius: 50%;
  border-style: solid;
  border-color: rgba(233,30,140,0.2);
  border-top-color: #e91e8c;
  animation: spin 0.8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
</style>
