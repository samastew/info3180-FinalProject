<template>
  <div class="container" style="padding-top:32px; padding-bottom:60px;">
    <h1 style="font-size:1.8rem; font-weight:800; margin-bottom:24px;">Messages 💬</h1>

    <div v-if="loading" class="text-center" style="padding:60px;">
      <div class="spinner" style="width:40px;height:40px;border-width:4px;margin:0 auto 16px;"></div>
    </div>

    <div v-else-if="conversations.length === 0" class="empty-state">
      <div style="font-size:4rem;">💬</div>
      <h2>No messages yet</h2>
      <p class="text-muted">Match with someone and start a conversation!</p>
      <RouterLink to="/matches" class="btn btn-primary mt-2">View Matches</RouterLink>
    </div>

    <div v-else class="convo-list">
      <RouterLink
        v-for="convo in conversations"
        :key="convo.conversation_id"
        :to="`/messages/${convo.conversation_id}`"
        class="convo-item"
        :class="{ unread: convo.unread_count > 0 }"
      >
        <div class="convo-avatar">
          <img :src="getPhoto(convo.other_user)" :alt="getName(convo)" @error="onImgErr" />
          <span v-if="convo.unread_count > 0" class="unread-dot">{{ convo.unread_count }}</span>
        </div>
        <div class="convo-details">
          <div class="convo-name">{{ getName(convo) }}</div>
          <div class="convo-preview">
            {{ convo.last_message ? convo.last_message.body : 'Say hello! 👋' }}
          </div>
        </div>
        <div class="convo-time text-muted">
          {{ convo.last_message ? formatTime(convo.last_message.sent_at) : '' }}
        </div>
      </RouterLink>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import api from '@/utils/api'

const conversations = ref([])
const loading       = ref(true)

function getName(c) {
  const p = c.other_profile
  const u = c.other_user
  if (p?.first_name) return `${p.first_name} ${p.last_name}`
  return u?.username || 'Unknown'
}

function getPhoto(user) {
  if (!user) return null
  return user.photo || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.username || '?')}&background=e91e8c&color=fff&size=80`
}

function onImgErr(e) { e.target.src = 'https://ui-avatars.com/api/?name=?&background=e91e8c&color=fff&size=80' }

function formatTime(iso) {
  if (!iso) return ''
  const d = new Date(iso)
  const now = new Date()
  if (d.toDateString() === now.toDateString())
    return d.toLocaleTimeString('en-JM', { hour: '2-digit', minute: '2-digit' })
  return d.toLocaleDateString('en-JM', { month: 'short', day: 'numeric' })
}

onMounted(async () => {
  try {
    const { data } = await api.get('/conversations')
    conversations.value = data
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.convo-list {
  display: flex;
  flex-direction: column;
  gap: 2px;
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.08);
  overflow: hidden;
}

.convo-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 20px;
  text-decoration: none;
  color: inherit;
  transition: background 0.2s;
  border-bottom: 1px solid #f0f0f0;
}
.convo-item:last-child { border-bottom: none; }
.convo-item:hover { background: #fce4ec; }
.convo-item.unread { background: #fff0f5; }

.convo-avatar {
  position: relative;
  flex-shrink: 0;
}
.convo-avatar img {
  width: 54px; height: 54px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #dee2e6;
}
.unread-dot {
  position: absolute;
  top: -2px; right: -2px;
  background: #e91e8c;
  color: #fff;
  border-radius: 50%;
  min-width: 18px; height: 18px;
  font-size: 0.7rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid #fff;
}

.convo-details { flex: 1; min-width: 0; }
.convo-name {
  font-weight: 700;
  font-size: 0.95rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.convo-preview {
  font-size: 0.85rem;
  color: #6c757d;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  margin-top: 2px;
}
.convo-item.unread .convo-preview { color: #212529; font-weight: 500; }
.convo-time { font-size: 0.78rem; flex-shrink: 0; }

.empty-state { text-align: center; padding: 80px 20px; }
.empty-state h2 { font-size: 1.5rem; font-weight: 700; margin: 12px 0; }
</style>
