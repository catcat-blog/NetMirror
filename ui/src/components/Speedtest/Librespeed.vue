<script setup>
import { ref, onMounted, toRaw, computed } from 'vue'
import { useMotion } from '@vueuse/motion'
import { useAppStore } from '@/stores/app'
import { useNodesStore } from '@/stores/nodes'
import { useNodeTool } from '@/composables/useNodeTool'
import { PlayIcon, StopIcon, ArrowDownIcon, ArrowUpIcon, ChartBarIcon } from '@heroicons/vue/24/outline'
import VueApexCharts from 'vue3-apexcharts'

const appStore = useAppStore()
const containerRef = ref()

const {
  selectedNode,
} = useNodeTool()

// 获取当前会话ID和基础URL
const currentSessionId = computed(() => {
  if (selectedNode.value) {
    // 使用选定节点的session
    const nodesStore = useNodesStore()
    return nodesStore.selectedNodeSession
  }
  // 回退到当前节点的session
  return appStore.sessionId
})

const baseUrl = computed(() => {
  if (selectedNode.value) {
    return selectedNode.value.url
  }
  return ''
})

const { apply } = useMotion(containerRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 100, damping: 15 } }
})

let workerInstance = null
let workerTimer = null
const working = ref(false)
const uploadText = ref('0')
const downloadText = ref('0')
const chartDownloadRef = ref()
const chartUploadRef = ref()

const gaugeValue = (value) => {
  const val = parseFloat(value)
  if (val < 1) return val * 100
  if (val < 10) return val * 10
  return Math.min(val, 1000)
}

const downloadGauge = computed(() => gaugeValue(downloadText.value))
const uploadGauge = computed(() => gaugeValue(uploadText.value))

const baseChartOptions = {
  chart: {
    height: 150,
    foreColor: '#6b7280',
    animations: {
      enabled: true,
      easing: 'linear',
      dynamicAnimation: {
        speed: 300
      }
    },
    zoom: {
      enabled: false
    },
    toolbar: {
      show: false
    },
    background: 'transparent'
  },
  tooltip: {
    enabled: false
  },
  xaxis: {
    type: 'category',
    categories: [''],
    labels: {
      show: false
    },
    axisBorder: {
      show: false
    },
    axisTicks: {
      show: false
    }
  },
  yaxis: {
    show: false,
    min: 0,
  },
  dataLabels: {
    enabled: false
  },
  markers: {
    size: 0
  },
  stroke: {
    curve: 'smooth',
    width: 3
  },
  fill: {
    type: 'gradient',
    gradient: {
      shadeIntensity: 1,
      opacityFrom: 0.7,
      opacityTo: 0.1,
      stops: [0, 90, 100]
    }
  },
  grid: {
    show: false
  }
}

const baseSeries = {
  type: 'area',
  name: 'Speed',
  data: []
}

const charts = ref({
  download: {
    ref: null,
    options: { 
      ...baseChartOptions,
      colors: ['#0ea5e9'],
      fill: {
        ...baseChartOptions.fill,
        gradient: {
          ...baseChartOptions.fill.gradient,
          colorStops: [
            { offset: 0, color: '#0ea5e9', opacity: 0.8 },
            { offset: 100, color: '#0ea5e9', opacity: 0.1 }
          ]
        }
      }
    },
    series: [{ ...baseSeries, name: 'Download' }],
    data: [],
    categories: []
  },
  upload: {
    ref: null,
    options: { 
      ...baseChartOptions,
      colors: ['#3b82f6'],
      fill: {
        ...baseChartOptions.fill,
        gradient: {
          ...baseChartOptions.fill.gradient,
          colorStops: [
            { offset: 0, color: '#3b82f6', opacity: 0.8 },
            { offset: 100, color: '#3b82f6', opacity: 0.1 }
          ]
        }
      }
    },
    series: [{ ...baseSeries, name: 'Upload' }],
    data: [],
    categories: []
  }
})

// Generate unique chart IDs
const generateChartIds = () => {
  for (const chartId in charts.value) {
    charts.value[chartId].options.chart.id = 
      'chart-librespeed-' + chartId + '-' + (Math.random() + 1).toString(36).substring(2)
  }
}

const errorMessage = ref('')

const startOrStopSpeedtest = (force = false) => {
  if (workerInstance != null) {
    workerInstance.postMessage('abort')
    clearInterval(workerTimer)
    workerInstance.terminate()
    workerInstance = null

    if (force) {
      uploadText.value = '0'
      downloadText.value = '0'
      // Reset charts
      charts.value.download.data = []
      charts.value.download.categories = []
      charts.value.upload.data = []
      charts.value.upload.categories = []
    }
    working.value = false
    return
  }

  // 验证 session 是否有效
  if (!currentSessionId.value) {
    errorMessage.value = 'Session not ready, please wait...'
    setTimeout(() => { errorMessage.value = '' }, 3000)
    return
  }

  errorMessage.value = ''
  working.value = true
  uploadText.value = '0'
  downloadText.value = '0'

  // Reset chart data
  charts.value.download.data = []
  charts.value.download.categories = []
  charts.value.upload.data = []
  charts.value.upload.categories = []

  // 构造 Worker URL - 使用绝对路径
  const workerUrl = baseUrl.value
    ? `${baseUrl.value}/speedtest_worker.js`
    : `${window.location.origin}/speedtest_worker.js`

  try {
    workerInstance = new Worker(workerUrl)
  } catch (err) {
    console.error('Failed to create speedtest worker:', err)
    errorMessage.value = 'Failed to load speedtest worker'
    working.value = false
    setTimeout(() => { errorMessage.value = '' }, 3000)
    return
  }

  workerInstance.onerror = (err) => {
    console.error('Worker error:', err)
    errorMessage.value = 'Speedtest worker error'
    working.value = false
    if (workerTimer) clearInterval(workerTimer)
    workerInstance = null
    setTimeout(() => { errorMessage.value = '' }, 3000)
  }

  workerInstance.onmessage = (e) => {
    const nowPointName = new Date().toLocaleTimeString()
    const data = JSON.parse(e.data)
    const status = data.testState

    if (status >= 4) {
      return startOrStopSpeedtest(false)
    }

    if (status === 1 && data.dlStatus === 0) {
      downloadText.value = '0'
      uploadText.value = '0'
    }

    if (data.ulStatus) {
      uploadText.value = data.ulStatus
      charts.value.upload.data.push(parseFloat(data.ulStatus))
      charts.value.upload.categories.push(nowPointName)

      if (chartUploadRef.value) {
        chartUploadRef.value.updateOptions({
          xaxis: {
            categories: toRaw(charts.value.upload.categories)
          }
        })
        chartUploadRef.value.updateSeries([{
          name: 'Upload',
          data: toRaw(charts.value.upload.data)
        }])
      }
      return
    }

    if (data.dlStatus) {
      downloadText.value = data.dlStatus
      charts.value.download.data.push(parseFloat(data.dlStatus))
      charts.value.download.categories.push(nowPointName)

      if (chartDownloadRef.value) {
        chartDownloadRef.value.updateOptions({
          xaxis: {
            categories: toRaw(charts.value.download.categories)
          }
        })
        chartDownloadRef.value.updateSeries([{
          name: 'Download',
          data: toRaw(charts.value.download.data)
        }])
      }
    }
  }

  // 构造 session URL - 使用绝对路径
  const sessionUrl = baseUrl.value
    ? `${baseUrl.value}/session/${currentSessionId.value}`
    : `${window.location.origin}/session/${currentSessionId.value}`

  workerInstance.postMessage(
    'start ' + JSON.stringify({
      test_order: 'D_U',
      url_dl: `${sessionUrl}/speedtest/download`,
      url_ul: `${sessionUrl}/speedtest/upload`,
      url_ping: `${sessionUrl}/speedtest/upload`,
      url_getIp: '',  // 禁用 IP 查询，后端没有这个接口
      getIp_ispInfo: false
    })
  )

  workerTimer = setInterval(() => {
    workerInstance.postMessage('status')
  }, 200)
}

onMounted(() => {
  apply()
  generateChartIds()
})
</script>

<template>
  <div ref="containerRef" class="space-y-6">
    <!-- Results Display -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Download -->
      <div class="bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm rounded-2xl p-6 border border-primary-200/30 dark:border-primary-700/30 relative overflow-hidden shadow-lg">
        <div class="flex items-center space-x-4 mb-4">
          <div class="flex items-center justify-center w-12 h-12 bg-primary-100 dark:bg-primary-900/30 rounded-xl flex-shrink-0">
            <ArrowDownIcon class="w-6 h-6 text-primary-600 dark:text-primary-400" />
          </div>
          <div>
            <h4 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Download</h4>
            <p class="text-3xl font-bold text-primary-600 dark:text-primary-400">{{ downloadText }} <span class="text-xl">Mbps</span></p>
          </div>
        </div>
        <VueApexCharts
          type="area"
          ref="chartDownloadRef"
          :options="charts.download.options"
          :series="charts.download.series"
        />
      </div>

      <!-- Upload -->
      <div class="bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm rounded-2xl p-6 border border-primary-200/30 dark:border-primary-700/30 relative overflow-hidden shadow-lg">
        <div class="flex items-center space-x-4 mb-4">
          <div class="flex items-center justify-center w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-xl flex-shrink-0">
            <ArrowUpIcon class="w-6 h-6 text-blue-600 dark:text-blue-400" />
          </div>
          <div>
            <h4 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Upload</h4>
            <p class="text-3xl font-bold text-blue-600 dark:text-blue-400">{{ uploadText }} <span class="text-xl">Mbps</span></p>
          </div>
        </div>
        <VueApexCharts
          type="area"
          ref="chartUploadRef"
          :options="charts.upload.options"
          :series="charts.upload.series"
        />
      </div>
    </div>

    <!-- Error Message -->
    <div v-if="errorMessage" class="text-center">
      <p class="text-red-500 dark:text-red-400 text-sm">{{ errorMessage }}</p>
    </div>

    <!-- Control Button -->
    <div class="text-center pt-4">
      <button
        @click="startOrStopSpeedtest"
        :disabled="!currentSessionId && !working"
        class="inline-flex items-center px-8 py-4 rounded-full font-semibold text-lg transition-all duration-300 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
        :class="working
          ? 'bg-red-500 hover:bg-red-600 text-white shadow-lg hover:shadow-red-500/30'
          : 'bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-700 hover:to-primary-800 text-white shadow-lg hover:shadow-primary-500/30'"
      >
        <component :is="working ? StopIcon : PlayIcon" class="w-6 h-6 mr-3" />
        <span v-if="working" class="flex items-center">
          <div class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
          Stop
        </span>
        <span v-else>Begin test</span>
      </button>
    </div>
  </div>
</template>
