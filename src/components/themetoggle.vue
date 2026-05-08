<!-- src/components/ThemeToggle.vue -->
<template>
  <button @click="themeStore.toggleTheme()" class="theme-toggle">
    {{ themeStore.isDark ? '☀️ Light' : '🌙 Dark' }}
  </button>
</template>

<script setup>
import { useThemeStore } from '@/stores/theme'
const themeStore = useThemeStore()
</script>