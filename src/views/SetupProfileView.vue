<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'

const router = useRouter()
const auth   = useAuthStore()

const step     = ref(1)
const errors   = ref([])
const loading  = ref(false)
const interests = ref([])
const selected  = ref([])

const form = ref({
  first_name: '', last_name: '', date_of_birth: '', gender: '',
  bio: '', city: '', country: 'Jamaica',
  looking_for: 'any', min_age_pref: 18, max_age_pref: 60,
  occupation: '', education_level: '', relationship_goal: '',
})

onMounted(async () => {
  const res = await api.get('/interests')
  interests.value = res.data.interests
})

const grouped = () => {
  const g = {}
  interests.value.forEach(i => {
    if (!g[i.category]) g[i.category] = []
    g[i.category].push(i)
  })
  return g
}

function toggleInterest(id) {
  const idx = selected.value.indexOf(id)
  if (idx >= 0) selected.value.splice(idx, 1)
  else selected.value.push(id)
}

async function submit() {
  errors.value = []
  if (selected.value.length < 3) {
    errors.value = ['Please select at least 3 interests.']
    return
  }
  loading.value = true
  try {
    const payload = { ...form.value, interest_ids: selected.value }
    const res = await api.post('/profiles', payload)
    auth.setProfile(res.data.profile)
    router.push({ name: 'discover' })
  } catch (e) {
    const data = e.response?.data
    if (data?.errors) errors.value = Array.isArray(data.errors) ? data.errors : [data.errors]
    else errors.value = ['Failed to create profile.']
  } finally {
    loading.value = false
  }
}

function nextStep() {
  errors.value = []
  const f = form.value
  if (step.value === 1) {
    if (!f.first_name || !f.last_name || !f.date_of_birth || !f.gender) {
      errors.value = ['Please fill all required fields.']
      return
    }
  }
  step.value++
}
</script>

<template>
  <div class="setup-page">
    <div class="setup-inner">
      <!-- Progress -->
      <div class="progress-bar">
        <div class="progress-fill" :style="{ width: (step / 3 * 100) + '%' }"></div>
      </div>
      <p class="progress-label">Step {{ step }} of 3</p>

      <h1 class="setup-title">
        {{ step === 1 ? '👋 Tell us about you' : step === 2 ? '🎯 Your preferences' : '✨ Your interests' }}
      </h1>

      <ul v-if="errors.length" class="error-list" style="margin-bottom:20px">
        <li v-for="err in errors" :key="err">{{ err }}</li>
      </ul>

      <!-- Step 1: Basic Info -->
      <div v-if="step === 1" class="step-form">
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">First Name *</label>
            <input v-model="form.first_name" type="text" class="form-control" placeholder="Jane" />
          </div>
          <div class="form-group">
            <label class="form-label">Last Name *</label>
            <input v-model="form.last_name" type="text" class="form-control" placeholder="Doe" />
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Date of Birth *</label>
            <input v-model="form.date_of_birth" type="date" class="form-control" />
          </div>
          <div class="form-group">
            <label class="form-label">Gender *</label>
            <select v-model="form.gender" class="form-control">
              <option value="">Select gender</option>
              <option value="female">Female</option>
              <option value="male">Male</option>
              <option value="non-binary">Non-binary</option>
              <option value="other">Other</option>
            </select>
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">City</label>
            <input v-model="form.city" type="text" class="form-control" placeholder="Kingston" />
          </div>
          <div class="form-group">
            <label class="form-label">Country</label>
            <input v-model="form.country" type="text" class="form-control" placeholder="Jamaica" />
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Bio</label>
          <textarea v-model="form.bio" class="form-control" rows="4" placeholder="Tell the world a little about yourself…"></textarea>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Occupation</label>
            <input v-model="form.occupation" type="text" class="form-control" placeholder="Software Engineer" />
          </div>
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
        </div>
        <button class="btn btn-primary" style="width:100%;justify-content:center" @click="nextStep">
          Continue →
        </button>
      </div>

      <!-- Step 2: Preferences -->
      <div v-if="step === 2" class="step-form">
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
          <label class="form-label">Relationship Goal</label>
          <div class="option-pills">
            <button v-for="opt in [['casual','😊 Casual'],['serious','💍 Serious'],['friendship','🤝 Friendship'],['marriage','💒 Marriage']]"
              :key="opt[0]" class="pill" :class="{ active: form.relationship_goal === opt[0] }"
              @click="form.relationship_goal = opt[0]">
              {{ opt[1] }}
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
        <div class="step-btns">
          <button class="btn btn-secondary" @click="step--">← Back</button>
          <button class="btn btn-primary" @click="step++">Continue →</button>
        </div>
      </div>

      <!-- Step 3: Interests -->
      <div v-if="step === 3" class="step-form">
        <p class="interest-hint">Select at least 3 interests that describe you</p>
        <div v-for="(list, cat) in grouped()" :key="cat" class="interest-group">
          <h4 class="interest-cat">{{ cat }}</h4>
          <div class="interest-chips">
            <button v-for="i in list" :key="i.interest_id"
              class="chip" :class="{ selected: selected.includes(i.interest_id) }"
              @click="toggleInterest(i.interest_id)">
              {{ i.name }}
              <span v-if="selected.includes(i.interest_id)">✓</span>
            </button>
          </div>
        </div>
        <p class="interest-count">{{ selected.length }} selected</p>
        <div class="step-btns">
          <button class="btn btn-secondary" @click="step--">← Back</button>
          <button class="btn btn-primary" :disabled="loading" @click="submit">
            <span v-if="loading">Creating…</span>
            <span v-else>Complete Profile 🎉</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.setup-page {
  min-height: 100vh; background: var(--nude);
  display: flex; align-items: flex-start; justify-content: center;
  padding: 40px 24px 80px;
}
.setup-inner { width: 100%; max-width: 620px; }
.progress-bar {
  height: 6px; background: #E5E7EB; border-radius: 3px;
  margin-bottom: 8px; overflow: hidden;
}
.progress-fill { height: 100%; background: linear-gradient(90deg, var(--coral), #FF4E4E); border-radius: 3px; transition: width 0.4s ease; }
.progress-label { font-size: 13px; color: var(--mist); margin-bottom: 24px; }
.setup-title { font-family: var(--font-display); font-size: 32px; margin-bottom: 28px; }
.step-form { background: white; border-radius: var(--radius-lg); padding: 32px; box-shadow: var(--shadow-sm); }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
textarea.form-control { resize: vertical; }

.option-pills { display: flex; flex-wrap: wrap; gap: 8px; }
.pill {
  padding: 8px 20px; border-radius: 50px; border: 2px solid #E5E7EB;
  background: white; font-size: 14px; cursor: pointer; transition: all 0.2s;
  font-family: var(--font-body); color: var(--ink);
}
.pill.active { border-color: var(--coral); background: var(--blush); color: var(--crimson); font-weight: 600; }

.range-row { display: flex; flex-direction: column; gap: 8px; }
.range-input { width: 100%; accent-color: var(--coral); }

.step-btns { display: flex; gap: 12px; justify-content: flex-end; margin-top: 24px; }

.interest-hint { color: var(--mist); margin-bottom: 20px; font-size: 14px; }
.interest-group { margin-bottom: 20px; }
.interest-cat { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; color: var(--mist); margin-bottom: 8px; }
.interest-chips { display: flex; flex-wrap: wrap; gap: 8px; }
.chip {
  padding: 6px 16px; border-radius: 50px; border: 2px solid #E5E7EB;
  background: white; font-size: 14px; cursor: pointer; transition: all 0.2s;
  font-family: var(--font-body); color: var(--slate); display: flex; align-items: center; gap: 6px;
}
.chip.selected { border-color: var(--coral); background: var(--blush); color: var(--crimson); font-weight: 600; }
.interest-count { margin-top: 12px; font-size: 14px; font-weight: 600; color: var(--coral); text-align: right; }
</style>
