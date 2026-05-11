import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useAuthStore = defineStore('auth', () => {
  const token   = ref(localStorage.getItem('dd_token') || null)
  const user    = ref(JSON.parse(localStorage.getItem('dd_user') || 'null'))
  const profile = ref(JSON.parse(localStorage.getItem('dd_profile') || 'null'))

  const isLoggedIn     = computed(() => !!token.value)
  const hasProfile     = computed(() => !!profile.value)
  const currentUserId  = computed(() => user.value?.user_id || null)

  function setAuth(data) {
    token.value   = data.token
    user.value    = data.user
    profile.value = data.user?.profile || null
    localStorage.setItem('dd_token', data.token)
    localStorage.setItem('dd_user', JSON.stringify(data.user))
    localStorage.setItem('dd_profile', JSON.stringify(profile.value))
  }

  function setProfile(p) {
    profile.value = p
    localStorage.setItem('dd_profile', JSON.stringify(p))
  }

  function logout() {
    token.value   = null
    user.value    = null
    profile.value = null
    localStorage.removeItem('dd_token')
    localStorage.removeItem('dd_user')
    localStorage.removeItem('dd_profile')
  }

  async function fetchMe() {
    try {
      const res = await api.get('/me')
      user.value = res.data.user
      profile.value = res.data.user?.profile || null
      localStorage.setItem('dd_user', JSON.stringify(user.value))
      localStorage.setItem('dd_profile', JSON.stringify(profile.value))
    } catch (e) {
      // ignore
    }
  }

  return { token, user, profile, isLoggedIn, hasProfile, currentUserId, setAuth, setProfile, logout, fetchMe }
})
