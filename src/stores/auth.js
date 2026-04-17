import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { MOCK_USERS } from '@/data/mockData'

export const useAuthStore = defineStore('auth', () => {
  // ── State ──────────────────────────────────────────────────────────────
  const currentUser = ref(JSON.parse(localStorage.getItem('dd_user') || 'null'))
  const error = ref(null)
  const loading = ref(false)

  // ── Getters ────────────────────────────────────────────────────────────
  const isLoggedIn = computed(() => !!currentUser.value)

  // ── Helpers ────────────────────────────────────────────────────────────

  /** Load the full user registry from localStorage, seeded with mock data */
  function getRegistry() {
    const stored = localStorage.getItem('dd_registry')
    if (!stored) {
      // Seed with mock users on first run
      const seed = {}
      MOCK_USERS.forEach(u => { seed[u.email] = u })
      localStorage.setItem('dd_registry', JSON.stringify(seed))
      return seed
    }
    return JSON.parse(stored)
  }

  function saveRegistry(registry) {
    localStorage.setItem('dd_registry', JSON.stringify(registry))
  }

  /** Persist the active session */
  function persistSession(user) {
    currentUser.value = user
    localStorage.setItem('dd_user', JSON.stringify(user))
  }

  // ── Actions ────────────────────────────────────────────────────────────

  /**
   * Register a new user.
   * In production: POST /api/users/register
   */
  async function register(formData) {
    error.value = null
    loading.value = true
    try {
      const registry = getRegistry()
      if (registry[formData.email]) {
        throw new Error('An account with this email already exists.')
      }
      const newUser = {
        id: `u_${Date.now()}`,
        email: formData.email,
        password: `hashed_${formData.password}`, // placeholder — backend uses bcrypt
        name: formData.name,
        age: Number(formData.age),
        bio: '',
        location: { city: '', lat: 0, lng: 0 },
        interests: [],
        profilePicture: null,
        isPublic: true,
        occupation: '',
        lookingFor: '',
        agePreference: { min: 18, max: 60 },
        maxDistanceKm: 50,
        createdAt: new Date().toISOString(),
        profileComplete: false,
      }
      registry[newUser.email] = newUser
      saveRegistry(registry)
      persistSession(newUser)
      return { success: true }
    } catch (err) {
      error.value = err.message
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }

  /**
   * Log in an existing user.
   * In production: POST /api/auth/login
   */
  async function login(email, password) {
    error.value = null
    loading.value = true
    try {
      const registry = getRegistry()
      const user = registry[email]
      if (!user) throw new Error('No account found with this email.')
      // Mock password check (production uses bcrypt.compare on server)
      if (user.password !== `hashed_${password}` && user.password !== 'hashed_placeholder') {
        throw new Error('Incorrect password.')
      }
      persistSession(user)
      return { success: true }
    } catch (err) {
      error.value = err.message
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }

  /** Log out and clear session */
  function logout() {
    currentUser.value = null
    localStorage.removeItem('dd_user')
  }

  /**
   * Update the current user's profile.
   * In production: PUT /api/users/:id
   */
  async function updateProfile(updates) {
    error.value = null
    loading.value = true
    try {
      const registry = getRegistry()
      const updated = { ...currentUser.value, ...updates, profileComplete: true }
      registry[updated.email] = updated
      saveRegistry(registry)
      persistSession(updated)
      return { success: true }
    } catch (err) {
      error.value = err.message
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }

  /** Get all public users (excluding self) — for matching */
  function getAllUsers() {
    const registry = getRegistry()
    return Object.values(registry).filter(
      u => u.id !== currentUser.value?.id && u.isPublic
    )
  }

  return {
    currentUser, error, loading, isLoggedIn,
    register, login, logout, updateProfile, getAllUsers,
  }
})