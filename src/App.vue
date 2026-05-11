<script setup>
import { RouterView } from 'vue-router'
import AppHeader from '@/components/AppHeader.vue'
import AppFooter from '@/components/AppFooter.vue'
</script>

<template>
  <AppHeader />
  <main class="main-content">
    <RouterView />
  </main>
  <AppFooter />
</template>

<style>
* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
  background: #f8f9fa;
  color: #212529;
  padding-top: 70px;
}

.main-content { min-height: calc(100vh - 140px); }

/* Global utilities */
.btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 10px 20px;
  border: none;
  border-radius: 10px;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  text-decoration: none;
}
.btn:disabled { opacity: 0.6; cursor: not-allowed; }
.btn-primary   { background: #e91e8c; color: #fff; }
.btn-primary:hover:not(:disabled) { background: #c2157a; transform: translateY(-1px); }
.btn-secondary { background: #6c757d; color: #fff; }
.btn-secondary:hover:not(:disabled) { background: #5a6268; }
.btn-outline   { background: transparent; border: 2px solid #e91e8c; color: #e91e8c; }
.btn-outline:hover:not(:disabled) { background: #e91e8c; color: #fff; }
.btn-danger    { background: #dc3545; color: #fff; }
.btn-danger:hover:not(:disabled) { background: #c82333; }
.btn-success   { background: #28a745; color: #fff; }
.btn-success:hover:not(:disabled) { background: #218838; }
.btn-sm { padding: 6px 14px; font-size: 0.85rem; }
.btn-lg { padding: 14px 28px; font-size: 1.1rem; }

.card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.08);
  padding: 24px;
}

.container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
.container-sm { max-width: 640px; margin: 0 auto; padding: 0 20px; }

.form-group { margin-bottom: 18px; }
.form-group label { display: block; font-weight: 600; margin-bottom: 6px; color: #495057; }
.form-control {
  width: 100%;
  padding: 10px 14px;
  border: 2px solid #dee2e6;
  border-radius: 10px;
  font-size: 0.95rem;
  transition: border-color 0.2s;
  background: #fff;
}
.form-control:focus { outline: none; border-color: #e91e8c; }
.form-control.is-invalid { border-color: #dc3545; }

.alert {
  padding: 12px 16px;
  border-radius: 10px;
  margin-bottom: 16px;
  font-weight: 500;
}
.alert-danger  { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
.alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
.alert-info    { background: #cce5ff; color: #004085; border: 1px solid #b8daff; }

.badge {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
}
.badge-pink    { background: #fce4ec; color: #c2157a; }
.badge-blue    { background: #e3f2fd; color: #1565c0; }
.badge-green   { background: #e8f5e9; color: #2e7d32; }

.spinner {
  display: inline-block;
  width: 20px; height: 20px;
  border: 3px solid rgba(233,30,140,0.3);
  border-top-color: #e91e8c;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

.text-muted { color: #6c757d; }
.text-center { text-align: center; }
.mt-1 { margin-top: 8px; }
.mt-2 { margin-top: 16px; }
.mt-3 { margin-top: 24px; }
.mb-1 { margin-bottom: 8px; }
.mb-2 { margin-bottom: 16px; }
.mb-3 { margin-bottom: 24px; }
.gap-2 { gap: 16px; }
.flex { display: flex; }
.flex-wrap { flex-wrap: wrap; }
.items-center { align-items: center; }
.justify-between { justify-content: space-between; }
</style>
