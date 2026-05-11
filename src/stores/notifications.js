import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/utils/api'

export const useNotificationsStore = defineStore('notifications', () => {
  const notifications = ref([])
  const unreadCount   = computed(() => notifications.value.filter(n => !n.is_read).length)

  async function fetch() {
    try {
      const { data } = await api.get('/notifications?page=1')
      notifications.value = data.notifications
    } catch {}
  }

  async function markRead(id) {
    await api.put(`/notifications/${id}/read`)
    const n = notifications.value.find(x => x.notification_id === id)
    if (n) n.is_read = true
  }

  async function markAllRead() {
    await api.put('/notifications/read-all')
    notifications.value.forEach(n => n.is_read = true)
  }

  return { notifications, unreadCount, fetch, markRead, markAllRead }
})
