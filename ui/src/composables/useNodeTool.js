import { ref, computed, onUnmounted } from 'vue'
import { useNodesStore } from '@/stores/nodes'
import { useAppStore } from '@/stores/app'
import { storeToRefs } from 'pinia'
import { markRaw } from 'vue'

/**
 * 通用的节点工具管理composable
 * 为所有网络诊断工具提供统一的节点管理接口
 */
export function useNodeTool() {
  const nodesStore = useNodesStore()
  const appStore = useAppStore()
  
  const { 
    selectedNode, 
    hasSelectedNode, 
    hasNodeSession,
    selectedNodeName,
    selectedNodeLocation 
  } = storeToRefs(nodesStore)

  // 工具状态
  const working = ref(false)
  let abortController = markRaw(new AbortController())
  let eventListeners = new Map() // 存储事件监听器

  // 检查节点会话状态
  const isNodeReady = computed(() => {
    return hasSelectedNode.value && hasNodeSession.value
  })

  // 获取当前选定节点的EventSource
  const getEventSource = () => {
    if (!isNodeReady.value) {
      throw new Error('No node session available')
    }
    return nodesStore.getNodeEventSource()
  }

  // 发送API请求到选定节点
  const sendRequest = async (method, data = {}, signal = null) => {
    if (!isNodeReady.value) {
      throw new Error('No node session available')
    }
    
    return await nodesStore.createNodeRequest(method, data, signal || abortController.signal)
  }

  // 添加事件监听器
  const addEventListener = (eventType, handler) => {
    if (!isNodeReady.value) {
      console.warn('Cannot add event listener: no node session available')
      return
    }

    try {
      const source = getEventSource()
      source.addEventListener(eventType, handler)
      
      // 存储监听器以便后续清理
      if (!eventListeners.has(eventType)) {
        eventListeners.set(eventType, new Set())
      }
      eventListeners.get(eventType).add(handler)
    } catch (error) {
      console.error('Failed to add event listener:', error)
    }
  }

  // 移除事件监听器
  const removeEventListener = (eventType, handler) => {
    try {
      if (isNodeReady.value) {
        const source = getEventSource()
        source.removeEventListener(eventType, handler)
      }
      
      // 从存储中移除
      if (eventListeners.has(eventType)) {
        eventListeners.get(eventType).delete(handler)
      }
    } catch (error) {
      console.error('Failed to remove event listener:', error)
    }
  }

  // 清理所有事件监听器
  const removeAllEventListeners = () => {
    try {
      if (isNodeReady.value) {
        const source = getEventSource()
        for (const [eventType, handlers] of eventListeners) {
          for (const handler of handlers) {
            source.removeEventListener(eventType, handler)
          }
        }
      }
    } catch (error) {
      console.error('Failed to clean up event listeners:', error)
    }
    
    eventListeners.clear()
  }

  // 开始工具操作
  const startTool = async (method, data = {}, eventType = null, eventHandler = null) => {
    if (working.value) {
      stopTool()
      return false
    }

    if (!isNodeReady.value) {
      appStore.showToast('Please select a node first', 'error')
      return false
    }

    // 重置abort controller
    abortController = markRaw(new AbortController())
    working.value = true

    // 如果需要监听事件
    if (eventType && eventHandler) {
      addEventListener(eventType, eventHandler)
    }

    try {
      await sendRequest(method, data, abortController.signal)
      // 不在这里调用 stopTool() - 让事件处理器在收到 finished 信号时调用 finishTool()
      return true
    } catch (error) {
      console.error(`${method} error:`, error)
      appStore.showToast(`${method} failed: ${error.message || 'Unknown error'}`, 'error')
      stopTool()
      return false
    }
  }

  // 停止工具操作 (用于手动停止或错误情况)
  const stopTool = () => {
    working.value = false
    removeAllEventListeners()

    if (abortController) {
      abortController.abort('Tool stopped')
    }
  }

  // 完成工具操作 (用于工具正常完成时)
  const finishTool = () => {
    working.value = false
    removeAllEventListeners()
    // 不调用 abort - 请求已经完成
  }

  // 组件卸载时清理
  onUnmounted(() => {
    stopTool()
  })

  return {
    // 状态
    working,
    selectedNode,
    hasSelectedNode,
    hasNodeSession,
    isNodeReady,
    selectedNodeName,
    selectedNodeLocation,

    // 方法
    getEventSource,
    sendRequest,
    addEventListener,
    removeEventListener,
    removeAllEventListeners,
    startTool,
    stopTool,
    finishTool
  }
}