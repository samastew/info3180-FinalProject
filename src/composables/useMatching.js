import { computed } from 'vue'
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

  const scoredCandidates = computed(() => {
    const me = authStore.currentUser
    if (!me) return []

    const allUsers = authStore.getAllUsers()
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
  })

  return { scoredCandidates }
}