<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useAppStore } from '@/stores/app'
import { useNodesStore } from '@/stores/nodes'
import NavGroup from './NavGroup.vue'

const emit = defineEmits(['navigate', 'toggleAdmin'])

const props = defineProps({
  currentView: { type: String, default: 'info' },
  adminMode: { type: Boolean, default: false }
})

const appStore = useAppStore()
const nodesStore = useNodesStore()

const isDark = computed(() => appStore.theme === 'dark')

// Node selection dropdown
const showNodeDropdown = ref(false)
const nodeDropdownRef = ref(null)

const nodes = computed(() => nodesStore.nodes || [])
const selectedNode = computed(() => nodesStore.selectedNode)
const currentNodeName = computed(() => {
  if (selectedNode.value) return selectedNode.value.name
  return appStore.config?.name || 'Select Node'
})

const selectNode = (node) => {
  nodesStore.selectNode(node)
  showNodeDropdown.value = false
}

const toggleTheme = () => {
  const newTheme = appStore.theme === 'dark' ? 'light' : 'dark'
  appStore.setTheme(newTheme)
  document.documentElement.classList.toggle('dark', newTheme === 'dark')
  document.body.classList.toggle('dark', newTheme === 'dark')
}

// Close dropdown on outside click
const handleClickOutside = (e) => {
  if (nodeDropdownRef.value && !nodeDropdownRef.value.contains(e.target)) {
    showNodeDropdown.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})

// Navigation groups with feature flag support
const navGroups = computed(() => {
  const config = appStore.config || {}

  const groups = [
    {
      id: 'info',
      icon: 'globe',
      label: 'Server Info',
      items: [
        { id: 'info', label: 'Network Information', icon: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z' }
      ]
    },
    {
      id: 'connectivity',
      icon: 'signal',
      label: 'Connectivity',
      items: [
        { id: 'ping', label: 'Ping', icon: 'M5.636 18.364a9 9 0 010-12.728m12.728 0a9 9 0 010 12.728m-9.9-2.829a5 5 0 010-7.07m7.072 0a5 5 0 010 7.07M13 12a1 1 0 11-2 0 1 1 0 012 0z', flag: 'feature_ping' },
        { id: 'ping6', label: 'Ping IPv6', icon: 'M5.636 18.364a9 9 0 010-12.728m12.728 0a9 9 0 010 12.728m-9.9-2.829a5 5 0 010-7.07m7.072 0a5 5 0 010 7.07M13 12a1 1 0 11-2 0 1 1 0 012 0z', flag: 'feature_ping6' }
      ]
    },
    {
      id: 'path',
      icon: 'route',
      label: 'Path Analysis',
      items: [
        { id: 'mtr', label: 'MTR', icon: 'M3.75 3v11.25A2.25 2.25 0 006 16.5h2.25M3.75 3h-1.5m1.5 0h16.5m0 0h1.5m-1.5 0v11.25A2.25 2.25 0 0118 16.5h-2.25m-7.5 0h7.5m-7.5 0l-1 3m8.5-3l1 3m0 0l.5 1.5m-.5-1.5h-9.5m0 0l-.5 1.5', flag: 'feature_mtr' },
        { id: 'mtr6', label: 'MTR IPv6', icon: 'M3.75 3v11.25A2.25 2.25 0 006 16.5h2.25M3.75 3h-1.5m1.5 0h16.5m0 0h1.5m-1.5 0v11.25A2.25 2.25 0 0118 16.5h-2.25m-7.5 0h7.5m-7.5 0l-1 3m8.5-3l1 3m0 0l.5 1.5m-.5-1.5h-9.5m0 0l-.5 1.5', flag: 'feature_mtr6' },
        { id: 'traceroute', label: 'Traceroute', icon: 'M9 6.75V15m6-6v8.25m.503 3.498l4.875-2.437c.381-.19.622-.58.622-1.006V4.82c0-.836-.88-1.38-1.628-1.006l-3.869 1.934c-.317.159-.69.159-1.006 0L9.503 3.252a1.125 1.125 0 00-1.006 0L3.622 5.689C3.24 5.88 3 6.27 3 6.695V19.18c0 .836.88 1.38 1.628 1.006l3.869-1.934c.317-.159.69-.159 1.006 0l4.994 2.497c.317.158.69.158 1.006 0z', flag: 'feature_traceroute' },
        { id: 'traceroute6', label: 'Traceroute IPv6', icon: 'M9 6.75V15m6-6v8.25m.503 3.498l4.875-2.437c.381-.19.622-.58.622-1.006V4.82c0-.836-.88-1.38-1.628-1.006l-3.869 1.934c-.317.159-.69.159-1.006 0L9.503 3.252a1.125 1.125 0 00-1.006 0L3.622 5.689C3.24 5.88 3 6.27 3 6.695V19.18c0 .836.88 1.38 1.628 1.006l3.869-1.934c.317-.159.69-.159 1.006 0l4.994 2.497c.317.158.69.158 1.006 0z', flag: 'feature_traceroute6' }
      ]
    },
    {
      id: 'performance',
      icon: 'zap',
      label: 'Performance',
      items: [
        { id: 'iperf3', label: 'IPerf3', icon: 'M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z', flag: 'feature_iperf3' },
        { id: 'speedtest', label: 'Speedtest', icon: 'M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z', flag: 'feature_speedtest_net' },
        { id: 'librespeed', label: 'Librespeed', icon: 'M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z', flag: 'feature_librespeed' },
        { id: 'filespeed', label: 'File Speed', icon: 'M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m.75 12l3 3m0 0l3-3m-3 3v-6m-1.5-9H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z', flag: 'feature_file_speedtest' }
      ]
    },
    {
      id: 'system',
      icon: 'terminal',
      label: 'System',
      items: [
        { id: 'shell', label: 'Shell', icon: 'M6.75 7.5l3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0021 18V6a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 6v12a2.25 2.25 0 002.25 2.25z', flag: 'feature_shell' },
        { id: 'traffic', label: 'Traffic Monitor', icon: 'M7.5 14.25v2.25m3-4.5v4.5m3-6.75v6.75m3-9v9M6 20.25h12A2.25 2.25 0 0020.25 18V6A2.25 2.25 0 0018 3.75H6A2.25 2.25 0 003.75 6v12A2.25 2.25 0 006 20.25z', flag: 'feature_iface_traffic' }
      ]
    }
  ]

  // Filter items based on feature flags
  return groups.map(group => ({
    ...group,
    items: group.items.filter(item => {
      if (!item.flag) return true
      return config[item.flag] !== false
    })
  })).filter(group => group.items.length > 0)
})

const isActive = (id) => props.currentView === id

const handleNavigate = (id) => {
  emit('navigate', id)
}
</script>

<template>
  <aside class="sidebar flex flex-col w-60 h-full bg-white/95 dark:bg-gray-900/95 border-r border-gray-200 dark:border-gray-800">
    <!-- Logo & Title -->
    <div class="flex-shrink-0 px-4 py-5 border-b border-gray-100 dark:border-gray-800">
      <div class="flex items-center space-x-3">
        <!-- Logo -->
        <div
          class="flex-shrink-0 w-9 h-9 flex items-center justify-center rounded-lg bg-gradient-to-br from-primary-500 to-primary-600 shadow-sm"
        >
          <template v-if="appStore.config?.logo">
            <img
              v-if="appStore.config.logo_type === 'url' || appStore.config.logo_type === 'base64'"
              :src="appStore.config.logo"
              alt="Logo"
              class="w-6 h-6 object-contain"
            />
            <div
              v-else-if="appStore.config.logo_type === 'svg'"
              class="w-6 h-6 flex items-center justify-center text-white"
              v-html="appStore.config.logo"
            ></div>
            <span
              v-else-if="appStore.config.logo_type === 'emoji'"
              class="text-lg"
            >{{ appStore.config.logo }}</span>
            <span
              v-else
              class="text-xs font-bold text-white"
            >{{ appStore.config.logo.slice(0, 2) }}</span>
          </template>
          <svg
            v-else
            class="w-5 h-5 text-white"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9"/>
          </svg>
        </div>
        <!-- Title -->
        <div class="flex-1 min-w-0">
          <h1 class="text-sm font-semibold text-gray-900 dark:text-white truncate">
            {{ appStore.config?.app_title || 'NetMirror' }}
          </h1>
          <p class="text-xs text-gray-500 dark:text-gray-400 truncate">
            {{ appStore.config?.location || 'Looking Glass' }}
          </p>
        </div>
      </div>
    </div>

    <!-- Node Selector -->
    <div class="flex-shrink-0 px-3 py-3 border-b border-gray-100 dark:border-gray-800" ref="nodeDropdownRef">
      <div class="relative">
        <button
          @click.stop="showNodeDropdown = !showNodeDropdown"
          class="w-full flex items-center justify-between px-3 py-2 text-sm bg-gray-50 dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-700 transition-colors duration-150"
        >
          <div class="flex items-center space-x-2 min-w-0">
            <div class="w-2 h-2 rounded-full bg-green-500 flex-shrink-0"></div>
            <span class="text-gray-700 dark:text-gray-300 truncate">{{ currentNodeName }}</span>
          </div>
          <svg class="w-4 h-4 text-gray-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l4-4 4 4m0 6l-4 4-4-4" />
          </svg>
        </button>

        <!-- Dropdown -->
        <div
          v-if="showNodeDropdown && nodes.length > 0"
          class="absolute z-50 mt-1 w-full bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 py-1 max-h-64 overflow-auto"
        >
          <button
            v-for="node in nodes"
            :key="node.url"
            @click="selectNode(node)"
            class="w-full flex items-center px-3 py-2 text-sm hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors duration-150"
            :class="selectedNode?.url === node.url ? 'bg-primary-50 dark:bg-primary-900/20' : ''"
          >
            <div class="flex-1 min-w-0 text-left">
              <div class="text-gray-900 dark:text-white truncate">{{ node.name }}</div>
              <div class="text-xs text-gray-500 dark:text-gray-400 truncate">{{ node.location }}</div>
            </div>
            <svg
              v-if="selectedNode?.url === node.url"
              class="w-4 h-4 text-primary-500 flex-shrink-0 ml-2"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
            </svg>
          </button>
        </div>
      </div>
    </div>

    <!-- Navigation -->
    <nav class="flex-1 overflow-y-auto px-3 py-3 space-y-1">
      <NavGroup
        v-for="group in navGroups"
        :key="group.id"
        :label="group.label"
        :icon="group.icon"
      >
        <button
          v-for="item in group.items"
          :key="item.id"
          @click="handleNavigate(item.id)"
          class="w-full flex items-center space-x-2.5 px-3 py-2 text-sm rounded-lg transition-all duration-150"
          :class="isActive(item.id)
            ? 'bg-primary-50 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300 font-medium'
            : 'text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-200'"
        >
          <svg class="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" :d="item.icon" />
          </svg>
          <span>{{ item.label }}</span>
        </button>
      </NavGroup>
    </nav>

    <!-- Footer -->
    <div class="flex-shrink-0 px-3 py-3 border-t border-gray-100 dark:border-gray-800 space-y-1">
      <!-- Admin Button -->
      <button
        @click="$emit('toggleAdmin')"
        class="w-full flex items-center space-x-2.5 px-3 py-2 text-sm rounded-lg transition-all duration-150"
        :class="adminMode
          ? 'bg-primary-50 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300 font-medium'
          : 'text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-200'"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z" />
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        <span>Admin Panel</span>
      </button>

      <!-- Theme Toggle -->
      <button
        @click="toggleTheme"
        class="w-full flex items-center space-x-2.5 px-3 py-2 text-sm text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-200 rounded-lg transition-all duration-150"
      >
        <!-- Sun icon -->
        <svg v-if="isDark" class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z" />
        </svg>
        <!-- Moon icon -->
        <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z" />
        </svg>
        <span>{{ isDark ? 'Light Mode' : 'Dark Mode' }}</span>
      </button>
    </div>
  </aside>
</template>

<style scoped>
.sidebar {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.3) transparent;
}

.sidebar::-webkit-scrollbar {
  width: 4px;
}

.sidebar::-webkit-scrollbar-track {
  background: transparent;
}

.sidebar::-webkit-scrollbar-thumb {
  background: rgba(156, 163, 175, 0.3);
  border-radius: 2px;
}

.sidebar::-webkit-scrollbar-thumb:hover {
  background: rgba(156, 163, 175, 0.5);
}
</style>
