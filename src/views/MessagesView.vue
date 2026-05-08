<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/services/api'

const router        = useRouter()
const conversations = ref([])
const loading       = ref(true)

onMounted(async () => {
  try {
    const res = await api.get('/conversations')
    conversations.value = res.data.conversations
  } catch {}
  loading.value = false
})

function openConversation(id) {
  router.push({ name: 'conversation', params: { conversationId: id } })
}

function formatTime(iso) {
  if (!iso) return ''
  const d = new Date(iso)
  const now = new Date()
  const diff = now - d
  if (diff < 60000) return 'just now'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`
  return d.toLocaleDateString('en-JM', { month: 'short', day: 'numeric' })
}
</script>

<template>
  <div class="messages-page">
    <div class="messages-inner">
      <h1 class="section-title">Messages</h1>
      <p class="section-sub">Your conversations with matches</p>

      <div v-if="loading" style="text-align:center;padding:80px 0">
        <div class="spinner"></div>
      </div>

      <div v-else-if="!conversations.length" class="empty-state">
        <div class="empty-icon">💬</div>
        <h2>No messages yet</h2>
        <p>Match with someone and start a conversation!</p>
        <RouterLink to="/discover" class="btn btn-primary">Discover People</RouterLink>
      </div>

      <div v-else class="convo-list">
        <div
          v-for="convo in conversations"
          :key="convo.conversation_id"
          class="convo-item"
          @click="openConversation(convo.conversation_id)"
        >
          <div class="convo-avatar">
            <img v-if="convo.other_photo" :src="convo.other_photo" :alt="convo.other_name" />
            <span v-else>{{ convo.other_name?.[0]?.toUpperCase() }}</span>
          </div>
          <div class="convo-body">
            <div class="convo-top">
              <strong class="convo-name">{{ convo.other_name }}</strong>
              <span class="convo-time">{{ formatTime(convo.last_message_at) }}</span>
            </div>
            <p class="convo-preview">{{ convo.last_message || 'No messages yet — say hello!' }}</p>
          </div>
          <div v-if="convo.unread_count" class="unread-badge">{{ convo.unread_count }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.messages-page {
  min-height: calc(100vh - var(--nav-height));
  background: var(--nude); padding: 40px 24px;
}
.messages-inner { max-width: 720px; margin: 0 auto; }

.empty-state { text-align: center; padding: 80px 24px; }
.empty-icon { font-size: 64px; margin-bottom: 16px; }
.empty-state h2 { font-family: var(--font-display); font-size: 28px; margin-bottom: 8px; }
.empty-state p { color: var(--mist); margin-bottom: 24px; }

.convo-list {
  background: white; border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm); overflow: hidden;
}
.convo-item {
  display: flex; align-items: center; gap: 16px;
  padding: 18px 24px; cursor: pointer; transition: background 0.15s;
  border-bottom: 1px solid #F3F4F6; position: relative;
}
.convo-item:last-child { border-bottom: none; }
.convo-item:hover { background: var(--nude); }

.convo-avatar {
  width: 52px; height: 52px; border-radius: 50%; overflow: hidden; flex-shrink: 0;
  background: var(--blush); display: flex; align-items: center; justify-content: center;
  color: var(--coral); font-weight: 700; font-size: 20px;
}
.convo-avatar img { width: 100%; height: 100%; object-fit: cover; }

.convo-body { flex: 1; min-width: 0; }
.convo-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px; }
.convo-name { font-size: 16px; color: var(--ink); }
.convo-time { font-size: 12px; color: var(--mist); }
.convo-preview {
  font-size: 14px; color: var(--mist); white-space: nowrap;
  overflow: hidden; text-overflow: ellipsis;
}

.unread-badge {
  width: 22px; height: 22px; border-radius: 50%;
  background: var(--coral); color: white;
  font-size: 12px; font-weight: 700;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
</style>
