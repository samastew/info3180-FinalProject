import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
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
      meta: { requiresAuth: true },
    },
    {
      path: '/discover',
      name: 'discover',
      component: () => import('../views/DiscoverView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/matches',
      name: 'matches',
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
})

export default router