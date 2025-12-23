import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import axios from 'axios'

export const useTokenAdminStore = defineStore('tokenAdmin', () => {
  // State
  const tokens = ref([])
  const loading = ref(false)
  const error = ref(null)

  // Get API key from nodeAdmin store (stored in localStorage)
  const getApiKey = () => {
    return localStorage.getItem('admin_api_key') || ''
  }

  // Check if authenticated
  const isAuthenticated = computed(() => !!getApiKey())

  // Create axios instance with API key
  const createAuthenticatedAxios = () => {
    return axios.create({
      headers: {
        'X-Api-Key': getApiKey()
      }
    })
  }

  // Fetch all tokens
  const fetchTokens = async () => {
    if (!isAuthenticated.value) {
      throw new Error('Not authenticated')
    }

    loading.value = true
    error.value = null

    try {
      const adminAxios = createAuthenticatedAxios()
      const response = await adminAxios.get('/api/admin/tokens')
      tokens.value = response.data.tokens || []
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to fetch tokens'
      throw err
    } finally {
      loading.value = false
    }
  }

  // Create new token
  const createToken = async (tokenData) => {
    if (!isAuthenticated.value) {
      throw new Error('Not authenticated')
    }

    loading.value = true
    error.value = null

    try {
      const adminAxios = createAuthenticatedAxios()
      const response = await adminAxios.post('/api/admin/tokens', tokenData)

      // Refresh tokens list
      await fetchTokens()

      // Return the created token
      return response.data.token
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to create token'
      throw err
    } finally {
      loading.value = false
    }
  }

  // Delete token
  const deleteToken = async (tokenId) => {
    if (!isAuthenticated.value) {
      throw new Error('Not authenticated')
    }

    loading.value = true
    error.value = null

    try {
      const adminAxios = createAuthenticatedAxios()
      await adminAxios.delete(`/api/admin/tokens/${tokenId}`)

      // Refresh tokens list
      await fetchTokens()
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to delete token'
      throw err
    } finally {
      loading.value = false
    }
  }

  // Get install script URL for a token
  const getInstallScriptUrl = (tokenValue) => {
    const baseUrl = window.location.origin
    const apiKey = getApiKey()
    return `${baseUrl}/api/admin/install-script/${encodeURIComponent(tokenValue)}?api_key=${encodeURIComponent(apiKey)}`
  }

  // Generate one-liner install command
  const getOneLinerCommand = (tokenValue) => {
    const scriptUrl = getInstallScriptUrl(tokenValue)
    return `curl -fsSL "${scriptUrl}" | bash`
  }

  // Get simplified one-liner (without api_key in URL for display)
  const getDisplayCommand = (tokenValue) => {
    const baseUrl = window.location.origin
    return `curl -fsSL "${baseUrl}/api/admin/install-script/${tokenValue}" | bash`
  }

  // Calculate time remaining for a token
  const getTimeRemaining = (expiresAt) => {
    const now = new Date()
    const expiry = new Date(expiresAt)
    const diff = expiry - now

    if (diff <= 0) return 'Expired'

    const hours = Math.floor(diff / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))

    if (hours >= 24) {
      const days = Math.floor(hours / 24)
      return `${days}d ${hours % 24}h`
    }
    if (hours > 0) {
      return `${hours}h ${minutes}m`
    }
    return `${minutes}m`
  }

  // Get status badge class
  const getStatusClass = (status) => {
    switch (status) {
      case 'pending':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300'
      case 'used':
        return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
      case 'expired':
        return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300'
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300'
    }
  }

  // Get status display text
  const getStatusText = (status) => {
    switch (status) {
      case 'pending':
        return 'Pending'
      case 'used':
        return 'Used'
      case 'expired':
        return 'Expired'
      default:
        return status
    }
  }

  // Clear tokens (on logout)
  const clearTokens = () => {
    tokens.value = []
    error.value = null
  }

  return {
    // State
    tokens,
    loading,
    error,

    // Getters
    isAuthenticated,

    // Actions
    fetchTokens,
    createToken,
    deleteToken,
    getInstallScriptUrl,
    getOneLinerCommand,
    getDisplayCommand,
    getTimeRemaining,
    getStatusClass,
    getStatusText,
    clearTokens
  }
})
