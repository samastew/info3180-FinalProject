import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
<<<<<<< Updated upstream
import './assets/main.css'
=======
>>>>>>> Stashed changes

const app = createApp(App)
app.use(createPinia())
app.use(router)
<<<<<<< Updated upstream
app.mount('#app')
=======
app.mount('#app')
>>>>>>> Stashed changes
