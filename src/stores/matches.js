import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useAuthStore } from './auth'

export const useMatchStore = defineStore('matches', () => {
  const authStore = useAuthStore()

  // ── State ──────────────────────────────────────────────────────────────

  /** likes[myId][theirId] = true/false/'pass' */
  const interactions = ref(JSON.parse(localStorage.getItem('dd_interactions') || '{}'))
  const notifications = ref([])

  // ── Helpers ────────────────────────────────────────────────────────────

  function myId() {
    return authStore.currentUser?.id
  }

  function saveInteractions() {
    localStorage.setItem('dd_interactions', JSON.stringify(interactions.value))
  }

  function myInteractions() {
    return interactions.value[myId()] || {}
  }

  // ── Getters ────────────────────────────────────────────────────────────

  /** Users I have liked */
  const likedIds = computed(() =>
    Object.entries(myInteractions())
      .filter(([, v]) => v === 'like')
      .map(([k]) => k)
  )

  /** Users I have passed or disliked */
  const dismissedIds = computed(() =>
    Object.entries(myInteractions())
      .filter(([, v]) => v === 'dislike' || v === 'pass')
      .map(([k]) => k)
  )

  /** Mutual matches — both users liked each other */
  const mutualMatchIds = computed(() => {
    const all = interactions.value
    return likedIds.value.filter(otherId => {
      return all[otherId]?.[myId()] === 'like'
    })
  })

  // ── Actions ────────────────────────────────────────────────────────────

  /** Record a like/dislike/pass interaction */
  function interact(targetId, action) {
    const id = myId()
    if (!id) return
    if (!interactions.value[id]) interactions.value[id] = {}
    interactions.value[id][targetId] = action
    saveInteractions()

    // Check for mutual match after a like
    if (action === 'like') {
      const theyLikedMe = interactions.value[targetId]?.[id] === 'like'
      if (theyLikedMe) {
        notifications.value.push({
          id: `notif_${Date.now()}`,
          type: 'mutual_match',
          targetId,
          message: "It's a match!",
          timestamp: new Date().toISOString(),
          read: false,
        })
      }
    }
  }

  function dismissNotification(notifId) {
    notifications.value = notifications.value.filter(n => n.id !== notifId)
  }

  function getInteraction(targetId) {
    return myInteractions()[targetId] || null
  }

  return {
    interactions, notifications,
    likedIds, dismissedIds, mutualMatchIds,
    interact, dismissNotification, getInteraction,
  }
})