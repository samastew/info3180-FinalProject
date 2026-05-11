<template>
  <div class="container" style="padding-top:32px; padding-bottom:60px;">
    <div v-if="!auth.user" class="text-center" style="padding:60px;">
      <div class="spinner" style="width:40px;height:40px;border-width:4px;margin:0 auto;"></div>
    </div>
    <div v-else class="profile-layout">
      <!-- Left: Photo + actions -->
      <div class="profile-sidebar">
        <div class="profile-photo-wrap">
          <img
            :src="primaryPhotoUrl || fallback"
            alt="Profile photo"
            class="profile-main-photo"
            @error="e => e.target.src = fallback"
          />
          <label class="photo-upload-btn" title="Upload photo">
            📷
            <input type="file" accept="image/*" @change="uploadPhoto" style="display:none;" />
          </label>
        </div>

        <!-- Thumbnails -->
        <div class="photo-thumbs" v-if="auth.photos.length > 1">
          <div
            v-for="photo in auth.photos" :key="photo.photo_id"
            class="thumb"
            :class="{ primary: photo.is_primary }"
          >
            <img :src="photo.photo_url" />
            <button class="thumb-del" @click="deletePhoto(photo.photo_id)">✕</button>
          </div>
        </div>

        <RouterLink to="/profile/edit" class="btn btn-primary" style="width:100%; justify-content:center; margin-top:12px;">
          ✏️ Edit Profile
        </RouterLink>

        <div class="profile-stats">
          <div class="stat">
            <span class="stat-n">{{ matchCount }}</span>
            <span class="stat-l">Matches</span>
          </div>
          <div class="stat">
            <span class="stat-n">{{ auth.interests.length }}</span>
            <span class="stat-l">Interests</span>
          </div>
          <div class="stat">
            <span class="stat-n">{{ auth.photos.length }}</span>
            <span class="stat-l">Photos</span>
          </div>
        </div>
      </div>

      <!-- Right: Profile details -->
      <div class="profile-main">
        <div class="card mb-2">
          <div style="display:flex; justify-content:space-between; align-items:flex-start;">
            <div>
              <h1 style="font-size:1.8rem; font-weight:800;">
                {{ auth.profile?.first_name }} {{ auth.profile?.last_name }}
                <span style="font-size:1rem; font-weight:400; color:#6c757d;" v-if="auth.profile?.age">
                  {{ auth.profile.age }}
                </span>
              </h1>
              <p class="text-muted" v-if="auth.profile?.city">📍 {{ auth.profile.city }}, {{ auth.profile.country }}</p>
              <p class="text-muted" style="font-size:0.9rem;">@{{ auth.user.username }}</p>
            </div>
            <span :class="auth.profile?.is_visible ? 'badge badge-green' : 'badge badge-blue'">
              {{ auth.profile?.is_visible ? '👁️ Visible' : '🔒 Hidden' }}
            </span>
          </div>

          <p v-if="auth.profile?.bio" style="margin-top:12px; line-height:1.6; color:#495057;">
            {{ auth.profile.bio }}
          </p>
          <p v-else class="text-muted mt-1" style="font-style:italic;">No bio yet. <RouterLink to="/profile/edit">Add one!</RouterLink></p>
        </div>

        <div class="card mb-2">
          <h3 style="font-weight:700; margin-bottom:12px;">Profile Details</h3>
          <div class="detail-grid">
            <div class="detail-item" v-if="auth.profile?.gender">
              <span class="detail-label">Gender</span>
              <span>{{ capitalize(auth.profile.gender) }}</span>
            </div>
            <div class="detail-item" v-if="auth.profile?.looking_for">
              <span class="detail-label">Looking for</span>
              <span>{{ capitalize(auth.profile.looking_for) }}</span>
            </div>
            <div class="detail-item" v-if="auth.profile?.occupation">
              <span class="detail-label">Occupation</span>
              <span>{{ auth.profile.occupation }}</span>
            </div>
            <div class="detail-item" v-if="auth.profile?.education_level">
              <span class="detail-label">Education</span>
              <span>{{ capitalize(auth.profile.education_level) }}</span>
            </div>
            <div class="detail-item" v-if="auth.profile?.relationship_goal">
              <span class="detail-label">Goal</span>
              <span>{{ capitalize(auth.profile.relationship_goal) }}</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Age pref</span>
              <span>{{ auth.profile?.min_age_pref }}–{{ auth.profile?.max_age_pref }} yrs</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Max distance</span>
              <span>{{ auth.profile?.max_distance_km }} km</span>
            </div>
          </div>
        </div>

        <div class="card">
          <h3 style="font-weight:700; margin-bottom:12px;">Interests</h3>
          <div v-if="auth.interests.length" class="tags-wrap">
            <span v-for="i in auth.interests" :key="i.interest_id" class="tag">{{ i.name }}</span>
          </div>
          <p v-else class="text-muted">No interests added yet.</p>
        </div>

        <div v-if="photoError" class="alert alert-danger mt-2">{{ photoError }}</div>
        <div v-if="photoSuccess" class="alert alert-success mt-2">{{ photoSuccess }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/utils/api'

const auth = useAuthStore()
const matchCount  = ref(0)
const photoError  = ref('')
const photoSuccess = ref('')

const fallback = computed(() =>
  `https://ui-avatars.com/api/?name=${encodeURIComponent((auth.profile?.first_name || auth.user?.username || '?'))}&background=e91e8c&color=fff&size=300`
)

const primaryPhotoUrl = computed(() => {
  const primary = auth.photos.find(p => p.is_primary)
  return (primary || auth.photos[0])?.photo_url || null
})

function capitalize(s) {
  if (!s) return ''
  return s.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
}

async function uploadPhoto(e) {
  const file = e.target.files[0]
  if (!file) return
  photoError.value = ''
  const fd = new FormData()
  fd.append('photo', file)
  try {
    await api.post(`/users/${auth.user.user_id}/photos`, fd, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    photoSuccess.value = 'Photo uploaded!'
    await auth.fetchMe()
    setTimeout(() => photoSuccess.value = '', 3000)
  } catch (err) {
    photoError.value = err.response?.data?.error || 'Upload failed'
  }
  e.target.value = ''
}

async function deletePhoto(photoId) {
  try {
    await api.delete(`/users/${auth.user.user_id}/photos/${photoId}`)
    await auth.fetchMe()
  } catch {}
}

onMounted(async () => {
  await auth.fetchMe()
  try {
    const { data } = await api.get('/matches')
    matchCount.value = data.length
  } catch {}
})
</script>

<style scoped>
.profile-layout {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 24px;
  align-items: flex-start;
}
@media (max-width: 768px) {
  .profile-layout { grid-template-columns: 1fr; }
}

.profile-sidebar { display: flex; flex-direction: column; gap: 12px; }

.profile-photo-wrap {
  position: relative;
  border-radius: 16px;
  overflow: hidden;
  height: 280px;
}
.profile-main-photo { width: 100%; height: 100%; object-fit: cover; }
.photo-upload-btn {
  position: absolute;
  bottom: 10px; right: 10px;
  background: rgba(0,0,0,0.6);
  color: #fff;
  border-radius: 50%;
  width: 40px; height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 1.1rem;
  transition: background 0.2s;
}
.photo-upload-btn:hover { background: rgba(0,0,0,0.8); }

.photo-thumbs { display: flex; flex-wrap: wrap; gap: 8px; }
.thumb {
  position: relative;
  width: 60px; height: 60px;
  border-radius: 8px;
  overflow: hidden;
  border: 2px solid #dee2e6;
}
.thumb.primary { border-color: #e91e8c; }
.thumb img { width: 100%; height: 100%; object-fit: cover; }
.thumb-del {
  position: absolute;
  top: 2px; right: 2px;
  background: rgba(220,53,69,0.85);
  color: #fff;
  border: none;
  border-radius: 50%;
  width: 18px; height: 18px;
  font-size: 0.6rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.profile-stats {
  display: flex;
  gap: 8px;
  background: #fff;
  border-radius: 12px;
  padding: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.07);
}
.stat { flex: 1; text-align: center; }
.stat-n { display: block; font-size: 1.4rem; font-weight: 800; color: #e91e8c; }
.stat-l { font-size: 0.75rem; color: #6c757d; font-weight: 600; }

.detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.detail-item { display: flex; flex-direction: column; gap: 2px; }
.detail-label { font-size: 0.78rem; font-weight: 700; color: #6c757d; text-transform: uppercase; }

.tags-wrap { display: flex; flex-wrap: wrap; gap: 8px; }
.tag {
  background: #fce4ec;
  color: #c2157a;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.85rem;
  font-weight: 600;
}
</style>
