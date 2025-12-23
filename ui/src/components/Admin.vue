<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-white to-primary-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900 transition-all duration-500">
    <!-- Animated background elements -->
    <div class="fixed inset-0 overflow-hidden pointer-events-none">
      <div class="absolute -top-40 -right-40 w-96 h-96 bg-gradient-to-r from-primary-200/30 to-blue-300/20 dark:from-primary-800/10 dark:to-blue-900/5 rounded-full mix-blend-multiply filter blur-3xl opacity-70 animate-pulse-slow"></div>
      <div class="absolute -bottom-40 -left-40 w-96 h-96 bg-gradient-to-r from-blue-200/30 to-primary-300/20 dark:from-blue-800/10 dark:to-primary-900/5 rounded-full mix-blend-multiply filter blur-3xl opacity-70 animate-pulse-slow" style="animation-delay: 2s;"></div>
    </div>

    <!-- Header with glass morphism -->
    <div class="relative z-10 bg-white/80 dark:bg-gray-800/80 backdrop-blur-lg shadow-lg border-b border-primary-200/30 dark:border-primary-700/30">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center py-6">
          <div class="animate-slide-in-left">
            <div class="flex items-center space-x-4">
              <div class="w-12 h-12 bg-gradient-to-br from-primary-500 to-primary-600 rounded-xl shadow-lg shadow-primary-500/25 flex items-center justify-center animate-scale-in">
                <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                </svg>
              </div>
              <div>
                <h1 class="text-3xl font-bold bg-gradient-to-r from-primary-600 via-primary-500 to-blue-600 bg-clip-text text-transparent">
                  Node Management
                </h1>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  Manage your network nodes and configuration
                </p>
              </div>
            </div>
          </div>
          <button
            @click="goBack"
            class="animate-slide-in-right group inline-flex items-center px-6 py-3 border border-gray-300/50 dark:border-gray-600/50 rounded-xl shadow-lg text-sm font-medium text-gray-700 dark:text-gray-200 bg-white/80 dark:bg-gray-700/80 backdrop-blur-sm hover:bg-white dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200 hover:scale-105"
          >
            <ArrowLeftIcon class="w-5 h-5 mr-2 transition-transform duration-200 group-hover:-translate-x-1" />
            Back to Main
          </button>
        </div>
      </div>
    </div>

    <div class="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- API Key Section with enhanced styling -->
      <transition
        enter-active-class="transition-all duration-500 ease-out"
        enter-from-class="opacity-0 translate-y-8 scale-95"
        enter-to-class="opacity-100 translate-y-0 scale-100"
        leave-active-class="transition-all duration-300 ease-in"
        leave-from-class="opacity-100 translate-y-0 scale-100"
        leave-to-class="opacity-0 translate-y-8 scale-95"
      >
        <div v-if="!isAuthenticated" class="mb-8">
          <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-lg rounded-2xl shadow-xl border border-primary-200/30 dark:border-primary-700/30 p-8 animate-slide-up">
            <div class="text-center mb-6">
              <div class="w-16 h-16 bg-gradient-to-br from-primary-500 to-primary-600 rounded-2xl shadow-lg shadow-primary-500/25 flex items-center justify-center mx-auto mb-4 animate-bounce-gentle">
                <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
                </svg>
              </div>
              <h2 class="text-2xl font-bold bg-gradient-to-r from-gray-900 to-gray-600 dark:from-gray-100 dark:to-gray-300 bg-clip-text text-transparent mb-2">
                Admin Authentication
              </h2>
              <p class="text-gray-600 dark:text-gray-400">
                Enter your admin API key to access node management features
              </p>
            </div>
            
            <div class="max-w-md mx-auto">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
                Admin API Key
              </label>
              <div class="flex gap-3">
                <div class="flex-1 relative">
                  <input
                    v-model="apiKey"
                    :type="showPassword ? 'text' : 'password'"
                    placeholder="Enter your admin API key"
                    class="w-full px-4 py-3 pr-12 border border-gray-300/50 dark:border-gray-600/50 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 bg-white/80 dark:bg-gray-700/80 backdrop-blur-sm text-gray-900 dark:text-gray-100 transition-all duration-200 placeholder-gray-500 dark:placeholder-gray-400"
                    @keyup.enter="authenticate"
                  >
                  <button
                    type="button"
                    @click="showPassword = !showPassword"
                    class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors duration-200"
                  >
                    <svg v-if="showPassword" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21"></path>
                    </svg>
                    <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                    </svg>
                  </button>
                </div>
                <button
                  @click="authenticate"
                  :disabled="!apiKey.trim() || authenticating"
                  class="px-6 py-3 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-xl hover:from-primary-700 hover:to-primary-800 focus:outline-none focus:ring-2 focus:ring-primary-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 transform hover:scale-105 shadow-lg shadow-primary-500/25"
                >
                  <span v-if="authenticating" class="flex items-center">
                    <svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Verifying...
                  </span>
                  <span v-else class="flex items-center">
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"></path>
                    </svg>
                    Login
                  </span>
                </button>
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-3 text-center">
                🔒 Your API key will be stored locally and remembered for future sessions
              </p>
            </div>
          </div>
        </div>
      </transition>

      <!-- Admin Panel with enhanced animations -->
      <transition
        enter-active-class="transition-all duration-500 ease-out"
        enter-from-class="opacity-0 translate-y-8"
        enter-to-class="opacity-100 translate-y-0"
      >
        <div v-if="isAuthenticated" class="space-y-6">
          <!-- Stats Cards -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-lg rounded-2xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 p-6 animate-slide-up" style="animation-delay: 0.1s;">
              <div class="flex items-center">
                <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl shadow-lg shadow-blue-500/25 flex items-center justify-center">
                  <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"></path>
                  </svg>
                </div>
                <div class="ml-4">
                  <p class="text-sm font-medium text-gray-600 dark:text-gray-400">Total Nodes</p>
                  <p class="text-2xl font-bold text-gray-900 dark:text-gray-100">{{ nodes.length }}</p>
                </div>
              </div>
            </div>
            
            <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-lg rounded-2xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 p-6 animate-slide-up" style="animation-delay: 0.2s;">
              <div class="flex items-center">
                <div class="w-12 h-12 bg-gradient-to-br from-green-500 to-green-600 rounded-xl shadow-lg shadow-green-500/25 flex items-center justify-center">
                  <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                </div>
                <div class="ml-4">
                  <p class="text-sm font-medium text-gray-600 dark:text-gray-400">
                    {{ Object.values(nodeLatencies).filter(l => l && l.status !== 'error').length > 0 ? 'Online Nodes' : 'Editable Nodes' }}
                  </p>
                  <p class="text-2xl font-bold text-gray-900 dark:text-gray-100">
                    {{ Object.values(nodeLatencies).filter(l => l && l.status !== 'error').length > 0 
                        ? Object.values(nodeLatencies).filter(l => l && l.status !== 'error').length 
                        : nodes.filter(n => n.id).length }}
                  </p>
                </div>
              </div>
            </div>
            
            <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-lg rounded-2xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 p-6 animate-slide-up" style="animation-delay: 0.3s;">
              <div class="flex items-center">
                <div class="w-12 h-12 bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl shadow-lg shadow-purple-500/25 flex items-center justify-center">
                  <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                  </svg>
                </div>
                <div class="ml-4">
                  <p class="text-sm font-medium text-gray-600 dark:text-gray-400">Current Node</p>
                  <p class="text-sm font-bold text-gray-900 dark:text-gray-100">{{ nodes.find(n => n.current)?.name || 'None' }}</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Actions Bar with enhanced styling -->
          <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6 animate-slide-up" style="animation-delay: 0.4s;">
            <div class="flex items-center space-x-4">
              <button
                @click="refreshNodes"
                :disabled="loading"
                class="group inline-flex items-center px-4 py-2 border border-gray-300/50 dark:border-gray-600/50 rounded-xl shadow-lg text-sm font-medium text-gray-700 dark:text-gray-200 bg-white/80 dark:bg-gray-700/80 backdrop-blur-sm hover:bg-white dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50 transition-all duration-200 hover:scale-105"
              >
                <ArrowPathIcon class="w-4 h-4 mr-2 transition-transform duration-200 group-hover:rotate-180" :class="{ 'animate-spin': loading }" />
                Refresh
              </button>
              <button
                @click="testAllNodesConnectivity"
                class="group inline-flex items-center px-4 py-2 border border-green-300/50 dark:border-green-600/50 rounded-xl shadow-lg text-sm font-medium text-green-700 dark:text-green-200 bg-green-50/80 dark:bg-green-900/20 backdrop-blur-sm hover:bg-green-100 dark:hover:bg-green-900/30 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-all duration-200 hover:scale-105"
              >
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"></path>
                </svg>
                Test Connectivity
              </button>
              <button
                @click="toggleTokensSection"
                class="group inline-flex items-center px-4 py-2 border border-purple-300/50 dark:border-purple-600/50 rounded-xl shadow-lg text-sm font-medium text-purple-700 dark:text-purple-200 bg-purple-50/80 dark:bg-purple-900/20 backdrop-blur-sm hover:bg-purple-100 dark:hover:bg-purple-900/30 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 transition-all duration-200 hover:scale-105"
              >
                <KeyIcon class="w-4 h-4 mr-2" />
                {{ showTokensSection ? 'Hide Tokens' : 'Deploy Tokens' }}
              </button>
              <div class="flex items-center space-x-2 text-sm text-gray-600 dark:text-gray-400">
                <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                <span>{{ nodes.length }} node{{ nodes.length !== 1 ? 's' : '' }} total</span>
              </div>
            </div>
          </div>

          <!-- Deploy Tokens Section -->
          <transition
            enter-active-class="transition-all duration-300 ease-out"
            enter-from-class="opacity-0 -translate-y-4"
            enter-to-class="opacity-100 translate-y-0"
            leave-active-class="transition-all duration-200 ease-in"
            leave-from-class="opacity-100 translate-y-0"
            leave-to-class="opacity-0 -translate-y-4"
          >
            <div v-if="showTokensSection" class="mb-8 animate-slide-up" style="animation-delay: 0.45s;">
              <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-lg rounded-2xl shadow-lg border border-purple-200/30 dark:border-purple-700/30 p-6">
                <div class="flex justify-between items-center mb-6">
                  <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl shadow-lg shadow-purple-500/25 flex items-center justify-center">
                      <KeyIcon class="w-5 h-5 text-white" />
                    </div>
                    <div>
                      <h3 class="text-lg font-bold text-gray-900 dark:text-gray-100">Deploy Tokens</h3>
                      <p class="text-xs text-gray-500 dark:text-gray-400">One-click installation scripts for child nodes</p>
                    </div>
                  </div>
                  <button
                    @click="showTokenCreateModal = true"
                    class="group inline-flex items-center px-4 py-2 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-xl hover:from-purple-700 hover:to-purple-800 focus:outline-none focus:ring-2 focus:ring-purple-500 transition-all duration-200 transform hover:scale-105 shadow-lg shadow-purple-500/25 text-sm"
                  >
                    <PlusIcon class="w-4 h-4 mr-2" />
                    Create Token
                  </button>
                </div>

                <!-- Tokens Table -->
                <div v-if="tokenStore.tokens.length > 0" class="overflow-x-auto">
                  <table class="w-full">
                    <thead>
                      <tr class="text-left text-sm font-medium text-gray-500 dark:text-gray-400 border-b border-gray-200/50 dark:border-gray-600/50">
                        <th class="pb-3 pr-4">Node Name</th>
                        <th class="pb-3 pr-4">Location</th>
                        <th class="pb-3 pr-4">Status</th>
                        <th class="pb-3 pr-4">Expires</th>
                        <th class="pb-3 text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr
                        v-for="token in tokenStore.tokens"
                        :key="token.id"
                        class="border-b border-gray-200/30 dark:border-gray-600/30 hover:bg-gray-50/50 dark:hover:bg-gray-700/30 transition-colors"
                      >
                        <td class="py-4 pr-4">
                          <span class="font-medium text-gray-900 dark:text-gray-100">{{ token.name }}</span>
                        </td>
                        <td class="py-4 pr-4 text-gray-600 dark:text-gray-400">
                          {{ token.location }}
                        </td>
                        <td class="py-4 pr-4">
                          <span
                            class="px-2.5 py-1 rounded-full text-xs font-medium"
                            :class="tokenStore.getStatusClass(token.status)"
                          >
                            {{ tokenStore.getStatusText(token.status) }}
                          </span>
                        </td>
                        <td class="py-4 pr-4 text-sm text-gray-600 dark:text-gray-400">
                          {{ tokenStore.getTimeRemaining(token.expires_at) }}
                        </td>
                        <td class="py-4 text-right">
                          <div class="flex justify-end space-x-2">
                            <button
                              v-if="token.status === 'pending'"
                              @click="showInstallScript(token)"
                              class="p-2 text-purple-600 hover:text-purple-900 dark:text-purple-400 dark:hover:text-purple-300 hover:bg-purple-50 dark:hover:bg-purple-900/20 rounded-lg transition-all duration-200"
                              title="View Install Script"
                            >
                              <CommandLineIcon class="w-4 h-4" />
                            </button>
                            <button
                              @click="deleteToken(token.id)"
                              class="p-2 text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-all duration-200"
                              title="Delete Token"
                            >
                              <TrashIcon class="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <!-- Empty State -->
                <div v-else class="text-center py-12">
                  <div class="w-16 h-16 bg-gradient-to-br from-purple-100 to-purple-200 dark:from-purple-900/30 dark:to-purple-800/30 rounded-2xl shadow-lg flex items-center justify-center mx-auto mb-4">
                    <KeyIcon class="w-8 h-8 text-purple-500 dark:text-purple-400" />
                  </div>
                  <h4 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">No deploy tokens yet</h4>
                  <p class="text-gray-500 dark:text-gray-400 mb-4 text-sm">Create a token to generate one-click install scripts for child nodes</p>
                  <button
                    @click="showTokenCreateModal = true"
                    class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-xl hover:from-purple-700 hover:to-purple-800 focus:outline-none transition-all duration-200 text-sm"
                  >
                    <PlusIcon class="w-4 h-4 mr-2" />
                    Create Your First Token
                  </button>
                </div>
              </div>
            </div>
          </transition>

          <!-- Enhanced Nodes Cards -->
          <div class="animate-slide-up" style="animation-delay: 0.5s;">
            <!-- Nodes Grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <transition-group
                enter-active-class="transition-all duration-300 ease-out"
                enter-from-class="opacity-0 translate-y-8 scale-95"
                enter-to-class="opacity-100 translate-y-0 scale-100"
                leave-active-class="transition-all duration-200 ease-in"
                leave-from-class="opacity-100 translate-y-0 scale-100"
                leave-to-class="opacity-0 translate-y-8 scale-95"
                name="node-cards"
              >
                <div 
                  v-for="(node, index) in nodes" 
                  :key="node.id || node.url"
                  class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-lg rounded-2xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 p-6 hover:shadow-xl hover:scale-105 transition-all duration-300 group"
                  :style="{ 'animation-delay': `${index * 0.1}s` }"
                >
                  <!-- Card Header -->
                  <div class="flex items-start justify-between mb-4">
                    <div class="flex items-center space-x-3">
                      <div class="w-12 h-12 bg-gradient-to-br from-primary-500 to-primary-600 rounded-xl shadow-lg shadow-primary-500/25 flex items-center justify-center group-hover:scale-110 transition-transform duration-200">
                        <span class="text-white font-bold text-lg">{{ node.name.charAt(0).toUpperCase() }}</span>
                      </div>
                      <div>
                        <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors duration-200">
                          {{ node.name }}
                        </h3>
                        <div class="flex items-center text-sm text-gray-500 dark:text-gray-400 mt-1">
                          <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                          </svg>
                          {{ node.location }}
                        </div>
                      </div>
                    </div>
                    
                    <!-- Actions -->
                    <div class="flex space-x-2 opacity-0 group-hover:opacity-100 transition-all duration-200">
                      <button
                        v-if="node.id"
                        @click="editNode(node)"
                        class="p-2 text-primary-600 hover:text-primary-900 dark:text-primary-400 dark:hover:text-primary-300 hover:bg-primary-50 dark:hover:bg-primary-900/20 rounded-lg transition-all duration-200 hover:scale-110"
                        title="Edit Node"
                      >
                        <PencilIcon class="w-4 h-4" />
                      </button>
                      <button
                        v-if="node.id"
                        @click="deleteNode(node)"
                        class="p-2 text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-all duration-200 hover:scale-110"
                        title="Delete Node"
                      >
                        <TrashIcon class="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  <!-- URL Display -->
                  <div class="mb-4">
                    <label class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Endpoint</label>
                    <div class="mt-1 flex items-center space-x-2">
                      <code class="flex-1 bg-gray-100/80 dark:bg-gray-700/80 backdrop-blur-sm px-3 py-2 rounded-lg text-sm font-mono text-gray-800 dark:text-gray-200 border border-gray-200/50 dark:border-gray-600/50 break-all">
                        {{ node.url }}
                      </code>
                      <button
                        @click="copyToClipboard(node.url, node.id || node.url)"
                        :disabled="copyingStates[node.id || node.url]"
                        class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-all duration-200 disabled:opacity-50"
                        :class="{ 'text-green-500 dark:text-green-400': copyingStates[node.id || node.url] }"
                        :title="copyingStates[node.id || node.url] ? 'Copied!' : 'Copy URL'"
                      >
                        <svg v-if="!copyingStates[node.id || node.url]" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
                        </svg>
                        <svg v-else class="w-4 h-4 animate-bounce" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                        </svg>
                      </button>
                    </div>
                  </div>

                  <!-- Status Badges -->
                  <div class="flex items-center justify-between">
                    <div class="flex flex-wrap gap-2">
                      <!-- Current Node Badge -->
                      <span v-if="node.current" class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-blue-100/80 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300 backdrop-blur-sm border border-blue-200/50 dark:border-blue-700/50">
                        <div class="w-2 h-2 bg-blue-500 rounded-full mr-2 animate-pulse"></div>
                        Current Node
                      </span>
                      
                      <!-- Management Type Badge -->
                      <span v-if="node.id" class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-green-100/80 text-green-800 dark:bg-green-900/30 dark:text-green-300 backdrop-blur-sm border border-green-200/50 dark:border-green-700/50">
                        <div class="w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></div>
                        Editable
                      </span>
                      <span v-else class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-gray-100/80 text-gray-600 dark:bg-gray-700/30 dark:text-gray-400 backdrop-blur-sm border border-gray-200/50 dark:border-gray-600/50">
                        <div class="w-2 h-2 bg-gray-500 rounded-full mr-2"></div>
                        Read-only
                      </span>
                    </div>

                    <!-- Connection Status -->
                    <div class="flex items-center text-xs" :class="getNodeStatus(node).class">
                      <div class="w-2 h-2 rounded-full mr-2" :class="getNodeStatus(node).dot"></div>
                      {{ getNodeStatus(node).text }}
                    </div>
                  </div>

                  <!-- Card Footer with additional info -->
                  <div class="mt-4 pt-4 border-t border-gray-200/50 dark:border-gray-600/50">
                    <div class="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
                      <span>ID: {{ node.id || 'ENV' }}</span>
                      <span>{{ node.current ? 'Active' : 'Standby' }}</span>
                    </div>
                  </div>
                </div>
              </transition-group>
            </div>
            
            <!-- Enhanced Empty State -->
            <transition
              enter-active-class="transition-all duration-500 ease-out"
              enter-from-class="opacity-0 scale-95"
              enter-to-class="opacity-100 scale-100"
            >
              <div v-if="nodes.length === 0" class="text-center py-16">
                <div class="w-24 h-24 bg-gradient-to-br from-purple-100 to-purple-200 dark:from-purple-900/30 dark:to-purple-800/30 rounded-3xl shadow-lg flex items-center justify-center mx-auto mb-8 animate-bounce-gentle">
                  <KeyIcon class="w-12 h-12 text-purple-500 dark:text-purple-400" />
                </div>
                <h3 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">No nodes configured</h3>
                <p class="text-gray-500 dark:text-gray-400 mb-8 max-w-md mx-auto text-lg">
                  Deploy agent nodes using one-click installation tokens. Create a token and run the generated script on your servers.
                </p>
                <button
                  @click="showTokensSection = true; showTokenCreateModal = true"
                  class="group inline-flex items-center px-8 py-4 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-2xl hover:from-purple-700 hover:to-purple-800 focus:outline-none focus:ring-2 focus:ring-purple-500 transition-all duration-200 transform hover:scale-105 shadow-lg shadow-purple-500/25 text-lg font-semibold"
                >
                  <KeyIcon class="w-6 h-6 mr-3" />
                  Create Deploy Token
                </button>
              </div>
            </transition>
          </div>

          <!-- Enhanced Logout Section -->
          <div class="mt-8 flex justify-end animate-slide-up" style="animation-delay: 0.6s;">
            <button
              @click="logout"
              class="group inline-flex items-center px-6 py-3 border border-red-300/50 dark:border-red-600/50 rounded-xl shadow-lg text-sm font-medium text-red-600 dark:text-red-400 bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm hover:bg-red-50 dark:hover:bg-red-900/20 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-all duration-200 hover:scale-105"
            >
              <ArrowRightOnRectangleIcon class="w-5 h-5 mr-2 transition-transform duration-200 group-hover:translate-x-1" />
              Logout
            </button>
          </div>
        </div>
      </transition>
    </div>

    <!-- Edit Node Modal (Agent mode - edit only, no create) -->
    <NodeEditModal
      v-if="showEditModal"
      :node="editingNode"
      :is-edit="true"
      @close="closeModal"
      @save="saveNode"
    />

    <!-- Enhanced Delete Confirmation Modal -->
    <transition
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition-all duration-200 ease-in"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <div v-if="showDeleteModal" class="fixed inset-0 bg-black/50 backdrop-blur-sm overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
        <div class="relative bg-white/95 dark:bg-gray-800/95 backdrop-blur-lg border border-red-200/50 dark:border-red-700/50 shadow-2xl rounded-2xl max-w-md w-full animate-scale-in">
          <div class="p-8 text-center">
            <div class="w-16 h-16 bg-gradient-to-br from-red-500 to-red-600 rounded-2xl shadow-lg shadow-red-500/25 flex items-center justify-center mx-auto mb-6 animate-shake">
              <ExclamationTriangleIcon class="h-8 w-8 text-white" />
            </div>
            <h3 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-3">Delete Node</h3>
            <div class="mb-6">
              <p class="text-gray-600 dark:text-gray-400 mb-2">
                Are you sure you want to delete this node?
              </p>
              <div class="bg-gray-50/80 dark:bg-gray-700/50 backdrop-blur-sm rounded-xl p-4 border border-gray-200/50 dark:border-gray-600/50">
                <p class="font-semibold text-gray-900 dark:text-gray-100">{{ deletingNode?.name }}</p>
                <p class="text-sm text-gray-500 dark:text-gray-400">{{ deletingNode?.location }}</p>
              </div>
              <p class="text-sm text-red-600 dark:text-red-400 mt-3">
                This action cannot be undone.
              </p>
            </div>
            <div class="flex justify-center space-x-3">
              <button
                @click="showDeleteModal = false"
                class="px-6 py-3 bg-white/80 dark:bg-gray-700/80 backdrop-blur-sm text-gray-800 dark:text-gray-200 border border-gray-300/50 dark:border-gray-600/50 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500 transition-all duration-200 hover:scale-105"
              >
                Cancel
              </button>
              <button
                @click="confirmDelete"
                :disabled="deleting"
                class="px-6 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-xl hover:from-red-700 hover:to-red-800 focus:outline-none focus:ring-2 focus:ring-red-500 disabled:opacity-50 transition-all duration-200 transform hover:scale-105 shadow-lg shadow-red-500/25"
              >
                <span v-if="deleting" class="flex items-center">
                  <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Deleting...
                </span>
                <span v-else class="flex items-center">
                  <TrashIcon class="w-4 h-4 mr-2" />
                  Delete Node
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- Token Create Modal -->
    <TokenCreateModal
      v-if="showTokenCreateModal"
      @close="showTokenCreateModal = false"
      @created="handleTokenCreated"
    />

    <!-- Install Script Modal -->
    <InstallScriptModal
      v-if="selectedToken"
      :token="selectedToken"
      @close="selectedToken = null"
    />
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import {
  ArrowLeftIcon,
  PlusIcon,
  PencilIcon,
  TrashIcon,
  ServerIcon,
  ArrowPathIcon,
  ArrowRightOnRectangleIcon,
  ExclamationTriangleIcon,
  KeyIcon,
  CommandLineIcon
} from '@heroicons/vue/24/outline'
import NodeEditModal from './NodeEditModal.vue'
import TokenCreateModal from './TokenCreateModal.vue'
import InstallScriptModal from './InstallScriptModal.vue'
import { useNodeAdminStore } from '@/stores/nodeAdmin'
import { useTokenAdminStore } from '@/stores/tokenAdmin'
import { useNodesStore } from '@/stores/nodes'
import { useAppStore } from '@/stores/app'
import { storeToRefs } from 'pinia'

const emit = defineEmits(['back'])

const adminStore = useNodeAdminStore()
const tokenStore = useTokenAdminStore()
const nodesStore = useNodesStore()
const appStore = useAppStore()

const { 
  nodes, 
  isAuthenticated, 
  loading, 
  apiKey: storedApiKey 
} = storeToRefs(adminStore)

// 从首页store复用延迟测试逻辑
const { 
  latencies: nodeLatencies,
  getNodeKey,
  testNodeLatency,
  testAllLatencies: testAllNodesLatency
} = nodesStore

const apiKey = ref('')
const showPassword = ref(false)
const authenticating = ref(false)
const showEditModal = ref(false)
const showDeleteModal = ref(false)
const editingNode = ref(null)
const deletingNode = ref(null)
const deleting = ref(false)
const copyingStates = ref({}) // 追踪每个节点的复制状态

// Token management state
const showTokensSection = ref(false)
const showTokenCreateModal = ref(false)
const selectedToken = ref(null)

// 删除自定义的connectivity测试逻辑，直接使用首页的延迟测试
// Test all nodes connectivity - 复用首页逻辑
const testAllNodesConnectivity = async () => {
  // 首先确保nodes store有最新的节点数据
  nodesStore.nodes = nodes.value
  // 然后使用首页的测试逻辑
  await testAllNodesLatency()
}

// Get node status - 复用首页逻辑
const getNodeStatus = (node) => {
  const nodeKey = getNodeKey(node)
  const latency = nodeLatencies[nodeKey]
  
  if (!latency) return { status: 'unknown', text: 'Unknown', class: 'text-gray-500', dot: 'bg-gray-500' }
  
  switch (latency.status) {
    case 'good':
      return { 
        status: 'online', 
        text: `Online (${latency.latency}ms)`, 
        class: 'text-green-600 dark:text-green-400', 
        dot: 'bg-green-500 animate-pulse' 
      }
    case 'medium':
      return { 
        status: 'online', 
        text: `Online (${latency.latency}ms)`, 
        class: 'text-yellow-600 dark:text-yellow-400', 
        dot: 'bg-yellow-500 animate-pulse' 
      }
    case 'high':
      return { 
        status: 'online', 
        text: `Slow (${latency.latency}ms)`, 
        class: 'text-orange-600 dark:text-orange-400', 
        dot: 'bg-orange-500 animate-pulse' 
      }
    case 'error':
      return { 
        status: 'offline', 
        text: 'Offline', 
        class: 'text-red-600 dark:text-red-400', 
        dot: 'bg-red-500' 
      }
    default:
      return { 
        status: 'unknown', 
        text: 'Unknown', 
        class: 'text-gray-500', 
        dot: 'bg-gray-500' 
      }
  }
}

// Load stored API key
onMounted(async () => {
  if (storedApiKey.value) {
    apiKey.value = storedApiKey.value
    try {
      await adminStore.authenticate(storedApiKey.value)
      // Nodes are already loaded in authenticate function
      // Test connectivity after nodes are loaded
      setTimeout(() => {
        testAllNodesConnectivity()
      }, 1000)
    } catch (error) {
      console.error('Auto-authentication failed:', error)
      // Clear invalid stored key
      adminStore.logout()
      apiKey.value = ''
    }
  }
})

const authenticate = async () => {
  if (!apiKey.value.trim()) return
  
  authenticating.value = true
  try {
    await adminStore.authenticate(apiKey.value)
    appStore.showToast('Admin authentication successful!', 'success', 2000)
    // Nodes are already loaded in authenticate function
    // Test connectivity after authentication
    setTimeout(() => {
      testAllNodesConnectivity()
    }, 1000)
  } catch (error) {
    console.error('Authentication failed:', error)
    const errorMessage = error.response?.data?.error || error.message || 'Authentication failed'
    appStore.showToast(errorMessage, 'error', 4000)
  } finally {
    authenticating.value = false
  }
}

const logout = () => {
  adminStore.logout()
  apiKey.value = ''
}

const goBack = () => {
  emit('back')
}

const refreshNodes = async () => {
  try {
    await adminStore.fetchNodes()
    appStore.showToast('Node list refreshed successfully!', 'success', 2000)
    // Test connectivity after refresh
    testAllNodesConnectivity()
  } catch (error) {
    console.error('Failed to refresh nodes:', error)
    const errorMessage = error.response?.data?.error || error.message || 'Failed to refresh nodes'
    appStore.showToast(errorMessage, 'error', 3000)
  }
}

const editNode = (node) => {
  editingNode.value = { ...node }
  showEditModal.value = true
}

const deleteNode = (node) => {
  deletingNode.value = node
  showDeleteModal.value = true
}

const confirmDelete = async () => {
  if (!deletingNode.value?.id) return
  
  deleting.value = true
  try {
    await adminStore.deleteNode(deletingNode.value.id)
    appStore.showToast(`Node "${deletingNode.value.name}" deleted successfully!`, 'success', 2000)
    showDeleteModal.value = false
    deletingNode.value = null
  } catch (error) {
    console.error('Failed to delete node:', error)
    const errorMessage = error.response?.data?.error || error.message || 'Failed to delete node'
    appStore.showToast(errorMessage, 'error', 4000)
  } finally {
    deleting.value = false
  }
}

const closeModal = () => {
  showEditModal.value = false
  editingNode.value = null
}

const saveNode = async (nodeData) => {
  try {
    if (editingNode.value?.id) {
      await adminStore.updateNode(editingNode.value.id, nodeData)
      appStore.showToast('Node updated successfully!', 'success', 2000)
      closeModal()
    }
  } catch (error) {
    console.error('Failed to save node:', error)
    const errorMessage = error.response?.data?.error || error.message || 'Failed to save node'
    appStore.showToast(errorMessage, 'error', 4000)
  }
}

const copyToClipboard = async (text, nodeId = null) => {
  // 设置复制状态
  if (nodeId) {
    copyingStates.value[nodeId] = true
  }

  try {
    await navigator.clipboard.writeText(text)
    // 使用应用的toast系统显示成功提示
    appStore.showToast('URL copied to clipboard!', 'success', 2000)
  } catch (error) {
    console.error('Failed to copy to clipboard:', error)
    // 降级方案：选择文本
    try {
      const textArea = document.createElement('textarea')
      textArea.value = text
      textArea.style.position = 'fixed'
      textArea.style.left = '-999999px'
      textArea.style.top = '-999999px'
      document.body.appendChild(textArea)
      textArea.focus()
      textArea.select()
      document.execCommand('copy')
      textArea.remove()
      appStore.showToast('URL copied to clipboard!', 'success', 2000)
    } catch (fallbackError) {
      console.error('Fallback copy failed:', fallbackError)
      appStore.showToast('Failed to copy URL to clipboard', 'error', 3000)
    }
  } finally {
    // 短暂延迟后重置复制状态，给用户视觉反馈
    setTimeout(() => {
      if (nodeId) {
        copyingStates.value[nodeId] = false
      }
    }, 1000)
  }
}

// Token management functions
const toggleTokensSection = async () => {
  showTokensSection.value = !showTokensSection.value
  if (showTokensSection.value) {
    try {
      await tokenStore.fetchTokens()
    } catch (error) {
      console.error('Failed to fetch tokens:', error)
      appStore.showToast('Failed to load tokens', 'error', 3000)
    }
  }
}

const handleTokenCreated = async (tokenData) => {
  try {
    const newToken = await tokenStore.createToken(tokenData)
    showTokenCreateModal.value = false
    selectedToken.value = newToken
    appStore.showToast('Token created! Copy the install script.', 'success', 3000)
  } catch (error) {
    console.error('Failed to create token:', error)
    const errorMessage = error.response?.data?.error || error.message || 'Failed to create token'
    appStore.showToast(errorMessage, 'error', 4000)
  }
}

const showInstallScript = (token) => {
  if (token.status !== 'pending') {
    appStore.showToast('This token has already been used or expired', 'warning', 3000)
    return
  }
  selectedToken.value = token
}

const deleteToken = async (tokenId) => {
  if (!confirm('Are you sure you want to delete this token?')) return
  try {
    await tokenStore.deleteToken(tokenId)
    appStore.showToast('Token deleted successfully', 'success', 2000)
  } catch (error) {
    console.error('Failed to delete token:', error)
    appStore.showToast('Failed to delete token', 'error', 3000)
  }
}
</script>