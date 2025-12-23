<template>
  <!-- Token Create Modal with glass morphism -->
  <transition
    enter-active-class="transition-all duration-300 ease-out"
    enter-from-class="opacity-0 scale-95"
    enter-to-class="opacity-100 scale-100"
    leave-active-class="transition-all duration-200 ease-in"
    leave-from-class="opacity-100 scale-100"
    leave-to-class="opacity-0 scale-95"
  >
    <div class="fixed inset-0 bg-black/50 backdrop-blur-sm overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
      <div class="relative bg-white/95 dark:bg-gray-800/95 backdrop-blur-lg border border-primary-200/30 dark:border-primary-700/30 shadow-2xl rounded-2xl max-w-lg w-full animate-scale-in">
        <!-- Modal Header -->
        <div class="px-8 py-6 border-b border-gray-200/50 dark:border-gray-600/50">
          <div class="flex items-center space-x-4">
            <div class="w-12 h-12 bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl shadow-lg shadow-purple-500/25 flex items-center justify-center animate-scale-in">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"></path>
              </svg>
            </div>
            <div>
              <h3 class="text-xl font-bold bg-gradient-to-r from-gray-900 to-gray-600 dark:from-gray-100 dark:to-gray-300 bg-clip-text text-transparent">
                Create Deploy Token
              </h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                Generate a one-click installation script
              </p>
            </div>
          </div>
        </div>

        <!-- Modal Body -->
        <div class="px-8 py-6">
          <form @submit.prevent="handleSubmit" class="space-y-6">
            <!-- Node Name Field -->
            <div class="animate-slide-up" style="animation-delay: 0.1s;">
              <label class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
                Node Name *
              </label>
              <div class="relative">
                <input
                  v-model="formData.name"
                  type="text"
                  required
                  placeholder="e.g., Singapore Node"
                  class="w-full px-4 py-3 pl-12 border border-gray-300/50 dark:border-gray-600/50 rounded-xl focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-purple-500 bg-white/80 dark:bg-gray-700/80 backdrop-blur-sm text-gray-900 dark:text-gray-100 transition-all duration-200 placeholder-gray-500 dark:placeholder-gray-400"
                >
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"></path>
                  </svg>
                </div>
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-2 ml-1">
                Display name for the new node
              </p>
            </div>

            <!-- Location Field -->
            <div class="animate-slide-up" style="animation-delay: 0.2s;">
              <label class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
                Location *
              </label>
              <div class="relative">
                <input
                  v-model="formData.location"
                  type="text"
                  required
                  placeholder="e.g., Singapore, SG"
                  class="w-full px-4 py-3 pl-12 border border-gray-300/50 dark:border-gray-600/50 rounded-xl focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-purple-500 bg-white/80 dark:bg-gray-700/80 backdrop-blur-sm text-gray-900 dark:text-gray-100 transition-all duration-200 placeholder-gray-500 dark:placeholder-gray-400"
                >
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                  </svg>
                </div>
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-2 ml-1">
                Geographic location of the node
              </p>
            </div>

            <!-- Token Expiry Field -->
            <div class="animate-slide-up" style="animation-delay: 0.3s;">
              <label class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
                Token Expires In
              </label>
              <div class="relative">
                <select
                  v-model="formData.expires_in"
                  class="w-full px-4 py-3 pl-12 border border-gray-300/50 dark:border-gray-600/50 rounded-xl focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-purple-500 bg-white/80 dark:bg-gray-700/80 backdrop-blur-sm text-gray-900 dark:text-gray-100 transition-all duration-200 appearance-none cursor-pointer"
                >
                  <option :value="1">1 hour</option>
                  <option :value="6">6 hours</option>
                  <option :value="24">24 hours (default)</option>
                  <option :value="72">3 days</option>
                  <option :value="168">7 days</option>
                </select>
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                </div>
                <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                  <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                  </svg>
                </div>
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-2 ml-1">
                Token will become invalid after this period
              </p>
            </div>

            <!-- Form Actions -->
            <div class="flex justify-end space-x-3 pt-6 animate-slide-up" style="animation-delay: 0.4s;">
              <button
                type="button"
                @click="$emit('close')"
                class="px-6 py-3 bg-white/80 dark:bg-gray-700/80 backdrop-blur-sm text-gray-800 dark:text-gray-200 border border-gray-300/50 dark:border-gray-600/50 rounded-xl hover:bg-white dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500 transition-all duration-200 hover:scale-105 shadow-lg"
              >
                Cancel
              </button>
              <button
                type="submit"
                :disabled="!isFormValid || saving"
                class="px-6 py-3 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-xl hover:from-purple-700 hover:to-purple-800 focus:outline-none focus:ring-2 focus:ring-purple-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 transform hover:scale-105 shadow-lg shadow-purple-500/25"
              >
                <span v-if="saving" class="flex items-center">
                  <svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Generating...
                </span>
                <span v-else class="flex items-center">
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"></path>
                  </svg>
                  Generate Token
                </span>
              </button>
            </div>
          </form>
        </div>

        <!-- Info Section -->
        <div class="px-8 pb-6 animate-slide-up" style="animation-delay: 0.5s;">
          <div class="p-4 bg-gradient-to-r from-purple-50 to-primary-50 dark:from-purple-900/20 dark:to-primary-900/20 border border-purple-200/50 dark:border-purple-700/50 rounded-xl backdrop-blur-sm">
            <div class="flex items-start space-x-3">
              <div class="flex-shrink-0">
                <svg class="w-5 h-5 text-purple-600 dark:text-purple-400 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
              </div>
              <div>
                <h4 class="text-sm font-semibold text-purple-800 dark:text-purple-300 mb-2">How it works:</h4>
                <ul class="text-xs text-purple-700 dark:text-purple-400 space-y-1.5">
                  <li class="flex items-center space-x-2">
                    <div class="w-1.5 h-1.5 bg-purple-500 rounded-full"></div>
                    <span>Token is generated with pre-configured node info</span>
                  </li>
                  <li class="flex items-center space-x-2">
                    <div class="w-1.5 h-1.5 bg-purple-500 rounded-full"></div>
                    <span>Copy the install command and run on your server</span>
                  </li>
                  <li class="flex items-center space-x-2">
                    <div class="w-1.5 h-1.5 bg-purple-500 rounded-full"></div>
                    <span>Node automatically registers with this master</span>
                  </li>
                  <li class="flex items-center space-x-2">
                    <div class="w-1.5 h-1.5 bg-purple-500 rounded-full"></div>
                    <span>Each token can only be used once</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, computed } from 'vue'

const emit = defineEmits(['close', 'created'])

const saving = ref(false)
const formData = ref({
  name: '',
  location: '',
  expires_in: 24
})

const isFormValid = computed(() => {
  return formData.value.name.trim() && formData.value.location.trim()
})

const handleSubmit = async () => {
  if (!isFormValid.value) return

  saving.value = true
  try {
    emit('created', {
      name: formData.value.name.trim(),
      location: formData.value.location.trim(),
      expires_in: formData.value.expires_in
    })
  } finally {
    saving.value = false
  }
}
</script>
