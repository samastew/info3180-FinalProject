<template>
  <div class="profile-editor">
    <h3 class="section-title">{{ isNew ? 'Complete your profile' : 'Edit profile' }}</h3>
    <p v-if="isNew" class="text-muted mb-4">
      Fill in your details so we can find your best matches.
    </p>

    <div v-if="saved" class="alert alert-success">Profile saved!</div>

    <form @submit.prevent="handleSave">
      <!-- Profile picture -->
      <div class="photo-upload mb-4" @click="triggerFileInput">
        <img v-if="form.profilePicture" :src="form.profilePicture" class="photo-preview" alt="Profile" />
        <div v-else class="photo-placeholder">
          <span class="photo-icon">&#128247;</span>
          <span class="photo-hint">Upload photo</span>
        </div>
        <input ref="fileInput" type="file" accept="image/*" class="d-none" @change="handlePhotoUpload" />
      </div>

      <!-- Basic info -->
      <div class="row g-3 mb-3">
        <div class="col-md-8">
          <label class="form-label">Name</label>
          <input v-model="form.name" type="text" class="form-control" :class="{ 'is-invalid': errors.name }" />
          <div v-if="errors.name" class="invalid-feedback">{{ errors.name }}</div>
        </div>
        <div class="col-md-4">
          <label class="form-label">Age</label>
          <input v-model.number="form.age" type="number" class="form-control" min="18" max="99" />
        </div>
      </div>

      <div class="mb-3">
        <label class="form-label">Bio <span class="text-muted small">(max 300 chars)</span></label>
        <textarea
          v-model="form.bio"
          class="form-control"
          rows="3"
          maxlength="300"
          placeholder="Tell potential matches about yourself..."
        />
        <div class="text-end small text-muted mt-1">{{ form.bio.length }}/300</div>
      </div>

      <!-- Location -->
      <div class="row g-3 mb-3">
        <div class="col-md-6">
          <label class="form-label">City</label>
          <input v-model="form.locationCity" type="text" class="form-control" :class="{ 'is-invalid': errors.locationCity }" placeholder="e.g. Kingston" />
          <div v-if="errors.locationCity" class="invalid-feedback">{{ errors.locationCity }}</div>
        </div>
        <div class="col-md-6">
          <label class="form-label">Max distance (km)</label>
          <input v-model.number="form.maxDistanceKm" type="number" class="form-control" min="5" max="500" />
        </div>
      </div>

      <!-- Interests — minimum 3 required -->
      <div class="mb-3">
        <label class="form-label">
          Interests
          <span class="badge bg-secondary ms-1">{{ form.interests.length }} selected</span>
          <span v-if="errors.interests" class="text-danger small ms-2">{{ errors.interests }}</span>
        </label>
        <div class="interest-grid">
          <button
            v-for="tag in INTEREST_OPTIONS"
            :key="tag"
            type="button"
            class="interest-tag"
            :class="{ active: form.interests.includes(tag) }"
            @click="toggleInterest(tag)"
          >
            {{ tag }}
          </button>
        </div>
      </div>

      <!-- Custom fields -->
      <div class="row g-3 mb-3">
        <div class="col-md-6">
          <label class="form-label">Occupation</label>
          <input v-model="form.occupation" type="text" class="form-control" placeholder="What do you do?" />
        </div>
        <div class="col-md-6">
          <label class="form-label">Looking for</label>
          <select v-model="form.lookingFor" class="form-select">
            <option value="">Select…</option>
            <option v-for="opt in LOOKING_FOR_OPTIONS" :key="opt" :value="opt">{{ opt }}</option>
          </select>
        </div>
      </div>

      <!-- Age preference -->
      <div class="mb-3">
        <label class="form-label">Preferred age range</label>
        <div class="row g-2">
          <div class="col-6">
            <div class="input-group">
              <span class="input-group-text small">Min</span>
              <input v-model.number="form.ageMin" type="number" class="form-control" min="18" max="99" />
            </div>
          </div>
          <div class="col-6">
            <div class="input-group">
              <span class="input-group-text small">Max</span>
              <input v-model.number="form.ageMax" type="number" class="form-control" min="18" max="99" />
            </div>
          </div>
        </div>
      </div>

      <!-- Visibility toggle -->
      <div class="mb-4 d-flex align-items-center gap-3">
        <label class="form-label mb-0">Profile visibility</label>
        <div class="form-check form-switch ms-auto">
          <input v-model="form.isPublic" class="form-check-input" type="checkbox" role="switch" id="visibility-toggle" />
          <label class="form-check-label" for="visibility-toggle">
            {{ form.isPublic ? 'Public' : 'Private' }}
          </label>
        </div>
      </div>

      <button type="submit" class="btn btn-primary px-5" :disabled="authStore.loading">
        <span v-if="authStore.loading" class="spinner-border spinner-border-sm me-2" />
        Save profile
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { INTEREST_OPTIONS, LOOKING_FOR_OPTIONS } from '@/data/mockData'

const props = defineProps({ isNew: { type: Boolean, default: false } })
const authStore = useAuthStore()
const router = useRouter()
const fileInput = ref(null)
const saved = ref(false)
const errors = reactive({ name: '', locationCity: '', interests: '' })

// Form state — pre-populated from current user
const form = reactive({
  name: '',
  age: 18,
  bio: '',
  locationCity: '',
  maxDistanceKm: 50,
  interests: [],
  occupation: '',
  lookingFor: '',
  ageMin: 18,
  ageMax: 60,
  isPublic: true,
  profilePicture: null,
})

onMounted(() => {
  const u = authStore.currentUser
  if (u) {
    form.name = u.name || ''
    form.age = u.age || 18
    form.bio = u.bio || ''
    form.locationCity = u.location?.city || ''
    form.maxDistanceKm = u.maxDistanceKm || 50
    form.interests = [...(u.interests || [])]
    form.occupation = u.occupation || ''
    form.lookingFor = u.lookingFor || ''
    form.ageMin = u.agePreference?.min || 18
    form.ageMax = u.agePreference?.max || 60
    form.isPublic = u.isPublic ?? true
    form.profilePicture = u.profilePicture || null
  }
})

function toggleInterest(tag) {
  const idx = form.interests.indexOf(tag)
  if (idx === -1) {
    form.interests.push(tag)
  } else {
    form.interests.splice(idx, 1)
  }
}

function triggerFileInput() {
  fileInput.value?.click()
}

function handlePhotoUpload(event) {
  const file = event.target.files[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = e => { form.profilePicture = e.target.result }
  reader.readAsDataURL(file)
}

function validate() {
  let valid = true
  errors.name = ''
  errors.locationCity = ''
  errors.interests = ''

  if (!form.name.trim()) { errors.name = 'Name is required.'; valid = false }
  if (!form.locationCity.trim()) { errors.locationCity = 'City is required.'; valid = false }
  if (form.interests.length < 3) { errors.interests = 'Select at least 3 interests.'; valid = false }
  return valid
}

async function handleSave() {
  if (!validate()) return

  const updates = {
    name: form.name,
    age: form.age,
    bio: form.bio,
    location: {
      city: form.locationCity,
      // Mock coordinates based on common JA cities; backend would geocode properly
      lat: form.locationCity.toLowerCase().includes('kingston') ? 17.9714 : 18.0000,
      lng: form.locationCity.toLowerCase().includes('kingston') ? -76.7931 : -77.0000,
    },
    maxDistanceKm: form.maxDistanceKm,
    interests: form.interests,
    occupation: form.occupation,
    lookingFor: form.lookingFor,
    agePreference: { min: form.ageMin, max: form.ageMax },
    isPublic: form.isPublic,
    profilePicture: form.profilePicture,
  }

  const result = await authStore.updateProfile(updates)
  if (result.success) {
    saved.value = true
    setTimeout(() => { saved.value = false }, 3000)
    if (props.isNew) router.push('/discover')
  }
}
</script>

<style scoped>
.profile-editor {
  max-width: 680px;
  margin: 0 auto;
  padding: 1rem 0;
}
.section-title {
  font-size: 1.4rem;
  font-weight: 600;
  color: #1a1a2e;
  margin-bottom: 0.5rem;
}
/* Photo upload */
.photo-upload {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  border: 2px dashed #c8d6e5;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  overflow: hidden;
  transition: border-color 0.2s;
}
.photo-upload:hover { border-color: #4361ee; }
.photo-preview {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.photo-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  color: #9ca3af;
}
.photo-icon { font-size: 28px; }
.photo-hint { font-size: 11px; }
/* Interest grid */
.interest-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 8px;
}
.interest-tag {
  padding: 5px 14px;
  border-radius: 20px;
  border: 1.5px solid #d1d5db;
  background: #f9fafb;
  color: #374151;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.15s;
}
.interest-tag:hover { border-color: #4361ee; color: #4361ee; }
.interest-tag.active {
  background: #4361ee;
  border-color: #4361ee;
  color: #fff;
}
</style>