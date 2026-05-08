<script setup>
import { ref, onMounted, nextTick, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'

const route   = useRoute()
const router  = useRouter()
const auth    = useAuthStore()
const convId  = route.params.conversationId

const messages  = ref([])
const newMsg    = ref('')
const loading   = ref(true)
const sending   = ref(false)
const msgEnd    = ref(null)
const otherName = ref('')
const otherPhoto= ref(null)

onMounted(async () => {
  // Get conversation info from conversations list
  try {
    const res = await api.get('/conversations')
    const convo = res.data.conversations.find(c => c.conversation_id == convId)
    if (convo) {
      otherName.value  = convo.other_name
      otherPhoto.value = convo.other_photo
    }
  } catch {}

  await fetchMessages()
})

async function fetchMessages() {
  loading.value = true
  try {
    const res = await api.get(`/conversations/${convId}/messages`)
    messages.value = res.data.messages
  } catch {}
  loading.value = false
  await nextTick()
  scrollToBottom()
}

async function sendMessage() {
  const body = newMsg.value.trim()
  if (!body || sending.value) return
  sending.value = true
  try {
    const res = await api.post(`/conversations/${convId}/messages`, { body })
    messages.value.push(res.data.data)
    newMsg.value = ''
    await nextTick()
    scrollToBottom()
  } catch {}
  sending.value = false
}

function scrollToBottom() {
  msgEnd.value?.scrollIntoView({ behavior: 'smooth' })
}

function formatTime(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleTimeString('en-JM', { hour: '2-digit', minute: '2-digit' })
}

function formatDate(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString('en-JM', { weekday: 'short', month: 'short', day: 'numeric' })
}

function isMine(msg) {
  return msg.sender_id === auth.currentUserId
}

function initials(name) {
  return name?.split(' ').map(n => n[0]).join('').toUpperCase() || '?'
}
</script>

<template>
  <div class="chat-page">
    <!-- Header -->
    <div class="chat-header">
      <button class="back-btn" @click="router.push({ name: 'messages' })">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>
      </button>
      <div class="chat-avatar">
        <img v-if="otherPhoto" :src="otherPhoto" :alt="otherName" />
        <span v-else>{{ initials(otherName) }}</span>
      </div>
      <div class="chat-header-info">
        <strong>{{ otherName }}</strong>
        <span class="online-dot"></span>
      </div>
    </div>

    <!-- Messages area -->
    <div class="chat-messages">
      <div v-if="loading" style="text-align:center;padding:40px">
        <div class="spinner"></div>
      </div>

      <div v-else-if="!messages.length" class="chat-empty">
        <div class="chat-empty-icon">👋</div>
        <p>Say hello to {{ otherName }}!</p>
      </div>

      <template v-else>
        <div v-for="(msg, idx) in messages" :key="msg.message_id">
          <!-- Date separator -->
          <div v-if="idx === 0 || formatDate(messages[idx-1].sent_at) !== formatDate(msg.sent_at)" class="date-sep">
            {{ formatDate(msg.sent_at) }}
          </div>

          <div class="msg-row" :class="{ mine: isMine(msg) }">
            <div v-if="!isMine(msg)" class="msg-avatar">
              <img v-if="otherPhoto" :src="otherPhoto" :alt="otherName" />
              <span v-else>{{ initials(otherName) }}</span>
            </div>
            <div class="bubble-wrap">
              <div class="bubble" :class="{ mine: isMine(msg) }">
                {{ msg.body }}
              </div>
              <span class="msg-time">{{ formatTime(msg.sent_at) }}</span>
            </div>
          </div>
        </div>
      </template>

      <div ref="msgEnd"></div>
    </div>

    <!-- Input area -->
    <div class="chat-input-area">
      <div class="chat-input-row">
        <textarea
          v-model="newMsg"
          class="chat-input"
          placeholder="Type a message…"
          rows="1"
          @keydown.enter.exact.prevent="sendMessage"
        ></textarea>
        <button class="send-btn" :disabled="!newMsg.trim() || sending" @click="sendMessage">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.chat-page {
  height: calc(100vh - var(--nav-height));
  display: flex; flex-direction: column;
  background: var(--nude); max-width: 800px; margin: 0 auto;
}

.chat-header {
  display: flex; align-items: center; gap: 12px;
  padding: 16px 20px; background: white;
  border-bottom: 1px solid #F3F4F6; flex-shrink: 0;
}
.back-btn {
  width: 36px; height: 36px; border-radius: 50%; border: none;
  background: var(--nude); cursor: pointer; display: flex; align-items: center; justify-content: center;
  color: var(--slate); transition: background 0.2s;
}
.back-btn:hover { background: var(--blush); }
.chat-avatar {
  width: 44px; height: 44px; border-radius: 50%; overflow: hidden;
  background: var(--blush); display: flex; align-items: center; justify-content: center;
  color: var(--coral); font-weight: 700; flex-shrink: 0;
}
.chat-avatar img { width: 100%; height: 100%; object-fit: cover; }
.chat-header-info strong { display: block; font-size: 16px; color: var(--ink); }
.online-dot {
  display: inline-block; width: 8px; height: 8px; border-radius: 50%;
  background: var(--mint); margin-top: 2px;
}

.chat-messages {
  flex: 1; overflow-y: auto; padding: 20px;
  display: flex; flex-direction: column; gap: 4px;
}
.chat-empty { text-align: center; padding: 60px; color: var(--mist); }
.chat-empty-icon { font-size: 48px; margin-bottom: 12px; }

.date-sep {
  text-align: center; font-size: 12px; color: var(--mist); font-weight: 600;
  margin: 16px 0 8px; position: relative;
}
.date-sep::before, .date-sep::after {
  content: ''; position: absolute; top: 50%; width: calc(50% - 60px);
  height: 1px; background: #E5E7EB;
}
.date-sep::before { left: 0; }
.date-sep::after { right: 0; }

.msg-row {
  display: flex; align-items: flex-end; gap: 8px; margin-bottom: 4px;
}
.msg-row.mine { flex-direction: row-reverse; }

.msg-avatar {
  width: 32px; height: 32px; border-radius: 50%; overflow: hidden; flex-shrink: 0;
  background: var(--blush); display: flex; align-items: center; justify-content: center;
  color: var(--coral); font-size: 12px; font-weight: 700;
}
.msg-avatar img { width: 100%; height: 100%; object-fit: cover; }

.bubble-wrap { display: flex; flex-direction: column; gap: 2px; max-width: 70%; }
.msg-row.mine .bubble-wrap { align-items: flex-end; }

.bubble {
  padding: 10px 16px; border-radius: 18px; font-size: 15px; line-height: 1.5;
  background: white; color: var(--ink); box-shadow: var(--shadow-sm);
  border-bottom-left-radius: 4px;
}
.bubble.mine {
  background: linear-gradient(135deg, var(--coral), #FF4E4E);
  color: white; box-shadow: 0 4px 12px rgba(255,107,107,0.3);
  border-bottom-left-radius: 18px; border-bottom-right-radius: 4px;
}
.msg-time { font-size: 11px; color: var(--mist); padding: 0 4px; }

.chat-input-area {
  padding: 16px 20px; background: white;
  border-top: 1px solid #F3F4F6; flex-shrink: 0;
}
.chat-input-row { display: flex; gap: 12px; align-items: flex-end; }
.chat-input {
  flex: 1; padding: 12px 16px; border-radius: 24px;
  border: 2px solid #E5E7EB; font-family: var(--font-body); font-size: 15px;
  color: var(--ink); resize: none; outline: none; max-height: 120px;
  transition: border-color 0.2s;
}
.chat-input:focus { border-color: var(--coral); }
.send-btn {
  width: 44px; height: 44px; border-radius: 50%; border: none;
  background: linear-gradient(135deg, var(--coral), #FF4E4E);
  color: white; cursor: pointer; display: flex; align-items: center; justify-content: center;
  box-shadow: 0 4px 12px rgba(255,107,107,0.35); transition: all 0.2s; flex-shrink: 0;
}
.send-btn:hover:not(:disabled) { transform: scale(1.05); }
.send-btn:disabled { opacity: 0.4; cursor: not-allowed; }
</style>
