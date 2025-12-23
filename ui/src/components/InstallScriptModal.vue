<template>
  <!-- Install Script Modal with glass morphism -->
  <transition
    enter-active-class="transition-all duration-300 ease-out"
    enter-from-class="opacity-0 scale-95"
    enter-to-class="opacity-100 scale-100"
    leave-active-class="transition-all duration-200 ease-in"
    leave-from-class="opacity-100 scale-100"
    leave-to-class="opacity-0 scale-95"
  >
    <div class="fixed inset-0 bg-black/50 backdrop-blur-sm overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
      <div class="relative bg-white/95 dark:bg-gray-800/95 backdrop-blur-lg border border-primary-200/30 dark:border-primary-700/30 shadow-2xl rounded-2xl max-w-2xl w-full animate-scale-in">
        <!-- Modal Header -->
        <div class="px-8 py-6 border-b border-gray-200/50 dark:border-gray-600/50">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <div class="w-12 h-12 bg-gradient-to-br from-green-500 to-green-600 rounded-xl shadow-lg shadow-green-500/25 flex items-center justify-center animate-scale-in">
                <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                </svg>
              </div>
              <div>
                <h3 class="text-xl font-bold bg-gradient-to-r from-gray-900 to-gray-600 dark:from-gray-100 dark:to-gray-300 bg-clip-text text-transparent">
                  Install Script Ready
                </h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  Run this command on your child node server
                </p>
              </div>
            </div>
            <button
              @click="$emit('close')"
              class="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-xl transition-colors"
            >
              <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
              </svg>
            </button>
          </div>
        </div>

        <!-- Modal Body -->
        <div class="px-8 py-6">
          <!-- Token Info -->
          <div class="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-4 mb-6 animate-slide-up" style="animation-delay: 0.1s;">
            <div class="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span class="text-gray-500 dark:text-gray-400">Node Name:</span>
                <span class="font-semibold text-gray-900 dark:text-gray-100 ml-2">{{ token.name }}</span>
              </div>
              <div>
                <span class="text-gray-500 dark:text-gray-400">Location:</span>
                <span class="font-semibold text-gray-900 dark:text-gray-100 ml-2">{{ token.location }}</span>
              </div>
              <div>
                <span class="text-gray-500 dark:text-gray-400">Expires:</span>
                <span class="font-semibold text-gray-900 dark:text-gray-100 ml-2">{{ tokenStore.getTimeRemaining(token.expires_at) }}</span>
              </div>
              <div>
                <span class="text-gray-500 dark:text-gray-400">Status:</span>
                <span
                  class="ml-2 px-2 py-1 rounded-full text-xs font-medium"
                  :class="tokenStore.getStatusClass(token.status)"
                >
                  {{ tokenStore.getStatusText(token.status) }}
                </span>
              </div>
            </div>
          </div>

          <!-- One-liner Command -->
          <div class="mb-6 animate-slide-up" style="animation-delay: 0.2s;">
            <label class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
              One-liner Install Command
            </label>
            <div class="relative group">
              <div class="bg-gray-900 rounded-xl p-4 overflow-x-auto">
                <code class="text-green-400 font-mono text-sm whitespace-pre-wrap break-all">{{ oneLinerCommand }}</code>
              </div>
              <button
                @click="copyCommand"
                class="absolute top-2 right-2 p-2 bg-gray-800 hover:bg-gray-700 rounded-lg transition-all duration-200 group-hover:opacity-100"
                :class="{ 'opacity-100': copied, 'opacity-70': !copied }"
              >
                <svg v-if="!copied" class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
                </svg>
                <svg v-else class="w-5 h-5 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
              </button>
            </div>
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-2 ml-1">
              Copy and paste this command on your target server
            </p>
          </div>

          <!-- With Custom Options -->
          <div class="mb-6 animate-slide-up" style="animation-delay: 0.3s;">
            <label class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
              With Custom Options
            </label>
            <div class="bg-gray-900 rounded-xl p-4 overflow-x-auto">
              <code class="text-blue-400 font-mono text-sm whitespace-pre-wrap break-all">
                <span class="text-yellow-400">PORT=3001</span> <span class="text-purple-400">NODE_URL="https://your-domain.com"</span> {{ displayCommand }}
              </code>
            </div>
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-2 ml-1">
              Use environment variables to customize the installation
            </p>
          </div>

          <!-- Tips -->
          <div class="animate-slide-up" style="animation-delay: 0.4s;">
            <div class="p-4 bg-gradient-to-r from-blue-50 to-primary-50 dark:from-blue-900/20 dark:to-primary-900/20 border border-blue-200/50 dark:border-blue-700/50 rounded-xl backdrop-blur-sm">
              <div class="flex items-start space-x-3">
                <div class="flex-shrink-0">
                  <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                </div>
                <div>
                  <h4 class="text-sm font-semibold text-blue-800 dark:text-blue-300 mb-2">Important Notes:</h4>
                  <ul class="text-xs text-blue-700 dark:text-blue-400 space-y-1.5">
                    <li class="flex items-center space-x-2">
                      <div class="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                      <span>This token can only be used <strong>once</strong></span>
                    </li>
                    <li class="flex items-center space-x-2">
                      <div class="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                      <span>Token expires {{ tokenStore.getTimeRemaining(token.expires_at) }}</span>
                    </li>
                    <li class="flex items-center space-x-2">
                      <div class="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                      <span>Use <code class="bg-blue-100 dark:bg-blue-800 px-1 rounded">NODE_URL</code> if behind a reverse proxy or CDN</span>
                    </li>
                    <li class="flex items-center space-x-2">
                      <div class="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                      <span>Default port is 3000, use <code class="bg-blue-100 dark:bg-blue-800 px-1 rounded">PORT=XXXX</code> to change</span>
                    </li>
                    <li class="flex items-center space-x-2">
                      <div class="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                      <span>Docker will be installed automatically if not present</span>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Modal Footer -->
        <div class="px-8 py-4 border-t border-gray-200/50 dark:border-gray-600/50 flex justify-between items-center">
          <div class="flex items-center space-x-2 text-sm text-gray-500 dark:text-gray-400">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
            </svg>
            <span>Token ID: {{ token.id }}</span>
          </div>
          <button
            @click="$emit('close')"
            class="px-6 py-3 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-xl hover:from-primary-700 hover:to-primary-800 focus:outline-none focus:ring-2 focus:ring-primary-500 transition-all duration-200 transform hover:scale-105 shadow-lg shadow-primary-500/25"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useTokenAdminStore } from '@/stores/tokenAdmin'
import { useAppStore } from '@/stores/app'

const props = defineProps({
  token: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['close'])

const tokenStore = useTokenAdminStore()
const appStore = useAppStore()
const copied = ref(false)

const oneLinerCommand = computed(() => {
  return tokenStore.getOneLinerCommand(props.token.token)
})

const displayCommand = computed(() => {
  return tokenStore.getDisplayCommand(props.token.token)
})

const copyCommand = async () => {
  try {
    await navigator.clipboard.writeText(oneLinerCommand.value)
    copied.value = true
    appStore.showToast('Command copied to clipboard!', 'success', 2000)
    setTimeout(() => {
      copied.value = false
    }, 2000)
  } catch (err) {
    // Fallback for older browsers
    const textArea = document.createElement('textarea')
    textArea.value = oneLinerCommand.value
    document.body.appendChild(textArea)
    textArea.select()
    try {
      document.execCommand('copy')
      copied.value = true
      appStore.showToast('Command copied to clipboard!', 'success', 2000)
      setTimeout(() => {
        copied.value = false
      }, 2000)
    } catch (e) {
      appStore.showToast('Failed to copy command', 'error', 2000)
    }
    document.body.removeChild(textArea)
  }
}
</script>
