<template>
  <div class="container" style="padding-top:32px; padding-bottom:60px;">
    <div class="flex items-center justify-between mb-3">
      <h1 style="font-size:1.8rem; font-weight:800;">
        Notifications
        <span v-if="unreadCount > 0" class="unread-badge">{{ unreadCount }}</span>
      </h1>
      <button v-if="unreadCount > 0" class="btn btn-outline btn-sm" @click="markAllRead">
        ✓ Mark all read
      </button>
    </div>

    <div v-if="loading" class="text-center" style="padding:60px;">
      <div class="spinner" style="width:40px;height:40px;border-width:4px;margin:0 auto;"></div>
    </div>

    <div v-else-if="notifications.length === 0" class="empty-state">
      <div style="font-size:3.5rem;">🔔</div>
      <h2>No notifications yet</h2>
      <p class="text-muted">When you get matches, messages or likes, they'll appear here.</p>
    </div>

    <div v-else class="notif-list">
      <div
        v-for="n in notifications"
        :key="n.notification_id"
        class="notif-item"
        :class="{ unread: !n.is_read }"
        @click="handleNotifClick(n)"
      >
        <div class="notif-icon">{{ typeIcon(n.type) }}</div>
        <div class="notif-body">
          <div class="notif-message">{{ n.message }}</div>
          <div class="notif-time text-muted">{{ formatTime(n.created_at) }}</div>
        </div>
        <div v-if="!n.is_read" class="notif-dot"></div>
      </div>
    </div>

    <div v-if="totalPages > 1" class="text-center mt-3">
      <button class="btn btn-outline btn-sm" @click="loadMore" :disabled="loadingMore || page >= totalPages">
        <span v-if="loadingMore" class="spinner"></span>
        {{ loadingMore ? 'Loading…' : 'Load more' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/utils/api'

const router        = useRouter()
const notifications = ref([])
const loading       = ref(true)
const loadingMore   = ref(false)
const page          = ref(1)
const totalPages    = ref(1)
const unreadCount   = computed(() => notifications.value.filter(n => !n.is_read).length)

function typeIcon(type) {
  return { match: '💕', message: '💬', like: '❤️', favorite: '⭐' }[type] || '🔔'
}

function formatTime(iso) {
  if (!iso) return ''
  const d = new Date(iso)
  const now = new Date()
  const diffMs = now - d
  const diffMins = Math.floor(diffMs / 60000)
  if (diffMins < 1)  return 'Just now'
  if (diffMins < 60) return `${diffMins}m ago`
  const diffHrs = Math.floor(diffMins / 60)
  if (diffHrs < 24)  return `${diffHrs}h ago`
  const diffDays = Math.floor(diffHrs / 24)
  if (diffDays < 7)  return `${diffDays}d ago`
  return d.toLocaleDateString('en-JM', { month: 'short', day: 'numeric' })
}

async function handleNotifClick(n) {
  if (!n.is_read) {
    await api.put(`/notifications/${n.notification_id}/read`)
    n.is_read = true
  }
  if (n.type === 'match')                    router.push('/matches')
  else if (n.type === 'message')             router.push('/messages')
  else if (n.type === 'like')                router.push('/discover')
  else if (n.type === 'favorite')            router.push('/favorites')
}

async function markAllRead() {
  await api.put('/notifications/read-all')
  notifications.value.forEach(n => n.is_read = true)
}

async function fetchNotifications(p = 1, append = false) {
  const { data } = await api.get(`/notifications?page=${p}`)
  if (append) notifications.value.push(...data.notifications)
  else        notifications.value = data.notifications
  totalPages.value = Math.ceil(data.total / 30)
  page.value = p
}

async function loadMore() {
  loadingMore.value = true
  try { await fetchNotifications(page.value + 1, true) }
  finally { loadingMore.value = false }
}

onMounted(async () => {
  try { await fetchNotifications() }
  finally { loading.value = false }
})
</script>

<style scoped>
.unread-badge {
  background: #e91e8c; color: #fff;
  border-radius: 20px; padding: 2px 10px;
  font-size: 0.9rem; vertical-align: middle; margin-left: 8px;
}
.notif-list {
  background: #fff; border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.08); overflow: hidden;
}
.notif-item {
  display: flex; align-items: center; gap: 14px;
  padding: 16px 20px; border-bottom: 1px solid #f0f0f0;
  cursor: pointer; transition: background 0.2s; position: relative;
}
.notif-item:last-child { border-bottom: none; }
.notif-item:hover      { background: #fafafa; }
.notif-item.unread     { background: #fff0f5; }
.notif-icon {
  font-size: 1.4rem; flex-shrink: 0; width: 44px; height: 44px;
  background: #fce4ec; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
}
.notif-body    { flex: 1; min-width: 0; }
.notif-message { font-size: 0.95rem; font-weight: 500; line-height: 1.4; }
.notif-item.unread .notif-message { font-weight: 700; }
.notif-time    { font-size: 0.78rem; margin-top: 3px; }
.notif-dot {
  width: 10px; height: 10px; border-radius: 50%;
  background: #e91e8c; flex-shrink: 0;
}
.empty-state   { text-align: center; padding: 80px 20px; }
.empty-state h2 { font-size: 1.5rem; font-weight: 700; margin: 12px 0; }
</style>
