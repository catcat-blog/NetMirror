<script setup>
import { ref, onMounted } from 'vue'
import { useNodeTool } from '@/composables/useNodeTool'
import { PlayIcon, StopIcon, ChartBarIcon } from '@heroicons/vue/24/outline'

const {
  working,
  selectedNode,
  isNodeReady,
  selectedNodeName,
  selectedNodeLocation,
  startTool,
  stopTool,
  finishTool
} = useNodeTool()

const output = ref('')
const host = ref('')
const inputRef = ref()
const outputRef = ref()

const handleMTRMessage = (e) => {
  try {
    const data = JSON.parse(e.data)
    if (data.output) {
      output.value += data.output
    }
    if (data.finished) {
      finishTool()
    }
  } catch (error) {
    // If not JSON, treat as plain text
    output.value += e.data
  }

  // Auto scroll to bottom
  setTimeout(() => {
    const container = outputRef.value
    if (container) {
      container.scrollTop = container.scrollHeight
    }
  }, 50)
}

const runMTR = async () => {
  if (working.value) {
    stopTool()
    return
  }
  
  if (!host.value.trim()) {
    inputRef.value?.focus()
    return
  }
  
  output.value = ''
  
  const success = await startTool(
    'mtr', 
    { ip: host.value }, 
    'MTROutput', 
    handleMTRMessage
  )
  
  if (!success) {
    // startTool已经处理了错误显示
    return
  }
}

onMounted(() => {
  inputRef.value?.focus()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Node Selection Info -->
    <div v-if="selectedNode" class="bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-700 rounded-xl p-4">
      <div class="flex items-center">
        <div class="w-2 h-2 bg-purple-500 rounded-full mr-3"></div>
        <div>
          <h3 class="font-medium text-purple-900 dark:text-purple-100">Running MTR on {{ selectedNodeName }}</h3>
          <p class="text-sm text-purple-700 dark:text-purple-300">{{ selectedNodeLocation }}</p>
        </div>
      </div>
    </div>

    <!-- Input Section -->
    <div class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-200 dark:border-gray-700">
      <div class="flex flex-col sm:flex-row gap-4">
        <div class="relative flex-1">
          <ChartBarIcon class="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            ref="inputRef"
            v-model="host"
            :disabled="working"
            type="text"
            placeholder="Enter IP address or domain name"
            class="w-full pl-10 pr-4 py-3 bg-transparent border-0 rounded-xl focus:ring-0 transition-all duration-200 disabled:opacity-50 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400"
            @keyup.enter="runMTR"
          />
        </div>
        <button
          @click="runMTR"
          :disabled="!host.trim()"
          class="inline-flex items-center justify-center px-6 py-3 rounded-xl font-medium transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
          :class="working 
            ? 'bg-red-500 hover:bg-red-600 text-white' 
            : 'bg-purple-500 hover:bg-purple-600 text-white hover:shadow-lg'"
        >
          <component :is="working ? StopIcon : PlayIcon" class="w-5 h-5 mr-2" />
          {{ working ? 'Stop' : 'Start MTR' }}
        </button>
      </div>
    </div>

    <!-- Results Section -->
    <div v-if="output" class="bg-gray-900 dark:bg-gray-950 rounded-xl border border-gray-700 overflow-hidden shadow-sm">
      <div class="px-4 py-3 bg-gray-800 dark:bg-gray-900 border-b border-gray-700">
        <div class="flex items-center justify-between">
          <h3 class="text-sm font-medium text-gray-300">MTR Report to {{ host }}</h3>
          <span class="text-xs text-gray-400" v-if="working">Running...</span>
          <span class="text-xs text-green-400" v-else>Completed</span>
        </div>
      </div>
      <div 
        ref="outputRef"
        class="p-4 text-xs font-mono text-gray-100 overflow-x-auto max-h-[30rem] overflow-y-auto whitespace-pre leading-relaxed"
        style="font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;"
      >{{ output }}</div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!working" class="text-center py-12">
      <ChartBarIcon class="w-16 h-16 text-gray-400/50 dark:text-gray-500/50 mx-auto mb-4" />
      <h3 class="text-lg font-medium text-gray-700 dark:text-gray-300 mb-2">Ready to Run MTR</h3>
      <p class="text-gray-500 dark:text-gray-400">Enter a hostname or IP address to analyze the network path.</p>
    </div>

    <!-- Loading State -->
    <div v-else class="text-center py-12">
      <div class="inline-flex items-center space-x-2">
        <svg class="animate-spin h-5 w-5 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <span class="text-gray-600 dark:text-gray-400">Running MTR analysis...</span>
      </div>
    </div>
  </div>
</template>