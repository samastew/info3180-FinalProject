import { ref, watch } from 'vue' // CHANGED: ref replaces computed (async can't use computed); watch added to re-run on filter changes
import { useAuthStore } from '@/stores/auth'
import { useMatchStore } from '@/stores/matches'

/**
 * Matching algorithm:
 *  1. Location proximity  — haversine distance ≤ user's maxDistanceKm
 *  2. Age range           — candidate age within current user's agePreference
 *  3. Shared interests    — at least 1 shared interest
 *  4. Looking for         — same relationship goal (bonus, not a hard filter)
 *
 * Each criterion contributes to a score; candidates are sorted by score desc.
 */

function haversineKm(lat1, lng1, lat2, lng2) {
  const R = 6371
  const dLat = ((lat2 - lat1) * Math.PI) / 180
  const dLng = ((lng2 - lng1) * Math.PI) / 180
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

export function useMatching(filterOptions = {}) {
  const authStore = useAuthStore()
  const matchStore = useMatchStore()

  const scoredCandidates = ref([]) // CHANGED: was computed(() => { ... }), now a ref populated by async loadCandidates()

  // CHANGED: scoring logic extracted into this function so loadCandidates() can call it after fetching users
  // Every line inside is identical to the original computed body
  function scoreUsers(allUsers) {
    const me = authStore.currentUser
    if (!me) return []

    const dismissed = matchStore.dismissedIds.value ?? []

    const {
      maxDistanceKm = me.maxDistanceKm ?? 50,
      minAge = me.agePreference?.min ?? 18,
      maxAge = me.agePreference?.max ?? 60,
      interests: filterInterests = [],
      lookingFor: filterLookingFor = '',
    } = filterOptions

    return allUsers
      .filter(u => !dismissed.includes(u.id)) // exclude already dismissed
      .map(u => {
        let score = 0
        const reasons = []

        // 1. Location proximity
        if (me.location?.lat && u.location?.lat) {
          const dist = haversineKm(
            me.location.lat, me.location.lng,
            u.location.lat, u.location.lng
          )
          if (dist <= maxDistanceKm) {
            score += 30
            reasons.push(`${Math.round(dist)} km away`)
          } else {
            return null // hard filter: too far
          }
        } else {
          score += 10 // no location data, give partial credit
        }

        // 2. Age range filter
        if (u.age < minAge || u.age > maxAge) return null
        score += 20

        // 3. Shared interests
        const sharedInterests = (me.interests || []).filter(i =>
          (u.interests || []).includes(i)
        )
        if (sharedInterests.length === 0) return null // hard filter: no shared interest
        score += Math.min(sharedInterests.length * 10, 30)
        reasons.push(`${sharedInterests.length} shared interest${sharedInterests.length > 1 ? 's' : ''}`)

        // 4. Looking for (soft criterion)
        if (me.lookingFor && u.lookingFor && me.lookingFor === u.lookingFor) {
          score += 20
          reasons.push('Same relationship goal')
        }

        // Additional interest filters from browse panel
        if (filterInterests.length > 0) {
          const hasAll = filterInterests.every(i => u.interests?.includes(i))
          if (!hasAll) return null
        }

        if (filterLookingFor && u.lookingFor !== filterLookingFor) return null

        return { user: u, score, reasons, sharedInterests }
      })
      .filter(Boolean)
      .sort((a, b) => b.score - a.score)
  }

  // NEW: fetches users from Flask API, normalizes snake_case to camelCase, then scores them.
  // Falls back to localStorage if API is unavailable so the app still works for teammates.
  async function loadCandidates() {
    try {
      const params = new URLSearchParams()
      if (filterOptions.minAge)            params.set('min_age', filterOptions.minAge)
      if (filterOptions.maxAge)            params.set('max_age', filterOptions.maxAge)
      if (filterOptions.interests?.length) params.set('interests', filterOptions.interests.join(','))
      if (filterOptions.lookingFor)        params.set('looking_for', filterOptions.lookingFor)
      if (filterOptions.maxDistanceKm)     params.set('max_distance_km', filterOptions.maxDistanceKm)

      const me = authStore.currentUser
      if (me?.location?.lat) {
        params.set('lat', me.location.lat)
        params.set('lng', me.location.lng)
      }

      const res = await fetch(`http://localhost:5000/api/search?${params}`)
      if (!res.ok) throw new Error('Search failed')
      const data = await res.json()

      // Normalize API response (snake_case) to camelCase so scoreUsers() works unchanged
      const normalized = data.users.map(u => ({
        id:             u.id,
        name:           u.name,
        age:            u.age,
        bio:            u.bio,
        occupation:     u.occupation,
        interests:      u.interests,
        profilePicture: u.profile_picture,
        lookingFor:     u.looking_for,
        location:       u.latitude ? { city: u.city, lat: u.latitude, lng: u.longitude } : null,
        maxDistanceKm:  u.max_distance_km,
        isPublic:       u.is_public,
      }))

      scoredCandidates.value = scoreUsers(normalized)
    } catch (err) {
      // Fallback to localStorage if API is unavailable
      console.warn('API unavailable, falling back to localStorage:', err.message)
      const allUsers = authStore.getAllUsers()
      scoredCandidates.value = scoreUsers(allUsers)
    }
  }

  loadCandidates() // run on mount
  watch(() => filterOptions, loadCandidates, { deep: true }) // re-run when filters change

  return { scoredCandidates }
}