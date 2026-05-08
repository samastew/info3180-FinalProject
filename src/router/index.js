<<<<<<< Updated upstream
import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
=======
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
>>>>>>> Stashed changes

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
<<<<<<< Updated upstream
    { path: '/',          name: 'home',     component: HomeView },
    { path: '/login',     name: 'login',    component: () => import('../views/LoginView.vue') },
    { path: '/register',  name: 'register', component: () => import('../views/RegisterView.vue') },
    {
      path: '/profile',
      name: 'profile',
      component: () => import('../views/ProfileView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/profile/edit',
      name: 'profile-edit',
      component: () => import('../views/ProfileView.vue'),
      props: { isNew: true },
=======
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
>>>>>>> Stashed changes
      meta: { requiresAuth: true },
    },
    {
      path: '/discover',
      name: 'discover',
<<<<<<< Updated upstream
      component: () => import('../views/DiscoverView.vue'),
=======
      component: () => import('@/views/DiscoverView.vue'),
>>>>>>> Stashed changes
      meta: { requiresAuth: true },
    },
    {
      path: '/matches',
      name: 'matches',
<<<<<<< Updated upstream
      component: () => import('../views/MatchesView.vue'),
      meta: { requiresAuth: true },
    },
    { path: '/about', name: 'about', component: () => import('../views/AboutView.vue') },
  ],
})

// Navigation guard — redirect unauthenticated users to /login
router.beforeEach((to, from, next) => {
  if (to.meta.requiresAuth) {
    const user = JSON.parse(localStorage.getItem('dd_user') || 'null')
    if (!user) return next('/login')
  }
  next()
=======
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
>>>>>>> Stashed changes
})

export default router