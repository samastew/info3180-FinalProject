<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'

const router  = useRouter()
const auth    = useAuthStore()
const loading = ref(true)
const saving  = ref(false)
const errors  = ref([])
const success  = ref(false)
const interests     = ref([])
const selectedInts  = ref([])
const photoFile     = ref(null)
const photoUploading = ref(false)

const form = ref({
  first_name: '', last_name: '', bio: '', city: '', country: '',
  gender: '', occupation: '', education_level: '', relationship_goal: '',
  looking_for: 'any', min_age_pref: 18, max_age_pref: 60, is_visible: true,
})

onMounted(async () => {
  try {
    const [profRes, intRes] = await Promise.all([
      api.get(`/profiles/${auth.currentUserId}`),
      api.get('/interests'),
    ])
    const p = profRes.data.profile
    Object.keys(form.value).forEach(k => { if (p[k] !== undefined) form.value[k] = p[k] })
    interests.value    = intRes.data.interests
    selectedInts.value = (p.interests || []).map(i => i.interest_id)
  } catch {}
  loading.value = false
})

function toggleInt(id) {
  const idx = selectedInts.value.indexOf(id)
  if (idx >= 0) selectedInts.value.splice(idx, 1)
  else selectedInts.value.push(id)
}

async function handlePhotoUpload(e) {
  const file = e.target.files[0]
  if (!file) return
  photoFile.value     = file
  photoUploading.value = true
  const fd = new FormData()
  fd.append('photo', file)
  fd.append('is_primary', 'true')
  try {
    await api.post(`/profiles/${auth.currentUserId}/photos`, fd, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    await auth.fetchMe()
  } catch {}
  photoUploading.value = false
}

async function save() {
  errors.value  = []
  success.value = false
  if (selectedInts.value.length < 3) {
    errors.value = ['Please select at least 3 interests.']
    return
  }
  saving.value = true
  try {
    const payload = { ...form.value, interest_ids: selectedInts.value }
    const res = await api.put(`/profiles/${auth.currentUserId}`, payload)
    auth.setProfile(res.data.profile)
    success.value = true
    setTimeout(() => (success.value = false), 3000)
  } catch (e) {
    const data = e.response?.data
    if (data?.errors) errors.value = Array.isArray(data.errors) ? data.errors : [data.errors]
    else errors.value = ['Failed to save changes.']
  } finally {
    saving.value = false
  }
}

const grouped = () => {
  const g = {}
  interests.value.forEach(i => {
    if (!g[i.category]) g[i.category] = []
    g[i.category].push(i)
  })
  return g
}
</script>

<template>
  <div class="edit-page">
    <div class="edit-inner">
      <div class="edit-header">
        <button class="btn btn-ghost" @click="router.push({ name: 'profile', params: { userId: auth.currentUserId } })">
          ← Back to Profile
        </button>
        <h1 class="section-title">Edit Profile</h1>
      </div>

      <div v-if="loading" style="text-align:center;padding:80px 0"><div class="spinner"></div></div>

      <template v-else>
        <ul v-if="errors.length" class="error-list" style="margin-bottom:20px">
          <li v-for="err in errors" :key="err">{{ err }}</li>
        </ul>

        <div v-if="success" class="success-banner">✅ Profile saved successfully!</div>

        <!-- Photo upload -->
        <div class="edit-section card">
          <h2 class="edit-section-title">Profile Photo</h2>
          <div class="photo-upload-area">
            <div class="current-photo">
              <img v-if="auth.profile?.profile_photo_url" :src="auth.profile.profile_photo_url" alt="Profile photo" />
              <div v-else class="photo-placeholder-sm">{{ auth.profile?.first_name?.[0] || '?' }}</div>
            </div>
            <div>
              <label class="btn btn-secondary upload-btn">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                <span>{{ photoUploading ? 'Uploading…' : 'Upload Photo' }}</span>
                <input type="file" accept="image/*" @change="handlePhotoUpload" style="display:none" :disabled="photoUploading" />
              </label>
              <p class="upload-hint">JPG, PNG or GIF · Max 16 MB</p>
            </div>
          </div>
        </div>

        <!-- Basic info -->
        <div class="edit-section card">
          <h2 class="edit-section-title">Basic Info</h2>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">First Name</label>
              <input v-model="form.first_name" type="text" class="form-control" />
            </div>
            <div class="form-group">
              <label class="form-label">Last Name</label>
              <input v-model="form.last_name" type="text" class="form-control" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Gender</label>
              <select v-model="form.gender" class="form-control">
                <option value="female">Female</option>
                <option value="male">Male</option>
                <option value="non-binary">Non-binary</option>
                <option value="other">Other</option>
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">City</label>
              <input v-model="form.city" type="text" class="form-control" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Country</label>
              <input v-model="form.country" type="text" class="form-control" />
            </div>
            <div class="form-group">
              <label class="form-label">Occupation</label>
              <input v-model="form.occupation" type="text" class="form-control" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Education</label>
              <select v-model="form.education_level" class="form-control">
                <option value="">Select level</option>
                <option value="high_school">High School</option>
                <option value="bachelors">Bachelor's</option>
                <option value="masters">Master's</option>
                <option value="phd">PhD</option>
                <option value="other">Other</option>
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">Relationship Goal</label>
              <select v-model="form.relationship_goal" class="form-control">
                <option value="">Select goal</option>
                <option value="casual">Casual</option>
                <option value="serious">Serious</option>
                <option value="friendship">Friendship</option>
                <option value="marriage">Marriage</option>
              </select>
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">Bio</label>
            <textarea v-model="form.bio" class="form-control" rows="4"></textarea>
          </div>
          <div class="form-group">
            <label class="form-label toggle-row">
              Profile Visible to Others
              <div class="toggle" :class="{ on: form.is_visible }" @click="form.is_visible = !form.is_visible">
                <div class="toggle-knob"></div>
              </div>
            </label>
          </div>
        </div>

        <!-- Preferences -->
        <div class="edit-section card">
          <h2 class="edit-section-title">Preferences</h2>
          <div class="form-group">
            <label class="form-label">I'm looking for</label>
            <div class="option-pills">
              <button v-for="opt in ['any','male','female','non-binary']" :key="opt"
                class="pill" :class="{ active: form.looking_for === opt }"
                @click="form.looking_for = opt">
                {{ opt.charAt(0).toUpperCase() + opt.slice(1) }}
              </button>
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">Age Range: {{ form.min_age_pref }} – {{ form.max_age_pref }}</label>
            <div class="range-row">
              <input v-model.number="form.min_age_pref" type="range" min="18" max="99" class="range-input" />
              <input v-model.number="form.max_age_pref" type="range" min="18" max="99" class="range-input" />
            </div>
          </div>
        </div>

        <!-- Interests -->
        <div class="edit-section card">
          <h2 class="edit-section-title">Interests ({{ selectedInts.length }} selected)</h2>
          <div v-for="(list, cat) in grouped()" :key="cat" class="interest-group">
            <h4 class="interest-cat">{{ cat }}</h4>
            <div class="interest-chips">
              <button v-for="i in list" :key="i.interest_id"
                class="chip" :class="{ selected: selectedInts.includes(i.interest_id) }"
                @click="toggleInt(i.interest_id)">
                {{ i.name }} <span v-if="selectedInts.includes(i.interest_id)">✓</span>
              </button>
            </div>
          </div>
        </div>

        <div class="edit-submit">
          <button class="btn btn-secondary" @click="router.back()">Cancel</button>
          <button class="btn btn-primary" :disabled="saving" @click="save">
            <span v-if="saving">Saving…</span>
            <span v-else>Save Changes</span>
          </button>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.edit-page { min-height: calc(100vh - var(--nav-height)); background: var(--nude); padding: 40px 24px 80px; }
.edit-inner { max-width: 700px; margin: 0 auto; }
.edit-header { margin-bottom: 28px; }
.edit-section { padding: 28px; margin-bottom: 20px; }
.edit-section-title { font-family: var(--font-display); font-size: 22px; margin-bottom: 20px; }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
textarea.form-control { resize: vertical; }

.success-banner {
  background: #D1FAE5; color: #065F46; padding: 12px 20px;
  border-radius: var(--radius-sm); margin-bottom: 20px; font-weight: 600;
  border-left: 4px solid #10B981;
}

.photo-upload-area { display: flex; align-items: center; gap: 20px; }
.current-photo { width: 80px; height: 80px; border-radius: 50%; overflow: hidden; border: 3px solid var(--coral); }
.current-photo img { width: 100%; height: 100%; object-fit: cover; }
.photo-placeholder-sm {
  width: 100%; height: 100%; display: flex; align-items: center; justify-content: center;
  background: var(--blush); font-family: var(--font-display); font-size: 28px; color: var(--coral);
}
.upload-btn { cursor: pointer; display: inline-flex; align-items: center; gap: 8px; }
.upload-hint { font-size: 12px; color: var(--mist); margin-top: 6px; }

.toggle-row { display: flex; justify-content: space-between; align-items: center; cursor: default; }
.toggle { width: 44px; height: 24px; border-radius: 12px; background: #D1D5DB; cursor: pointer; position: relative; transition: background 0.2s; }
.toggle.on { background: var(--coral); }
.toggle-knob { position: absolute; top: 2px; left: 2px; width: 20px; height: 20px; border-radius: 50%; background: white; transition: transform 0.2s; box-shadow: var(--shadow-sm); }
.toggle.on .toggle-knob { transform: translateX(20px); }

.option-pills { display: flex; flex-wrap: wrap; gap: 8px; }
.pill { padding: 7px 18px; border-radius: 50px; border: 2px solid #E5E7EB; background: white; font-size: 14px; cursor: pointer; transition: all 0.2s; font-family: var(--font-body); color: var(--ink); }
.pill.active { border-color: var(--coral); background: var(--blush); color: var(--crimson); font-weight: 600; }

.range-row { display: flex; flex-direction: column; gap: 8px; }
.range-input { width: 100%; accent-color: var(--coral); }

.interest-group { margin-bottom: 16px; }
.interest-cat { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; color: var(--mist); margin-bottom: 8px; }
.interest-chips { display: flex; flex-wrap: wrap; gap: 8px; }
.chip { padding: 5px 14px; border-radius: 50px; border: 2px solid #E5E7EB; background: white; font-size: 13px; cursor: pointer; transition: all 0.2s; font-family: var(--font-body); color: var(--slate); }
.chip.selected { border-color: var(--coral); background: var(--blush); color: var(--crimson); font-weight: 600; }

.edit-submit { display: flex; gap: 12px; justify-content: flex-end; margin-top: 8px; }
</style>
