/**
 * router/index.js
 *
 * IMPORTANT: /profile/edit MUST be defined before /profile/:userId.
 * Vue Router matches routes top-to-bottom. If :userId comes first,
 * navigating to /profile/edit will treat "edit" as the userId param
 * and try to load a profile instead of the edit form.
 */

import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    // ── Public ────────────────────────────────────────────────────────────
    {
      path: '/',
      name: 'home',
      component: () => import('@/views/HomeView.vue'),
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { guest: true },
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('@/views/RegisterView.vue'),
      meta: { guest: true },
    },

    // ── Authenticated ─────────────────────────────────────────────────────
    {
      path: '/setup-profile',
      name: 'setup-profile',
      component: () => import('@/views/SetupProfileView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/discover',
      name: 'discover',
      component: () => import('@/views/DiscoverView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/matches',
      name: 'matches',
      component: () => import('@/views/MatchesView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/messages',
      name: 'messages',
      component: () => import('@/views/MessagesView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/messages/:conversationId',
      name: 'conversation',
      component: () => import('@/views/ConversationView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/favorites',
      name: 'favorites',
      component: () => import('@/views/FavoritesView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/search',
      name: 'search',
      component: () => import('@/views/SearchView.vue'),
      meta: { requiresAuth: true },
    },

    // ── Profile routes — static path /profile/edit BEFORE dynamic /profile/:userId ──
    {
      path: '/profile/edit',
      name: 'edit-profile',
      component: () => import('@/views/EditProfileView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/profile/:userId',
      name: 'profile',
      component: () => import('@/views/ProfileView.vue'),
      meta: { requiresAuth: true },
    },
  ],
})

// Global navigation guard
router.beforeEach((to, from, next) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.token) {
    next({ name: 'login' })
  } else if (to.meta.guest && auth.token) {
    next({ name: 'discover' })
  } else {
    next()
  }
})

export default router