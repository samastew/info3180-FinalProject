<template>
  <div class="container-sm" style="padding-top: 40px; padding-bottom: 60px;">
    <div class="card">
      <div class="text-center mb-3">
        <h1 style="font-size: 1.8rem; font-weight: 800;">Create Your Profile 💕</h1>
        <p class="text-muted">Join DriftDater and find your perfect match</p>
      </div>

      <div v-if="error" class="alert alert-danger">{{ error }}</div>

      <!-- Step indicators -->
      <div class="steps">
        <div v-for="s in 3" :key="s" class="step" :class="{ active: step === s, done: step > s }">
          <div class="step-circle">{{ step > s ? '✓' : s }}</div>
          <div class="step-label">{{ stepLabels[s-1] }}</div>
        </div>
      </div>

      <!-- Step 1: Account -->
      <form v-if="step === 1" @submit.prevent="nextStep">
        <div class="form-group">
          <label>Username *</label>
          <input v-model="form.username" class="form-control" placeholder="e.g. cooljamaicanvibes" required />
        </div>
        <div class="form-group">
          <label>Email *</label>
          <input v-model="form.email" type="email" class="form-control" placeholder="you@example.com" required />
        </div>
        <div class="form-group">
          <label>Password *</label>
          <input v-model="form.password" type="password" class="form-control" placeholder="At least 8 characters" minlength="8" required />
        </div>
        <div class="form-group">
          <label>Confirm Password *</label>
          <input v-model="confirmPassword" type="password" class="form-control" placeholder="Repeat password" required />
          <small v-if="confirmPassword && form.password !== confirmPassword" class="text-danger">Passwords don't match</small>
        </div>
        <button type="submit" class="btn btn-primary" style="width:100%"
          :disabled="form.password !== confirmPassword">Continue →</button>
      </form>

      <!-- Step 2: Profile -->
      <form v-if="step === 2" @submit.prevent="nextStep">
        <div class="form-row">
          <div class="form-group">
            <label>First Name *</label>
            <input v-model="form.first_name" class="form-control" required />
          </div>
          <div class="form-group">
            <label>Last Name *</label>
            <input v-model="form.last_name" class="form-control" required />
          </div>
        </div>
        <div class="form-group">
          <label>Date of Birth *</label>
          <input v-model="form.date_of_birth" type="date" class="form-control" required :max="maxDob" />
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>Gender *</label>
            <select v-model="form.gender" class="form-control" required>
              <option value="">Select...</option>
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
        <div class="form-group">
          <label>City</label>
          <input v-model="form.city" class="form-control" placeholder="e.g. Kingston" />
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>Occupation</label>
            <input v-model="form.occupation" class="form-control" placeholder="e.g. Software Engineer" />
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
        </div>
        <div class="form-group">
          <label>Bio</label>
          <textarea v-model="form.bio" class="form-control" rows="3" placeholder="Tell others about yourself..."></textarea>
        </div>
        <div style="display:flex; gap:12px;">
          <button type="button" class="btn btn-secondary" @click="step=1">← Back</button>
          <button type="submit" class="btn btn-primary" style="flex:1">Continue →</button>
        </div>
      </form>

      <!-- Step 3: Interests -->
      <form v-if="step === 3" @submit.prevent="handleRegister">
        <p class="text-muted mb-2">Pick at least 3 interests that describe you:</p>
        <div class="interests-grid">
          <button
            v-for="interest in allInterests" :key="interest.interest_id"
            type="button"
            class="interest-btn"
            :class="{ selected: form.interest_ids.includes(interest.interest_id) }"
            @click="toggleInterest(interest.interest_id)"
          >{{ interest.name }}</button>
        </div>
        <p v-if="form.interest_ids.length < 3" class="text-muted mt-1" style="font-size:0.85rem">
          Select {{ 3 - form.interest_ids.length }} more
        </p>
        <div style="display:flex; gap:12px; margin-top:20px;">
          <button type="button" class="btn btn-secondary" @click="step=2">← Back</button>
          <button type="submit" class="btn btn-primary" style="flex:1"
            :disabled="form.interest_ids.length < 3 || loading">
            <span v-if="loading" class="spinner"></span>
            {{ loading ? 'Creating...' : 'Create Profile 🎉' }}
          </button>
        </div>
      </form>

      <p class="text-center mt-2 text-muted" style="font-size:0.9rem">
        Already have an account? <RouterLink to="/login" style="color:#e91e8c; font-weight:600;">Sign In</RouterLink>
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/utils/api'

const auth   = useAuthStore()
const router = useRouter()

const step            = ref(1)
const stepLabels      = ['Account', 'Profile', 'Interests']
const loading         = ref(false)
const error           = ref('')
const confirmPassword = ref('')
const allInterests    = ref([])

const maxDob = computed(() => {
  const d = new Date()
  d.setFullYear(d.getFullYear() - 18)
  return d.toISOString().split('T')[0]
})

const form = ref({
  username: '', email: '', password: '',
  first_name: '', last_name: '', date_of_birth: '',
  gender: '', looking_for: 'any', bio: '',
  city: '', country: 'Jamaica', occupation: '', relationship_goal: '',
  interest_ids: [],
})

onMounted(async () => {
  const { data } = await api.get('/interests')
  allInterests.value = data
})

function nextStep() {
  error.value = ''
  step.value++
}

function toggleInterest(id) {
  const idx = form.value.interest_ids.indexOf(id)
  if (idx === -1) form.value.interest_ids.push(id)
  else form.value.interest_ids.splice(idx, 1)
}

async function handleRegister() {
  loading.value = true
  error.value   = ''
  try {
    await auth.register(form.value)
    router.push('/discover')
  } catch (e) {
    error.value = e.response?.data?.error || 'Registration failed'
    step.value  = 1
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.steps {
  display: flex;
  justify-content: center;
  gap: 12px;
  margin-bottom: 32px;
}
.step {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  flex: 1;
  max-width: 120px;
}
.step-circle {
  width: 36px; height: 36px;
  border-radius: 50%;
  background: #dee2e6;
  color: #6c757d;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.9rem;
}
.step.active .step-circle { background: #e91e8c; color: #fff; }
.step.done   .step-circle { background: #28a745; color: #fff; }
.step-label { font-size: 0.75rem; color: #6c757d; font-weight: 600; }

.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
@media (max-width: 480px) { .form-row { grid-template-columns: 1fr; } }

.interests-grid { display: flex; flex-wrap: wrap; gap: 8px; }
.interest-btn {
  padding: 8px 16px;
  border: 2px solid #dee2e6;
  border-radius: 20px;
  background: none;
  cursor: pointer;
  font-size: 0.875rem;
  transition: all 0.2s;
  font-weight: 500;
}
.interest-btn.selected { border-color: #e91e8c; background: #fce4ec; color: #c2157a; font-weight: 600; }
.interest-btn:hover { border-color: #e91e8c; }

.text-danger { color: #dc3545; font-size: 0.8rem; }
</style>
