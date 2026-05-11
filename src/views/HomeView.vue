<template>
  <div class="home">
    <!-- Hero -->
    <section class="hero">
      <div class="hero-content">
        <h1>Find Your <span class="gradient-text">Perfect Match</span></h1>
        <p>DriftDater connects you with compatible singles based on shared interests, location, and lifestyle preferences.</p>
        <div class="hero-cta" v-if="!auth.isLoggedIn">
          <RouterLink to="/register" class="btn btn-primary btn-lg">Get Started Free</RouterLink>
          <RouterLink to="/login"    class="btn btn-outline btn-lg">Sign In</RouterLink>
        </div>
        <div class="hero-cta" v-else>
          <RouterLink to="/discover" class="btn btn-primary btn-lg">Start Discovering 💕</RouterLink>
        </div>
      </div>
      <div class="hero-visual">
        <div class="floating-card card-1">💕 Matched!</div>
        <div class="floating-card card-2">❤️ 1,200+ matches today</div>
        <div class="floating-card card-3">🌟 95% satisfaction</div>
      </div>
    </section>

    <!-- Stats -->
    <section class="stats-section">
      <div class="container">
        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-number">10K+</div>
            <div class="stat-label">Active Users</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">5K+</div>
            <div class="stat-label">Matches Made</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">50+</div>
            <div class="stat-label">Cities Covered</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">95%</div>
            <div class="stat-label">Satisfaction Rate</div>
          </div>
        </div>
      </div>
    </section>

    <!-- Features -->
    <section class="features-section">
      <div class="container">
        <h2>Why DriftDater?</h2>
        <div class="features-grid">
          <div class="feature-card">
            <div class="feature-icon">🎯</div>
            <h3>Smart Matching</h3>
            <p>Our algorithm finds compatible matches based on your interests, location, and relationship goals.</p>
          </div>
          <div class="feature-card">
            <div class="feature-icon">💬</div>
            <h3>Secure Messaging</h3>
            <p>Chat only with people you match with. Your privacy is our priority.</p>
          </div>
          <div class="feature-card">
            <div class="feature-icon">📍</div>
            <h3>Location-Based</h3>
            <p>Find singles near you across Jamaica and beyond.</p>
          </div>
          <div class="feature-card">
            <div class="feature-icon">⭐</div>
            <h3>Save Favorites</h3>
            <p>Bookmark profiles you're interested in and revisit them anytime.</p>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section class="cta-section" v-if="!auth.isLoggedIn">
      <div class="container">
        <div class="cta-box">
          <h2>Ready to find your match?</h2>
          <p>Join thousands of singles already on DriftDater.</p>
          <RouterLink to="/register" class="btn btn-primary btn-lg">Create Your Free Profile</RouterLink>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
const auth = useAuthStore()
</script>

<style scoped>
.home { overflow-x: hidden; }

.hero {
  min-height: calc(100vh - 70px);
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  position: relative;
  overflow: hidden;
}
.hero::before {
  content: '';
  position: absolute;
  inset: 0;
  background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23e91e8c' fill-opacity='0.05'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
}

.hero-content {
  max-width: 600px;
  z-index: 1;
  text-align: center;
}
.hero-content h1 {
  font-size: clamp(2rem, 5vw, 3.5rem);
  font-weight: 900;
  color: #fff;
  line-height: 1.2;
  margin-bottom: 20px;
}
.gradient-text {
  background: linear-gradient(135deg, #e91e8c, #ff6b35);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
.hero-content p {
  font-size: 1.1rem;
  color: rgba(255,255,255,0.8);
  margin-bottom: 36px;
  line-height: 1.6;
}
.hero-cta { display: flex; gap: 16px; justify-content: center; flex-wrap: wrap; }

.hero-visual {
  position: absolute;
  right: 5%;
  top: 20%;
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.floating-card {
  background: rgba(255,255,255,0.1);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255,255,255,0.2);
  color: #fff;
  padding: 12px 20px;
  border-radius: 12px;
  font-weight: 600;
  animation: float 3s ease-in-out infinite;
}
.floating-card.card-2 { animation-delay: 1s; }
.floating-card.card-3 { animation-delay: 2s; }
@keyframes float {
  0%,100% { transform: translateY(0); }
  50%      { transform: translateY(-10px); }
}

@media (max-width: 768px) { .hero-visual { display: none; } }

.stats-section { padding: 60px 20px; background: #fff; }
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 24px;
}
.stat-card { text-align: center; }
.stat-number { font-size: 2.5rem; font-weight: 900; color: #e91e8c; }
.stat-label { color: #6c757d; font-weight: 600; }

.features-section { padding: 80px 20px; background: #f8f9fa; }
.features-section h2 { text-align: center; font-size: 2rem; font-weight: 800; margin-bottom: 48px; }
.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 24px;
}
.feature-card {
  background: #fff;
  border-radius: 16px;
  padding: 32px 24px;
  text-align: center;
  box-shadow: 0 4px 16px rgba(0,0,0,0.06);
  transition: transform 0.2s;
}
.feature-card:hover { transform: translateY(-6px); }
.feature-icon { font-size: 2.5rem; margin-bottom: 16px; }
.feature-card h3 { font-size: 1.1rem; font-weight: 700; margin-bottom: 10px; }
.feature-card p { color: #6c757d; line-height: 1.5; font-size: 0.92rem; }

.cta-section { padding: 80px 20px; }
.cta-box {
  background: linear-gradient(135deg, #e91e8c, #ff6b35);
  border-radius: 24px;
  padding: 60px 40px;
  text-align: center;
  color: #fff;
}
.cta-box h2 { font-size: 2rem; font-weight: 800; margin-bottom: 12px; }
.cta-box p { font-size: 1.1rem; opacity: 0.9; margin-bottom: 32px; }
.cta-box .btn-primary { background: #fff; color: #e91e8c; }
.cta-box .btn-primary:hover { background: #f0f0f0; }
</style>
