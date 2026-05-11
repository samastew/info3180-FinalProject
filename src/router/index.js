import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior: () => ({ top: 0 }),
  routes: [
    { path: '/',              name: 'home',          component: () => import('@/views/HomeView.vue') },
    { path: '/about',         name: 'about',         component: () => import('@/views/AboutView.vue') },
    { path: '/register',      name: 'register',      component: () => import('@/views/RegisterView.vue') },
    { path: '/login',         name: 'login',         component: () => import('@/views/LoginView.vue') },
    {
      path: '/discover',      name: 'discover',
      component: () => import('@/views/DiscoverView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/matches',       name: 'matches',
      component: () => import('@/views/MatchesView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/messages',      name: 'messages',
      component: () => import('@/views/MessagesView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/messages/:convoId', name: 'conversation',
      component: () => import('@/views/ConversationView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/profile',       name: 'profile',
      component: () => import('@/views/ProfileView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/profile/edit',  name: 'edit-profile',
      component: () => import('@/views/EditProfileView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/users/:userId', name: 'user-profile',
      component: () => import('@/views/UserProfileView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/search',        name: 'search',
      component: () => import('@/views/SearchView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/favorites',     name: 'favorites',
      component: () => import('@/views/FavoritesView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/notifications', name: 'notifications',
      component: () => import('@/views/NotificationsView.vue'),
      meta: { requiresAuth: true }
    },
    { path: '/:pathMatch(.*)*', redirect: '/' }
  ]
})

router.beforeEach(async (to) => {
  if (!to.meta.requiresAuth) return true
  const auth = useAuthStore()
  if (!auth.isLoggedIn) {
    await auth.fetchMe()
    if (!auth.isLoggedIn) return { name: 'login', query: { redirect: to.fullPath } }
  }
  return true
})

export default router
