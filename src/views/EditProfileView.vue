<template>
  <div class="container-sm" style="padding-top:32px; padding-bottom:60px;">
    <div class="card">
      <div class="flex items-center justify-between mb-3">
        <h1 style="font-size:1.6rem; font-weight:800;">Edit Profile</h1>
        <RouterLink to="/profile" class="btn btn-secondary btn-sm">← Back</RouterLink>
      </div>

      <div v-if="success" class="alert alert-success">{{ success }}</div>
      <div v-if="error"   class="alert alert-danger">{{ error }}</div>

      <form @submit.prevent="handleSave">
        <h3 class="section-title">Basic Info</h3>
        <div class="form-row">
          <div class="form-group">
            <label>First Name</label>
            <input v-model="form.first_name" class="form-control" required />
          </div>
          <div class="form-group">
            <label>Last Name</label>
            <input v-model="form.last_name" class="form-control" required />
          </div>
        </div>

        <div class="form-group">
          <label>Username</label>
          <input v-model="form.username" class="form-control" required />
        </div>

        <div class="form-group">
          <label>Date of Birth</label>
          <input v-model="form.date_of_birth" type="date" class="form-control" :max="maxDob" />
        </div>

        <div class="form-group">
          <label>Bio</label>
          <textarea v-model="form.bio" class="form-control" rows="3" placeholder="Tell others about yourself…"></textarea>
        </div>

        <h3 class="section-title">Identity</h3>
        <div class="form-row">
          <div class="form-group">
            <label>Gender</label>
            <select v-model="form.gender" class="form-control">
              <option value="male">Male</option>
              <option value="female">Female</option>
              <option value="non_binary">Non-Binary</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div class="form-group">
            <label>Looking For</label>
            <select v-model="form.looking_for" class="form-control">
              <option value="any">Anyone</option>
              <option value="male">Men</option>
              <option value="female">Women</option>
              <option value="non_binary">Non-Binary</option>
            </select>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>Occupation</label>
            <input v-model="form.occupation" class="form-control" />
          </div>
          <div class="form-group">
            <label>Education</label>
            <select v-model="form.education_level" class="form-control">
              <option value="">Select…</option>
              <option value="high_school">High School</option>
              <option value="associate">Associate</option>
              <option value="bachelors">Bachelor's</option>
              <option value="masters">Master's</option>
              <option value="phd">PhD</option>
              <option value="other">Other</option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label>Relationship Goal</label>
          <select v-model="form.relationship_goal" class="form-control">
            <option value="">Any</option>
            <option value="casual">Casual</option>
            <option value="serious">Serious</option>
            <option value="friendship">Friendship</option>
            <option value="marriage">Marriage</option>
          </select>
        </div>

        <h3 class="section-title">Location</h3>
        <div class="form-row">
          <div class="form-group">
            <label>City</label>
            <input v-model="form.city" class="form-control" />
          </div>
          <div class="form-group">
            <label>Country</label>
            <input v-model="form.country" class="form-control" />
          </div>
        </div>

        <h3 class="section-title">Preferences</h3>
        <div class="form-row">
          <div class="form-group">
            <label>Min Age Preference</label>
            <input v-model.number="form.min_age_pref" type="number" class="form-control" min="18" max="99" />
          </div>
          <div class="form-group">
            <label>Max Age Preference</label>
            <input v-model.number="form.max_age_pref" type="number" class="form-control" min="18" max="99" />
          </div>
        </div>

        <div class="form-group">
          <label>Max Distance (km)</label>
          <input v-model.number="form.max_distance_km" type="range" class="form-control" min="5" max="500" style="padding:6px 0;" />
          <small class="text-muted">{{ form.max_distance_km }} km</small>
        </div>

        <div class="form-group">
          <label>
            <input type="checkbox" v-model="form.is_visible" style="margin-right:6px;" />
            Profile visible to others
          </label>
        </div>

        <h3 class="section-title">Interests</h3>
        <div class="interests-grid">
          <button
            v-for="interest in allInterests" :key="interest.interest_id"
            type="button"
            class="interest-btn"
            :class="{ selected: form.interest_ids.includes(interest.interest_id) }"
            @click="toggleInterest(interest.interest_id)"
          >{{ interest.name }}</button>
        </div>
        <small class="text-muted">Select at least 3</small>

        <button type="submit" class="btn btn-primary" style="width:100%; margin-top:24px;"
          :disabled="saving || form.interest_ids.length < 3">
          <span v-if="saving" class="spinner"></span>
          {{ saving ? 'Saving…' : 'Save Changes' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/utils/api'

const auth    = useAuthStore()
const saving  = ref(false)
const error   = ref('')
const success = ref('')
const allInterests = ref([])

const maxDob = computed(() => {
  const d = new Date()
  d.setFullYear(d.getFullYear() - 18)
  return d.toISOString().split('T')[0]
})

const form = ref({
  first_name: '', last_name: '', username: '',
  date_of_birth: '', gender: 'male', looking_for: 'any',
  bio: '', city: '', country: 'Jamaica',
  occupation: '', education_level: '', relationship_goal: '',
  min_age_pref: 18, max_age_pref: 55, max_distance_km: 100,
  is_visible: true,
  interest_ids: [],
})

function populateForm() {
  const p = auth.profile
  const u = auth.user
  if (!p || !u) return
  form.value = {
    first_name:        p.first_name       || '',
    last_name:         p.last_name        || '',
    username:          u.username         || '',
    date_of_birth:     p.date_of_birth    || '',
    gender:            p.gender           || 'male',
    looking_for:       p.looking_for      || 'any',
    bio:               p.bio              || '',
    city:              p.city             || '',
    country:           p.country          || 'Jamaica',
    occupation:        p.occupation       || '',
    education_level:   p.education_level  || '',
    relationship_goal: p.relationship_goal || '',
    min_age_pref:      p.min_age_pref     || 18,
    max_age_pref:      p.max_age_pref     || 55,
    max_distance_km:   p.max_distance_km  || 100,
    is_visible:        p.is_visible       !== undefined ? p.is_visible : true,
    interest_ids:      auth.interests.map(i => i.interest_id),
  }
}

function toggleInterest(id) {
  const idx = form.value.interest_ids.indexOf(id)
  if (idx === -1) form.value.interest_ids.push(id)
  else form.value.interest_ids.splice(idx, 1)
}

async function handleSave() {
  saving.value  = true
  error.value   = ''
  success.value = ''
  try {
    await auth.updateProfile(form.value)
    success.value = 'Profile updated successfully!'
    window.scrollTo({ top: 0, behavior: 'smooth' })
    setTimeout(() => success.value = '', 3000)
  } catch (e) {
    error.value = e.response?.data?.error || 'Failed to save'
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  await auth.fetchMe()
  populateForm()
  const { data } = await api.get('/interests')
  allInterests.value = data
})
</script>

<style scoped>
.section-title {
  font-size: 1rem;
  font-weight: 700;
  color: #e91e8c;
  margin: 24px 0 12px;
  padding-bottom: 6px;
  border-bottom: 2px solid #fce4ec;
}
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
@media (max-width: 480px) { .form-row { grid-template-columns: 1fr; } }

.interests-grid { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 4px; }
.interest-btn {
  padding: 6px 14px;
  border: 2px solid #dee2e6;
  border-radius: 20px;
  background: none;
  cursor: pointer;
  font-size: 0.85rem;
  transition: all 0.2s;
  font-weight: 500;
}
.interest-btn.selected { border-color: #e91e8c; background: #fce4ec; color: #c2157a; font-weight: 700; }
</style>
