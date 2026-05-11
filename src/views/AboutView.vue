<template>
  <div class="container" style="padding-top:48px; padding-bottom:80px;">
    <div class="about-hero text-center mb-3">
      <div style="font-size:4rem;">💕</div>
      <h1 style="font-size:2.4rem; font-weight:900;">About DriftDater</h1>
      <p class="text-muted" style="max-width:560px; margin:12px auto 0; font-size:1.05rem; line-height:1.6;">
        DriftDater was built as an INFO3180 group project at the University of the West Indies.
        It's a modern, full-stack dating platform connecting people across Jamaica.
      </p>
    </div>

    <!-- Tech Stack -->
    <div class="section card mb-3">
      <h2>🛠️ Technology Stack</h2>
      <div class="tech-grid">
        <div class="tech-item">
          <div class="tech-icon">⚡</div>
          <div><strong>Vue 3</strong><br><small class="text-muted">Composition API + Pinia</small></div>
        </div>
        <div class="tech-item">
          <div class="tech-icon">🐍</div>
          <div><strong>Flask</strong><br><small class="text-muted">Python REST API</small></div>
        </div>
        <div class="tech-item">
          <div class="tech-icon">🐘</div>
          <div><strong>PostgreSQL</strong><br><small class="text-muted">Relational database</small></div>
        </div>
        <div class="tech-item">
          <div class="tech-icon">🔒</div>
          <div><strong>Flask-Login</strong><br><small class="text-muted">Session-based auth</small></div>
        </div>
        <div class="tech-item">
          <div class="tech-icon">📦</div>
          <div><strong>SQLAlchemy</strong><br><small class="text-muted">ORM + migrations</small></div>
        </div>
        <div class="tech-item">
          <div class="tech-icon">🚀</div>
          <div><strong>Vite</strong><br><small class="text-muted">Lightning-fast bundler</small></div>
        </div>
      </div>
    </div>

    <!-- Features -->
    <div class="section card mb-3">
      <h2>✨ Features</h2>
      <div class="feature-list">
        <div v-for="f in features" :key="f.title" class="feature-row">
          <span class="feature-icon">{{ f.icon }}</span>
          <div>
            <strong>{{ f.title }}</strong>
            <p class="text-muted" style="font-size:0.88rem; margin-top:2px;">{{ f.desc }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Team -->
    <div class="section card">
      <h2>👥 Meet the Team</h2>
      <p class="text-muted" style="margin-bottom:20px;">
        This project was developed by Group 1 for INFO3180 (Web Application Development II).
      </p>
      <div class="team-grid">
        <div v-for="member in team" :key="member.name" class="team-card">
          <div class="team-avatar">{{ member.initials }}</div>
          <strong>{{ member.name }}</strong>
          <small class="text-muted">{{ member.role }}</small>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const features = [
  { icon: '🎯', title: 'Smart Matching Algorithm', desc: 'Ranks profiles by shared interests, location, age preferences, and relationship goals using the Haversine formula for distance.' },
  { icon: '👆', title: 'Like / Dislike / Pass Swiping', desc: 'Swipe on profiles. When two users both like each other, a match is created automatically with instant notification.' },
  { icon: '💬', title: 'Private Messaging', desc: 'Chat only with your matches. Messages update every 5 seconds for near real-time conversation.' },
  { icon: '🔍', title: 'Advanced Search & Filters', desc: 'Search by name, city, age, gender, relationship goal, and shared interests. Sort by newest or most similar.' },
  { icon: '⭐', title: 'Save Favourites', desc: 'Bookmark profiles you like and revisit them from your Saved tab anytime.' },
  { icon: '📸', title: 'Multi-Photo Profiles', desc: 'Upload up to 5 photos. Set your primary photo that appears in discover and search results.' },
  { icon: '🔔', title: 'In-App Notifications', desc: 'Receive notifications for new matches, likes, messages, and saved profiles.' },
  { icon: '🚫', title: 'Block & Report', desc: 'Stay safe. Block users from seeing your profile or report inappropriate behaviour.' },
  { icon: '📍', title: 'Location-Based Discovery', desc: 'Filter by distance. Profiles are ranked closer to you first when location data is available.' },
]

const team = [
  { name: 'Team Member 1', role: 'Project Manager / Backend', initials: 'TM' },
  { name: 'Team Member 2', role: 'Frontend Lead (Vue)',       initials: 'TM' },
  { name: 'Team Member 3', role: 'QA & Testing',             initials: 'TM' },
  { name: 'Team Member 4', role: 'Database & Deployment',    initials: 'TM' },
]
</script>

<style scoped>
.about-hero { margin-bottom: 40px; }

.section h2 { font-size: 1.3rem; font-weight: 800; margin-bottom: 20px; }

.tech-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 16px;
}
.tech-item {
  display: flex; align-items: center; gap: 12px;
  padding: 12px; background: #f8f9fa; border-radius: 10px;
}
.tech-icon { font-size: 1.8rem; }

.feature-list { display: flex; flex-direction: column; gap: 16px; }
.feature-row  { display: flex; gap: 14px; align-items: flex-start; }
.feature-icon { font-size: 1.5rem; flex-shrink: 0; width: 36px; text-align: center; }

.team-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 16px;
}
.team-card {
  display: flex; flex-direction: column; align-items: center; gap: 8px;
  padding: 20px 12px; background: #f8f9fa; border-radius: 12px; text-align: center;
}
.team-avatar {
  width: 56px; height: 56px; border-radius: 50%;
  background: linear-gradient(135deg, #e91e8c, #ff6b35);
  color: #fff; font-size: 1.1rem; font-weight: 800;
  display: flex; align-items: center; justify-content: center;
}
</style>
