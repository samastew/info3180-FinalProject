import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/utils/api'

export const useAuthStore = defineStore('auth', () => {
  const user    = ref(null)
  const profile = ref(null)
  const photos  = ref([])
  const interests = ref([])

  const isLoggedIn = computed(() => !!user.value)

  async function fetchMe() {
    try {
      const { data } = await api.get('/auth/me')
      user.value      = data.user
      profile.value   = data.profile
      photos.value    = data.photos || []
      interests.value = data.interests || []
      return true
    } catch {
      user.value = null
      return false
    }
  }

  async function login(credentials) {
    const { data } = await api.post('/auth/login', credentials)
    user.value    = data.user
    profile.value = data.profile
    return data
  }

  async function register(payload) {
    const { data } = await api.post('/auth/register', payload)
    user.value    = data.user
    profile.value = data.profile
    return data
  }

  async function logout() {
    await api.post('/auth/logout')
    user.value    = null
    profile.value = null
    photos.value  = []
    interests.value = []
  }

  async function updateProfile(payload) {
    const { data } = await api.put(`/users/${user.value.user_id}`, payload)
    user.value      = data.user
    profile.value   = data.profile
    interests.value = data.interests || []
    return data
  }

  return { user, profile, photos, interests, isLoggedIn, fetchMe, login, register, logout, updateProfile }
})
