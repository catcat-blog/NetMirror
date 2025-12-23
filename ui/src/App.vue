<script setup>
import { computed, onMounted, ref, watch, defineAsyncComponent } from 'vue'
import { setI18nLanguage, loadLocaleMessages } from './config/lang.js'
import { useAppStore } from './stores/app'
import LoadingCard from '@/components/Loading.vue'
import Toast from '@/components/Toast.vue'
import Sidebar from '@/components/layout/Sidebar.vue'
import MobileHeader from '@/components/layout/MobileHeader.vue'

// Lazy load heavy components
const InfoCard = defineAsyncComponent(() => import('@/components/Information.vue'))
const AdminPanel = defineAsyncComponent(() => import('@/components/Admin.vue'))
const TrafficCard = defineAsyncComponent(() => import('@/components/TrafficDisplay.vue'))

// Lazy load tool components
const PingComponent = defineAsyncComponent(() => import('@/components/Utilities/Ping.vue'))
const Ping6Component = defineAsyncComponent(() => import('@/components/Utilities/Ping6.vue'))
const MTRComponent = defineAsyncComponent(() => import('@/components/Utilities/MTR.vue'))
const MTR6Component = defineAsyncComponent(() => import('@/components/Utilities/MTR6.vue'))
const TracerouteComponent = defineAsyncComponent(() => import('@/components/Utilities/Traceroute.vue'))
const Traceroute6Component = defineAsyncComponent(() => import('@/components/Utilities/Traceroute6.vue'))
const IPerf3Component = defineAsyncComponent(() => import('@/components/Utilities/IPerf3.vue'))
const SpeedtestComponent = defineAsyncComponent(() => import('@/components/Utilities/SpeedtestNet.vue'))
const ShellComponent = defineAsyncComponent(() => import('@/components/Utilities/Shell.vue'))

// Lazy load speedtest components
const LibrespeedComponent = defineAsyncComponent(() => import('@/components/Speedtest/Librespeed.vue'))
const FileSpeedtestComponent = defineAsyncComponent(() => import('@/components/Speedtest/FileSpeedtest.vue'))

const appStore = useAppStore()
const currentView = ref('info')
const adminMode = ref(false)

// Component map for dynamic rendering
const componentMap = {
  info: InfoCard,
  ping: PingComponent,
  ping6: Ping6Component,
  mtr: MTRComponent,
  mtr6: MTR6Component,
  traceroute: TracerouteComponent,
  traceroute6: Traceroute6Component,
  iperf3: IPerf3Component,
  speedtest: SpeedtestComponent,
  librespeed: LibrespeedComponent,
  filespeed: FileSpeedtestComponent,
  shell: ShellComponent,
  traffic: TrafficCard
}

// View metadata
const viewMeta = {
  info: { title: 'Network Information', desc: 'View server network configuration and status' },
  ping: { title: 'Ping Test', desc: 'Test connectivity to a host using ICMP' },
  ping6: { title: 'Ping IPv6 Test', desc: 'Test IPv6 connectivity using ICMPv6' },
  mtr: { title: 'MTR Analysis', desc: 'Analyze network path with packet loss and latency' },
  mtr6: { title: 'MTR IPv6 Analysis', desc: 'Analyze IPv6 network path' },
  traceroute: { title: 'Traceroute', desc: 'Trace the route packets take to a host' },
  traceroute6: { title: 'Traceroute IPv6', desc: 'Trace IPv6 route to destination' },
  iperf3: { title: 'IPerf3 Bandwidth Test', desc: 'Measure network bandwidth performance' },
  speedtest: { title: 'Speedtest.net', desc: 'Test internet speed via Speedtest.net' },
  librespeed: { title: 'Librespeed Test', desc: 'Test speed with Librespeed' },
  filespeed: { title: 'File Speed Test', desc: 'Test download speed with file transfer' },
  shell: { title: 'Shell Terminal', desc: 'Interactive command shell' },
  traffic: { title: 'Traffic Monitor', desc: 'Monitor network interface traffic in real-time' }
}

const currentComponent = computed(() => componentMap[currentView.value] || InfoCard)
const viewTitle = computed(() => viewMeta[currentView.value]?.title || 'Network Tools')
const viewDescription = computed(() => viewMeta[currentView.value]?.desc || '')

const handleNavigate = (viewId) => {
  currentView.value = viewId
  adminMode.value = false
}

const toggleAdminMode = () => {
  adminMode.value = !adminMode.value
}

const goBackToMain = () => {
  adminMode.value = false
}

// Page title update
const updatePageInfo = () => {
  if (!appStore.config) return
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

  // Set initial theme classes
  if (appStore.theme === 'dark') {
    document.documentElement.classList.add('dark')
    document.body.classList.add('dark')
  }
})

// Watch for config changes
watch(() => appStore.config, () => {
  updatePageInfo()
}, { deep: true })
</script>

<template>
  <div class="app-container h-screen flex bg-gray-50 dark:bg-gray-900">
    <!-- Desktop Sidebar -->
    <Sidebar
      class="hidden md:flex flex-shrink-0"
      :current-view="currentView"
      :admin-mode="adminMode"
      @navigate="handleNavigate"
      @toggle-admin="toggleAdminMode"
    />

    <!-- Mobile Header -->
    <MobileHeader
      class="md:hidden"
      :current-view="currentView"
      :admin-mode="adminMode"
      @navigate="handleNavigate"
      @toggle-admin="toggleAdminMode"
    />

    <!-- Main Content Area -->
    <main class="flex-1 overflow-auto md:pt-0 pt-14">
      <!-- Loading State -->
      <div v-if="appStore.connecting" class="flex items-center justify-center h-full">
        <LoadingCard />
      </div>

      <!-- Admin Panel -->
      <div v-else-if="adminMode" class="h-full">
        <AdminPanel @back="goBackToMain" />
      </div>

      <!-- Main Content -->
      <div v-else class="h-full">
        <div class="max-w-5xl mx-auto px-4 md:px-6 py-6">
          <!-- Page Header -->
          <div class="mb-6">
            <h2 class="text-xl font-semibold text-gray-900 dark:text-white">
              {{ viewTitle }}
            </h2>
            <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {{ viewDescription }}
            </p>
          </div>

          <!-- Dynamic Component -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
            <component :is="currentComponent" />
          </div>
        </div>
      </div>
    </main>

    <!-- Toast Notifications -->
    <Toast />
  </div>
</template>

<style>
/* Base styles - using system fonts for performance */
html {
  scroll-behavior: smooth;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

body {
  margin: 0;
  padding: 0;
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* App container */
.app-container {
  min-height: 100vh;
  min-height: 100dvh;
}

/* Scrollbar styling */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: transparent;
}

::-webkit-scrollbar-thumb {
  background: rgba(156, 163, 175, 0.4);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(156, 163, 175, 0.6);
}

.dark ::-webkit-scrollbar-thumb {
  background: rgba(75, 85, 99, 0.5);
}

.dark ::-webkit-scrollbar-thumb:hover {
  background: rgba(75, 85, 99, 0.7);
}

/* Simple fade transition */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
