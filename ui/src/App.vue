<script setup>
import { computed, onMounted, onUnmounted, ref, watch, defineAsyncComponent, h } from 'vue'
import { list as langList, setI18nLanguage, loadLocaleMessages } from './config/lang.js'
import { useAppStore } from './stores/app'
import LoadingCard from '@/components/Loading.vue'
import InfoCard from '@/components/Information.vue'
import ThemeToggle from '@/components/ThemeToggle.vue'
import LanguageSelector from '@/components/LanguageSelector.vue'
import Toast from '@/components/Toast.vue'
import AdminPanel from '@/components/Admin.vue'

// Lazy load heavy components
const SpeedtestCard = defineAsyncComponent({
  loader: () => import('@/components/Speedtest.vue'),
  delay: 300,
  timeout: 10000,
  loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
    h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
  ])
})

const UtilitiesCard = defineAsyncComponent({
  loader: () => import('@/components/Utilities.vue'),
  delay: 300,
  timeout: 10000,
  loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
    h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
  ])
})

const TrafficCard = defineAsyncComponent({
  loader: () => import('@/components/TrafficDisplay.vue'),
  delay: 300,
  timeout: 10000,
  loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
    h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
  ])
})

const NodeListCard = defineAsyncComponent({
  loader: () => import('@/components/Utilities/NodeList.vue'),
  delay: 300,
  timeout: 10000,
  loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
    h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
  ])
})

const appStore = useAppStore()
const activeTab = ref('info')
const adminMode = ref(false)
const tabContainer = ref(null)
const tabNavigation = ref(null)
const showFab = ref(false)

// Use store theme and language
const isDark = computed(() => appStore.theme === 'dark')
const currentLangCode = computed(() => appStore.language)

const tabs = [
  { id: 'info', label: 'Network Information', icon: 'M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9' },
  { id: 'tools', label: 'Network Tools', icon: 'M15 12a3 3 0 11-6 0 3 3 0 016 0zM2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z' },
  { id: 'speedtest', label: 'Speed Test', icon: 'M13 10V3L4 14h7v7l9-11h-7z' },
  { id: 'traffic', label: 'Traffic Monitor', icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z' }
]

const filteredTabs = computed(() => {
  if (!appStore.config.feature_iface_traffic) {
    return tabs.filter(tab => tab.id !== 'traffic')
  }
  return tabs
})

const tabIndex = computed(() => {
  return filteredTabs.value.findIndex(tab => tab.id === activeTab.value)
})

const currentLang = computed(() => {
  for (const lang of langList) {
    if (lang.value === currentLangCode.value) {
      return lang
    }
  }
  return null
})

const handleLangChange = async (newLang) => {
  appStore.setLanguage(newLang)
  await loadLocaleMessages(newLang)
  setI18nLanguage(newLang)
}

const toggleTheme = () => {
  const newTheme = appStore.theme === 'dark' ? 'light' : 'dark'
  appStore.setTheme(newTheme)
  
  // Update html and body classes for overscroll background
  if (newTheme === 'dark') {
    document.documentElement.classList.add('dark')
    document.body.classList.add('dark')
    document.getElementById('app')?.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
    document.body.classList.remove('dark')
    document.getElementById('app')?.classList.remove('dark')
  }
}

const changeTab = (tabId) => {
  activeTab.value = tabId
  // 延迟一下让动画开始，然后滚动到tab导航位置
  setTimeout(() => {
    if (tabNavigation.value) {
      const rect = tabNavigation.value.getBoundingClientRect()
      const scrollTop = window.pageYOffset + rect.top - 100 // 留100px的顶部空间
      window.scrollTo({
        top: scrollTop,
        behavior: 'smooth'
      })
    }
  }, 50)
}

const handleScroll = () => {
  if (window.scrollY > 200) {
    showFab.value = true
  } else {
    showFab.value = false
  }
}

const scrollToTop = () => {
  window.scrollTo({
    top: 0,
    behavior: 'smooth'
  })
}

const toggleAdminMode = () => {
  adminMode.value = !adminMode.value
}

const goBackToMain = () => {
  adminMode.value = false
}

// 设置页面标题（favicon由后端处理）
const updatePageInfo = () => {
  if (!appStore.config) return
  
  // 设置页面标题（如果后端没有注入的话）
  const title = appStore.config.app_title || appStore.config.location || 'Network Diagnostic Tools'
  if (document.title === 'Looking glass server') {
    document.title = title
  }
}

onMounted(async () => {
  // Initialize the app store and wait for session ID
  await appStore.initialize()
  
  // Load stored language
  await loadLocaleMessages(appStore.language)
  setI18nLanguage(appStore.language)

  // Update page info when config is loaded
  updatePageInfo()

  // Set initial theme classes for overscroll background
  if (appStore.theme === 'dark') {
    document.documentElement.classList.add('dark')
    document.body.classList.add('dark')
    document.getElementById('app')?.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
    document.body.classList.remove('dark')
    document.getElementById('app')?.classList.remove('dark')
  }

  window.addEventListener('scroll', handleScroll)
})

// Watch for config changes to update page info
watch(() => appStore.config, () => {
  updatePageInfo()
}, { deep: true })

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-primary-50 via-white to-primary-100 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900 transition-all duration-500" style="min-height: 100vh; min-height: 100dvh;">
    <!-- Enhanced floating decorative elements -->
    <div class="fixed inset-0 overflow-hidden pointer-events-none">
      <div class="absolute -top-40 -right-40 w-96 h-96 bg-gradient-to-r from-primary-200/40 to-blue-300/30 dark:from-primary-800/20 dark:to-blue-900/10 rounded-full mix-blend-multiply filter blur-3xl opacity-70 animate-pulse-slow"></div>
      <div class="absolute -bottom-40 -left-40 w-96 h-96 bg-gradient-to-r from-blue-200/40 to-primary-300/30 dark:from-blue-800/20 dark:to-primary-900/10 rounded-full mix-blend-multiply filter blur-3xl opacity-70 animate-pulse-slow" style="animation-delay: 2s;"></div>
      <div class="absolute top-1/3 right-1/4 w-64 h-64 bg-gradient-to-r from-primary-100/30 to-sky-200/20 dark:from-primary-900/10 dark:to-sky-900/5 rounded-full mix-blend-multiply filter blur-2xl opacity-50 animate-pulse-slow" style="animation-delay: 4s;"></div>
      <div class="absolute bottom-1/3 left-1/4 w-80 h-80 bg-gradient-to-r from-sky-100/30 to-primary-200/20 dark:from-sky-900/10 dark:to-primary-900/5 rounded-full mix-blend-multiply filter blur-2xl opacity-40 animate-pulse-slow" style="animation-delay: 6s;"></div>
    </div>

    <!-- Main container -->
    <div class="relative z-10 min-h-screen">
      <!-- Header -->
      <header class="pt-8 pb-6 px-4">
        <div class="max-w-6xl mx-auto text-center">
          <!-- Logo/Icon -->
          <div 
            class="inline-flex items-center justify-center mb-4 animate-scale-in"
            :class="[
              appStore.config?.logo && (appStore.config.logo_type === 'text' || appStore.config.logo_type === 'emoji') 
                ? 'min-w-14 h-14 px-4 py-2 bg-gradient-to-br from-primary-500 to-primary-600 rounded-xl shadow-lg shadow-primary-500/25' 
                : appStore.config?.logo && (appStore.config.logo_type === 'svg' || appStore.config.logo_type === 'url' || appStore.config.logo_type === 'base64')
                ? 'w-14 h-14'
                : 'w-14 h-14 bg-gradient-to-br from-primary-500 to-primary-600 rounded-xl shadow-lg shadow-primary-500/25'
            ]"
          >
            <!-- 根据logo类型显示不同内容 -->
            <template v-if="appStore.config?.logo">
              <!-- URL类型或base64图片 -->
              <img 
                v-if="appStore.config.logo_type === 'url' || appStore.config.logo_type === 'base64'"
                :src="appStore.config.logo" 
                alt="Logo" 
                class="w-12 h-12 object-contain"
                @error="($event) => $event.target.style.display = 'none'"
              />
              <!-- SVG类型 -->
              <div 
                v-else-if="appStore.config.logo_type === 'svg'"
                class="w-12 h-12 flex items-center justify-center"
                v-html="appStore.config.logo"
              ></div>
              <!-- Emoji类型 -->
              <span 
                v-else-if="appStore.config.logo_type === 'emoji'"
                class="text-2xl"
              >{{ appStore.config.logo }}</span>
              <!-- 纯文本类型 - 智能适配 -->
              <span 
                v-else
                class="font-bold text-white text-center leading-tight px-1"
                :class="appStore.config.logo.length > 8 ? 'text-xs' : appStore.config.logo.length > 5 ? 'text-sm' : 'text-base'"
              >{{ appStore.config.logo }}</span>
            </template>
            <!-- 默认SVG图标 -->
            <svg 
              v-else
              class="w-7 h-7 text-white" 
              fill="none" 
              stroke="currentColor" 
              stroke-width="2" 
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9"/>
            </svg>
          </div>

          <!-- Title and subtitle -->
          <div class="space-y-3 animate-fade-in">
            <h1 class="text-2xl md:text-3xl lg:text-4xl font-bold bg-gradient-to-r from-primary-600 via-primary-500 to-blue-600 bg-clip-text text-transparent tracking-tight">
              {{ appStore.config?.app_title || 'Network Diagnostic Tools' }}
            </h1>
            <p class="text-base md:text-lg text-gray-600 dark:text-gray-300 font-medium max-w-2xl mx-auto">
              {{ appStore.config?.location || 'Professional Looking Glass Server' }}
            </p>
            
            <!-- Status indicator -->
            <div class="inline-flex items-center px-3 py-1.5 bg-white/70 dark:bg-gray-800/70 backdrop-blur-sm rounded-full border border-primary-200/50 dark:border-primary-700/50 shadow-lg">
              <div class="w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></div>
              <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Server Online</span>
            </div>
          </div>
        </div>
      </header>

      <!-- Main content area -->
      <main class="pb-8">
        <!-- Admin Panel -->
        <AdminPanel v-if="adminMode" @back="goBackToMain" />
        
        <!-- Normal Application -->
        <template v-else>
          <LoadingCard v-if="appStore.connecting" />
          <template v-else>
            <div class="max-w-7xl mx-auto space-y-4 md:space-y-6 px-4">
              <!-- Node List Card with enhanced mobile spacing -->
              <div class="animate-slide-up">
                <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden p-4 md:p-6">
                  <div class="mb-3 md:mb-4">
                    <h2 class="text-lg md:text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">Looking Glass Nodes Configuration</h2>
                    <p class="text-sm text-gray-600 dark:text-gray-400">Select and test connectivity to different network nodes</p>
                  </div>
                  <NodeListCard />
                </div>
              </div>
              <!-- Tab Navigation with improved mobile layout -->
              <div ref="tabNavigation" class="animate-slide-up mt-6 md:mt-8" style="animation-delay: 0.1s;">
                <div class="bg-white/60 dark:bg-gray-800/60 backdrop-blur-lg rounded-2xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 p-2">
                  <!-- Mobile: Scrollable horizontal tabs -->
                  <div class="md:hidden overflow-x-auto">
                    <div class="flex gap-2 min-w-max px-1">
                      <button
                        v-for="tab in filteredTabs"
                        :key="tab.id"
                        @click="changeTab(tab.id)"
                        class="flex items-center space-x-2 px-3 py-2 rounded-xl font-medium transition-all duration-200 group whitespace-nowrap flex-shrink-0"
                        :class="activeTab === tab.id 
                          ? 'bg-gradient-to-r from-primary-500 to-primary-600 text-white shadow-lg' 
                          : 'bg-white/50 dark:bg-gray-700/50 text-gray-700 dark:text-gray-300 hover:bg-white/80 dark:hover:bg-gray-700/80'"
                      >
                        <svg class="w-4 h-4 transition-transform duration-200" :class="activeTab === tab.id ? 'rotate-12' : 'group-hover:rotate-6'" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" :d="tab.icon"></path>
                        </svg>
                        <span class="text-sm">{{ tab.label }}</span>
                      </button>
                    </div>
                  </div>
                  <!-- Desktop: Regular flex layout -->
                  <div class="hidden md:flex gap-2">
                    <button
                      v-for="tab in filteredTabs"
                      :key="tab.id"
                      @click="changeTab(tab.id)"
                      class="flex items-center space-x-2 px-4 py-2.5 rounded-xl font-medium transition-all duration-200 group"
                      :class="activeTab === tab.id 
                        ? 'bg-gradient-to-r from-primary-500 to-primary-600 text-white shadow-lg' 
                        : 'bg-white/50 dark:bg-gray-700/50 text-gray-700 dark:text-gray-300 hover:bg-white/80 dark:hover:bg-gray-700/80'"
                    >
                      <svg class="w-5 h-5 transition-transform duration-200" :class="activeTab === tab.id ? 'rotate-12' : 'group-hover:rotate-6'" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" :d="tab.icon"></path>
                      </svg>
                      <span>{{ tab.label }}</span>
                    </button>
                  </div>
                </div>
              </div>
              
              <!-- Tab Content with improved mobile spacing and dynamic height -->
              <div class="relative mt-4 md:mt-6 overflow-hidden">
                <div 
                  class="flex transition-transform duration-300 ease-out"
                  :style="{ transform: `translateX(-${tabIndex * 100}%)` }"
                >
                  <div 
                    v-for="(tab, index) in filteredTabs" 
                    :key="tab.id"
                    class="w-full flex-shrink-0 px-1 md:px-0"
                    :style="{ order: index }"
                  >
                    <InfoCard v-if="tab.id === 'info'" />
                    <UtilitiesCard v-else-if="tab.id === 'tools'" />
                    <SpeedtestCard v-else-if="tab.id === 'speedtest'" />
                    <TrafficCard v-else-if="tab.id === 'traffic'" />
                  </div>
                </div>
              </div>
            </div>
          </template>
        </template>
      </main>

      <!-- Footer -->
      <footer class="pb-8 px-4">
        <div class="max-w-7xl mx-auto text-center">
          <div class="inline-flex items-center justify-center space-x-2 text-sm text-gray-500 dark:text-gray-400">
            <span>Powered by</span>
            <a 
              href="https://github.com/catcat-blog/NetMirror" 
              target="_blank"
              class="font-medium text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 transition-colors duration-200"
            >
              NetMirror - Another Looking Glass Server
            </a>
          </div>
        </div>
      </footer>
    </div>

    <!-- Admin Button (Always Visible) -->
    <button
      @click="toggleAdminMode"
      class="fixed bottom-8 right-8 z-50 w-12 h-12 flex items-center justify-center bg-white dark:bg-gray-700 rounded-full shadow-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-all duration-200 transform hover:scale-110 border border-gray-200 dark:border-gray-600"
      :class="adminMode ? 'ring-2 ring-primary-500' : ''"
      title="Admin Panel"
    >
      <svg class="w-5 h-5 text-gray-600 dark:text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
      </svg>
    </button>

    <!-- Floating Action Button Group (scroll to top, theme) -->
    <div class="fixed bottom-8 right-24 z-50">
      <transition
        enter-active-class="transition-all duration-300 ease-out"
        enter-from-class="opacity-0 translate-y-4"
        enter-to-class="opacity-100 translate-y-0"
        leave-active-class="transition-all duration-200 ease-in"
        leave-from-class="opacity-100 translate-y-0"
        leave-to-class="opacity-0 translate-y-4"
      >
        <div v-if="showFab" class="flex items-center space-x-2">
          <!-- Theme Toggle -->
          <div class="w-12 h-12 flex items-center justify-center bg-white dark:bg-gray-700 rounded-full shadow-lg border border-gray-200 dark:border-gray-600">
            <ThemeToggle :is-dark="isDark" @toggle="toggleTheme" />
          </div>
          <!-- Scroll to Top -->
          <button @click="scrollToTop" class="w-12 h-12 flex items-center justify-center bg-white dark:bg-gray-700 rounded-full shadow-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-all duration-200 transform hover:scale-110 border border-gray-200 dark:border-gray-600">
            <svg class="w-5 h-5 text-gray-600 dark:text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"></path></svg>
          </button>
        </div>
      </transition>
    </div>

    <!-- Toast Notifications -->
    <Toast />
  </div>
</template>

<style>
@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';

html {
  scroll-behavior: smooth;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

body {
  margin: 0;
  padding: 0;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Enhanced animations */
@keyframes fadeIn {
  0% { opacity: 0; transform: translateY(20px); }
  100% { opacity: 1; transform: translateY(0); }
}

@keyframes slideUp {
  0% { opacity: 0; transform: translateY(30px); }
  100% { opacity: 1; transform: translateY(0); }
}

@keyframes scaleIn {
  0% { opacity: 0; transform: scale(0.9); }
  100% { opacity: 1; transform: scale(1); }
}

@keyframes pulse-slow {
  0%, 100% { opacity: 0.4; }
  50% { opacity: 0.8; }
}

@keyframes bounce-gentle {
  0%, 100% { 
    transform: translateY(0);
    animation-timing-function: cubic-bezier(0.8, 0, 1, 1);
  }
  50% { 
    transform: translateY(-5px);
    animation-timing-function: cubic-bezier(0, 0, 0.2, 1);
  }
}

@keyframes slide-in-left {
  0% { opacity: 0; transform: translateX(-20px); }
  100% { opacity: 1; transform: translateX(0); }
}

@keyframes slide-in-right {
  0% { opacity: 0; transform: translateX(20px); }
  100% { opacity: 1; transform: translateX(0); }
}

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  10%, 30%, 50%, 70%, 90% { transform: translateX(-2px); }
  20%, 40%, 60%, 80% { transform: translateX(2px); }
}

.animate-fade-in {
  animation: fadeIn 0.8s ease-out;
}

.animate-slide-up {
  animation: slideUp 0.6s ease-out both;
}

.animate-scale-in {
  animation: scaleIn 0.5s ease-out;
}

.animate-pulse-slow {
  animation: pulse-slow 4s ease-in-out infinite;
}

.animate-bounce-gentle {
  animation: bounce-gentle 2s ease-in-out infinite;
}

.animate-slide-in-left {
  animation: slide-in-left 0.6s ease-out;
}

.animate-slide-in-right {
  animation: slide-in-right 0.6s ease-out;
}

.animate-shake {
  animation: shake 0.5s ease-in-out;
}

/* Mobile-friendly line clamping */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Mobile touch improvements */
@media (hover: none) {
  .group:hover .group-hover\:opacity-100 {
    opacity: 1;
  }
  .group:hover .group-hover\:scale-110 {
    transform: scale(1.1);
  }
  .group:hover .group-hover\:rotate-12 {
    transform: rotate(12deg);
  }
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: transparent;
}

::-webkit-scrollbar-thumb {
  background: rgba(59, 130, 246, 0.3);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(59, 130, 246, 0.5);
}

.dark ::-webkit-scrollbar-thumb {
  background: rgba(147, 197, 253, 0.3);
}

.dark ::-webkit-scrollbar-thumb:hover {
  background: rgba(147, 197, 253, 0.5);
}

/* Enhanced glassmorphism/acrylic effect */
.glass-effect {
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(12px) saturate(180%);
  -webkit-backdrop-filter: blur(12px) saturate(180%);
}

.dark .glass-effect {
  background: rgba(31, 41, 55, 0.6);
}

/* Tab transitions */
.tab-enter-active {
  transition: all 0.5s cubic-bezier(0.16, 1, 0.3, 1);
}

.tab-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.6, 1);
}

.tab-enter-from {
  opacity: 0;
  transform: translateY(20px);
}

.tab-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}
</style>