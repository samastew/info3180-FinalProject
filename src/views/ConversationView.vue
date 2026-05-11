<template>
  <div class="conversation-page">
    <!-- Header -->
    <div class="convo-header">
      <RouterLink to="/messages" class="back-btn">← Back</RouterLink>
      <div class="convo-peer" v-if="convoMeta">
        <img :src="getPhoto(convoMeta.other_user)" :alt="peerName" @error="onImgErr" />
        <div>
          <div class="peer-name">{{ peerName }}</div>
          <div class="peer-sub text-muted">{{ peerSub }}</div>
        </div>
      </div>
      <div style="width:60px;"></div>
    </div>

    <!-- Messages -->
    <div class="messages-area" ref="scrollEl">
      <div v-if="loading" class="text-center" style="padding:40px;">
        <div class="spinner" style="width:32px;height:32px;border-width:3px;margin:0 auto;"></div>
      </div>

      <div v-else>
        <div v-if="page < totalPages" class="text-center" style="margin-bottom:12px;">
          <button class="btn btn-outline btn-sm" @click="loadOlder" :disabled="loadingOlder">
            {{ loadingOlder ? '…' : 'Load older messages' }}
          </button>
        </div>

        <div v-for="msg in messages" :key="msg.message_id"
          class="msg-row"
          :class="{ mine: msg.sender_id === myId }">
          <div class="bubble">
            <div class="bubble-body">{{ msg.body }}</div>
            <div class="bubble-time">{{ formatTime(msg.sent_at) }}</div>
          </div>
        </div>

        <div v-if="messages.length === 0" class="text-center text-muted" style="padding:40px 20px;">
          No messages yet. Say hello! 👋
        </div>
      </div>
    </div>

    <!-- Input -->
    <div class="message-input">
      <textarea
        v-model="newMessage"
        class="form-control"
        placeholder="Type a message…"
        rows="1"
        style="resize:none; border-radius:24px;"
        @keydown.enter.exact.prevent="sendMessage"
        @input="autoGrow"
        ref="inputEl"
      ></textarea>
      <button class="send-btn" @click="sendMessage" :disabled="!newMessage.trim() || sending">
        <span v-if="sending" class="spinner"></span>
        <span v-else>➤</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/utils/api'

const route    = useRoute()
const auth     = useAuthStore()
const convoId  = computed(() => Number(route.params.convoId))
const myId     = computed(() => auth.user?.user_id)

const messages    = ref([])
const convoMeta   = ref(null)
const loading     = ref(true)
const loadingOlder = ref(false)
const sending     = ref(false)
const newMessage  = ref('')
const page        = ref(1)
const totalPages  = ref(1)
const scrollEl    = ref(null)
const inputEl     = ref(null)

const peerName = computed(() => {
  const p = convoMeta.value?.other_profile
  const u = convoMeta.value?.other_user
  if (p?.first_name) return `${p.first_name} ${p.last_name}`
  return u?.username || 'User'
})

const peerSub = computed(() => {
  const p = convoMeta.value?.other_profile
  if (p?.city) return `📍 ${p.city}`
  return ''
})

function getPhoto(user) {
  if (!user) return null
  return user.photo || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.username || '?')}&background=e91e8c&color=fff&size=80`
}
function onImgErr(e) { e.target.src = 'https://ui-avatars.com/api/?name=?&background=e91e8c&color=fff&size=80' }

function formatTime(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleTimeString('en-JM', { hour: '2-digit', minute: '2-digit' })
}

async function fetchMessages(p = 1, prepend = false) {
  const { data } = await api.get(`/conversations/${convoId.value}/messages?page=${p}&limit=50`)
  if (prepend) messages.value = [...data.messages, ...messages.value]
  else         messages.value = data.messages
  totalPages.value = data.pages
  page.value = p
}

async function loadOlder() {
  loadingOlder.value = true
  const scrollBefore = scrollEl.value?.scrollHeight || 0
  await fetchMessages(page.value + 1, true)
  loadingOlder.value = false
  await nextTick()
  const added = (scrollEl.value?.scrollHeight || 0) - scrollBefore
  if (scrollEl.value) scrollEl.value.scrollTop = added
}

async function fetchConvoMeta() {
  const { data } = await api.get('/conversations')
  convoMeta.value = data.find(c => c.conversation_id === convoId.value) || null
}

async function sendMessage() {
  const body = newMessage.value.trim()
  if (!body || sending.value) return
  sending.value = true
  try {
    const { data } = await api.post(`/conversations/${convoId.value}/messages`, { body })
    messages.value.push(data.data)
    newMessage.value = ''
    if (inputEl.value) inputEl.value.style.height = 'auto'
    await nextTick()
    scrollToBottom()
  } finally {
    sending.value = false
  }
}

function scrollToBottom() {
  if (scrollEl.value) scrollEl.value.scrollTop = scrollEl.value.scrollHeight
}

function autoGrow(e) {
  e.target.style.height = 'auto'
  e.target.style.height = Math.min(e.target.scrollHeight, 120) + 'px'
}

// Poll for new messages every 5 seconds
let pollTimer = null

onMounted(async () => {
  try {
    await Promise.all([fetchMessages(), fetchConvoMeta()])
    await nextTick()
    scrollToBottom()
  } finally {
    loading.value = false
  }

  pollTimer = setInterval(async () => {
    if (!document.hidden) {
      const prevLen = messages.value.length
      await fetchMessages()
      if (messages.value.length > prevLen) {
        await nextTick()
        scrollToBottom()
      }
    }
  }, 5000)
})

import { onUnmounted } from 'vue'
onUnmounted(() => clearInterval(pollTimer))
</script>

<style scoped>
.conversation-page {
  display: flex;
  flex-direction: column;
  height: calc(100vh - 70px);
  max-width: 800px;
  margin: 0 auto;
}

.convo-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  background: #fff;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  gap: 12px;
}
.back-btn {
  text-decoration: none;
  color: #e91e8c;
  font-weight: 700;
  width: 60px;
  flex-shrink: 0;
}
.convo-peer {
  display: flex;
  align-items: center;
  gap: 12px;
}
.convo-peer img {
  width: 42px; height: 42px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #e91e8c;
}
.peer-name { font-weight: 700; font-size: 1rem; }
.peer-sub  { font-size: 0.8rem; }

.messages-area {
  flex: 1;
  overflow-y: auto;
  padding: 20px 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.msg-row {
  display: flex;
  justify-content: flex-start;
}
.msg-row.mine { justify-content: flex-end; }

.bubble {
  max-width: 70%;
  background: #f0f0f0;
  border-radius: 18px 18px 18px 4px;
  padding: 10px 14px;
}
.mine .bubble {
  background: linear-gradient(135deg, #e91e8c, #ff6b35);
  color: #fff;
  border-radius: 18px 18px 4px 18px;
}

.bubble-body { font-size: 0.95rem; line-height: 1.5; word-break: break-word; }
.bubble-time { font-size: 0.72rem; opacity: 0.7; margin-top: 4px; text-align: right; }

.message-input {
  display: flex;
  align-items: flex-end;
  gap: 10px;
  padding: 12px 16px;
  background: #fff;
  box-shadow: 0 -2px 8px rgba(0,0,0,0.08);
}
.message-input .form-control { flex: 1; padding: 10px 16px; }

.send-btn {
  width: 46px; height: 46px;
  border-radius: 50%;
  background: linear-gradient(135deg, #e91e8c, #ff6b35);
  color: #fff;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: opacity 0.2s;
}
.send-btn:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
