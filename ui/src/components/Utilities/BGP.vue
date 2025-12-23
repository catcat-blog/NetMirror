<template>
  <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden animate-slide-up">
    <div class="p-6">
      <!-- BGP Info Header -->
      <div v-if="currentConfig" class="mb-6">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h2 class="text-xl font-bold text-gray-900 dark:text-white">BGP Network Topology</h2>
            <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
              {{ getBGPDescription() }}
            </p>
          </div>
          <div v-if="currentConfig?.asn" class="flex items-center space-x-3">
            <span class="px-3 py-1 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300 rounded-full text-sm font-medium">
              {{ currentConfig.asn }}
            </span>
            <a
              :href="`https://stat.ripe.net/AS${asnNumber}`"
              target="_blank"
              class="text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 font-medium flex items-center transition-colors text-sm"
            >
              View on RIPE Stat
              <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
              </svg>
            </a>
          </div>
        </div>
      </div>

      <!-- BGP Data Display -->
      <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700">
        <!-- Loading State -->
        <div v-if="bgpLoading" class="p-12 text-center">
          <div class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-primary-500 border-t-transparent"></div>
          <p class="mt-4 text-lg text-gray-600 dark:text-gray-400">Loading BGP neighbours...</p>
        </div>

        <!-- Error State -->
        <div v-else-if="bgpError" class="p-12 text-center text-red-600 dark:text-red-400">
          <svg class="w-16 h-16 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <p class="text-lg font-medium mb-2">Failed to load BGP data</p>
          <p class="text-sm text-gray-500 mb-4">{{ bgpErrorMessage }}</p>
          <button
            @click="loadBGPData"
            class="px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors"
          >
            Retry
          </button>
        </div>

        <!-- No ASN State -->
        <div v-else-if="!currentConfig?.asn" class="p-12 text-center text-gray-500 dark:text-gray-400">
          <svg class="w-16 h-16 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
          </svg>
          <p class="text-lg font-medium mb-2">No ASN Information</p>
          <p class="text-sm">BGP topology requires ASN data to be available</p>
        </div>

        <!-- Success State - Neighbours Table -->
        <div v-else-if="bgpData" class="overflow-hidden">
          <!-- Summary Stats -->
          <div class="grid grid-cols-3 gap-4 p-4 bg-gray-50 dark:bg-gray-900/50 border-b border-gray-200 dark:border-gray-700">
            <div class="text-center">
              <p class="text-2xl font-bold text-blue-600 dark:text-blue-400">{{ upstreamCount }}</p>
              <p class="text-sm text-gray-600 dark:text-gray-400">Upstream</p>
            </div>
            <div class="text-center">
              <p class="text-2xl font-bold text-green-600 dark:text-green-400">{{ peerCount }}</p>
              <p class="text-sm text-gray-600 dark:text-gray-400">Peers</p>
            </div>
            <div class="text-center">
              <p class="text-2xl font-bold text-purple-600 dark:text-purple-400">{{ downstreamCount }}</p>
              <p class="text-sm text-gray-600 dark:text-gray-400">Downstream</p>
            </div>
          </div>

          <!-- Neighbours Table -->
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead class="bg-gray-50 dark:bg-gray-900/50">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">ASN</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Type</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Power</th>
                  <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">IPv4</th>
                  <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">IPv6</th>
                  <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                <tr
                  v-for="neighbour in sortedNeighbours"
                  :key="neighbour.asn"
                  class="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
                >
                  <td class="px-4 py-3">
                    <span class="font-mono font-medium text-gray-900 dark:text-white">AS{{ neighbour.asn }}</span>
                  </td>
                  <td class="px-4 py-3">
                    <span
                      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                      :class="getTypeClasses(neighbour.type)"
                    >
                      {{ getTypeLabel(neighbour.type) }}
                    </span>
                  </td>
                  <td class="px-4 py-3">
                    <div class="flex items-center">
                      <div class="w-16 bg-gray-200 dark:bg-gray-700 rounded-full h-2 mr-2">
                        <div
                          class="h-2 rounded-full transition-all duration-300"
                          :class="getPowerColor(neighbour.power)"
                          :style="{ width: `${Math.round(neighbour.power * 100)}%` }"
                        ></div>
                      </div>
                      <span class="text-sm text-gray-600 dark:text-gray-400">{{ (neighbour.power * 100).toFixed(0) }}%</span>
                    </div>
                  </td>
                  <td class="px-4 py-3 text-center">
                    <span v-if="neighbour.v4_peers > 0" class="inline-flex items-center justify-center w-6 h-6 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 rounded-full text-xs font-medium">
                      {{ neighbour.v4_peers }}
                    </span>
                    <span v-else class="text-gray-400 dark:text-gray-600">-</span>
                  </td>
                  <td class="px-4 py-3 text-center">
                    <span v-if="neighbour.v6_peers > 0" class="inline-flex items-center justify-center w-6 h-6 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 rounded-full text-xs font-medium">
                      {{ neighbour.v6_peers }}
                    </span>
                    <span v-else class="text-gray-400 dark:text-gray-600">-</span>
                  </td>
                  <td class="px-4 py-3 text-right">
                    <a
                      :href="`https://stat.ripe.net/AS${neighbour.asn}`"
                      target="_blank"
                      class="text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 text-sm font-medium transition-colors"
                    >
                      View
                    </a>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Query Time Info -->
          <div v-if="queryTime" class="px-4 py-3 bg-gray-50 dark:bg-gray-900/50 border-t border-gray-200 dark:border-gray-700 text-xs text-gray-500 dark:text-gray-400">
            Data from RIPE Stat | Query time: {{ queryTime }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useAppStore } from '@/stores/app'
import { useNodeTool } from '@/composables/useNodeTool'

const appStore = useAppStore()

const {
  selectedNode,
} = useNodeTool()

// BGP Data related
const bgpData = ref(null)
const bgpLoading = ref(false)
const bgpError = ref(false)
const bgpErrorMessage = ref('')
const queryTime = ref('')

// Computed properties
const asnNumber = computed(() => {
  const config = currentConfig.value
  return config?.asn ? config.asn.replace('AS', '') : null
})

const currentConfig = computed(() => {
  if (selectedNode.value && selectedNode.value.config) {
    return selectedNode.value.config
  }
  return appStore.config
})

const neighbours = computed(() => {
  return bgpData.value?.data?.neighbours || []
})

const sortedNeighbours = computed(() => {
  return [...neighbours.value].sort((a, b) => b.power - a.power)
})

const upstreamCount = computed(() => {
  return neighbours.value.filter(n => n.type === 'left').length
})

const downstreamCount = computed(() => {
  return neighbours.value.filter(n => n.type === 'right').length
})

const peerCount = computed(() => {
  return neighbours.value.filter(n => n.type === 'uncertain' || n.type === 'not-announced').length
})

const bgpDataUrl = computed(() => {
  if (!asnNumber.value) return null
  const baseUrl = selectedNode.value ? selectedNode.value.url : ''
  return `${baseUrl}/bgp/data/${asnNumber.value}`
})

// Auto load data when ASN becomes available
watch(() => currentConfig.value?.asn, (newAsn) => {
  if (newAsn) {
    loadBGPData()
  }
}, { immediate: true })

// Watch for selected node changes
watch(() => selectedNode.value, (newNode, oldNode) => {
  if (newNode !== oldNode && currentConfig.value?.asn) {
    loadBGPData()
  }
}, { immediate: false })

const loadBGPData = async () => {
  if (!bgpDataUrl.value) return

  bgpLoading.value = true
  bgpError.value = false
  bgpErrorMessage.value = ''
  bgpData.value = null

  try {
    const response = await fetch(bgpDataUrl.value)

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`)
    }

    const data = await response.json()

    if (data.status === 'ok' && data.data) {
      bgpData.value = data
      queryTime.value = data.query_time || ''
    } else {
      throw new Error(data.messages?.join(', ') || 'Invalid response')
    }
  } catch (error) {
    console.error('Failed to load BGP data:', error)
    bgpError.value = true
    bgpErrorMessage.value = error.message
  } finally {
    bgpLoading.value = false
  }
}

const getTypeLabel = (type) => {
  switch (type) {
    case 'left': return 'Upstream'
    case 'right': return 'Downstream'
    case 'uncertain': return 'Peer'
    case 'not-announced': return 'Peer'
    default: return type
  }
}

const getTypeClasses = (type) => {
  switch (type) {
    case 'left':
      return 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400'
    case 'right':
      return 'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400'
    case 'uncertain':
    case 'not-announced':
      return 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400'
    default:
      return 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-400'
  }
}

const getPowerColor = (power) => {
  if (power >= 0.7) return 'bg-green-500'
  if (power >= 0.4) return 'bg-yellow-500'
  return 'bg-red-500'
}

const getBGPDescription = () => {
  const config = currentConfig.value

  if (!config?.bgp && !config?.asn) {
    return 'Network topology visualization'
  }

  if (config.bgp) {
    return config.bgp
  }

  return config.asn || 'Network topology visualization'
}

onMounted(() => {
  if (currentConfig.value?.asn) {
    loadBGPData()
  }
})
</script>

<style scoped>
.animate-slide-up {
  animation: slideUp 0.4s ease-out;
}

@keyframes slideUp {
  from {
    transform: translateY(20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}
</style>
