<template>
  <div class="home-view">
    <template v-if="!authStore.isLoggedIn">
      <section class="hero container">
        <div class="hero-inner">
          <!-- Left: text -->
          <div class="hero-content">
            <h1 class="hero-title">Find your drift</h1>
            <p class="hero-lead">
              DriftDater matches you with people who share your passions,
              location, and vibe — not just a photo.
            </p>
            <div class="hero-actions">
              <RouterLink to="/register" class="btn btn-primary btn-lg px-5">
                Get started
              </RouterLink>
              <RouterLink to="/login" class="btn btn-outline-secondary btn-lg px-4">
                Sign in
              </RouterLink>
            </div>
          </div>

          <!-- Right: stacked card visual -->
          <div class="hero-visual">
            <div class="hero-card hero-card--back" />
            <div class="hero-card hero-card--mid" />
            <div class="hero-card hero-card--front">
              <div class="hero-avatar">DD</div>
              <p class="hero-card-name">Your next match</p>
              <p class="hero-card-sub">97% compatible</p>
            </div>
          </div>
        </div>
      </section>
    </template>
  </div>
</template>

<script setup>
import { watchEffect } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const router = useRouter()

watchEffect(() => {
  if (authStore.isLoggedIn) router.replace('/discover')
})
</script>

<style scoped>
.home-view {
  min-height: calc(100vh - 140px);
  display: flex;
  align-items: center;
  justify-content: center;
}

.hero {
  width: 100%;
  padding: 3rem 1rem;
}

/* Centered two-column layout */
.hero-inner {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4rem;
  flex-wrap: wrap;
  max-width: 860px;
  margin: 0 auto;
}

.hero-content {
  flex: 1;
  min-width: 260px;
  max-width: 420px;
}

.hero-title {
  font-size: clamp(2rem, 5vw, 3.2rem);
  font-weight: 700;
  color: #1a1a2e;
  line-height: 1.15;
  margin-bottom: 1rem;
}

.hero-lead {
  font-size: 1.05rem;
  color: #6b7280;
  line-height: 1.6;
  margin-bottom: 2rem;
}

.hero-actions {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

/* Stacked card visual */
.hero-visual {
  flex-shrink: 0;
  position: relative;
  width: 220px;
  height: 280px;
}

.hero-card {
  position: absolute;
  width: 200px;
  height: 260px;
  border-radius: 20px;
  background: #fff;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.07);
}

.hero-card--back {
  top: 20px;
  left: 20px;
  background: #eef2ff;
  transform: rotate(-6deg);
}

.hero-card--mid {
  top: 10px;
  left: 10px;
  background: #f5f3ff;
  transform: rotate(-2deg);
}

.hero-card--front {
  top: 0;
  left: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
}

.hero-avatar {
  width: 72px;
  height: 72px;
  border-radius: 50%;
  background: linear-gradient(135deg, #4361ee, #7b5ea7);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 1.4rem;
  font-weight: 700;
}

.hero-card-name {
  font-weight: 600;
  color: #1a1a2e;
  font-size: 1rem;
  margin: 0;
}

.hero-card-sub {
  font-size: 12px;
  color: #4361ee;
  font-weight: 600;
  margin: 0;
}
</style>