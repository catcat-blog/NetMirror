# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NetMirror (ALS - Another Looking-glass Server) is a modern network diagnostics and performance testing tool with a Vue 3 frontend and Go backend. The project uses Docker for deployment and includes real-time Server-Sent Events (SSE) and WebSocket for live data streaming.

## Key Commands

### Development
```bash
# Quick start with Docker Compose
make dev                    # Start development environment (builds and runs)
docker-compose up -d        # Start containers in detached mode
docker-compose down         # Stop and remove containers

# Building
make build                  # Build Docker images
make build-frontend         # Build only frontend (cd ui && npm run build)
make build-backend          # Build only backend (cd backend && go build -o als)

# Frontend development
cd ui && npm install        # Install dependencies
cd ui && npm run dev        # Start dev server (Vite, host 0.0.0.0)
cd ui && npm run lint       # Run ESLint and fix issues
cd ui && npm run format     # Run Prettier formatting
cd ui && npm run type-check # Run Vue TypeScript checking

# Backend development
cd backend && go mod download    # Install dependencies
cd backend && go run main.go     # Start backend server
cd backend && go build -o als    # Build binary
make dev-backend                 # Alternative backend dev command

# Testing and Quality
make test                   # Run all tests (backend: go test, frontend: npm test)
make lint                   # Run linting checks (go vet + npm lint:check)
make lint-fix              # Fix linting issues
cd ui && npm run build:analyze   # Analyze bundle size

# Initialization
make init                   # Initialize project (install deps, git submodules)
make update-deps           # Update all dependencies
```

### Deployment
```bash
# Production deployment
make deploy                 # Build and deploy (docker-compose up -d --build)

# Container management
docker-compose logs -f looking-glass  # View logs (note: container name is 'looking-glass')
docker-compose restart looking-glass  # Restart container
make docker-stop           # Stop containers (docker-compose down)
make status                # Check service status

# Maintenance
make clean                 # Clean build artifacts
make clean-all            # Clean everything including node_modules
```

## Architecture

### Backend (Go)
- **Entry Point**: `backend/main.go` - Dual mode: web server or fake shell (`--shell` flag)
- **HTTP Routes**: `backend/als/route.go` - All API endpoints, static file serving, session management
- **Core Components**:
  - `als/client/`: WebSocket client management, message queuing, session isolation
  - `als/controller/`: All API controllers with feature-specific implementations
    - `ping/`: Native Go ping implementation using go-ping library (sends "Ping" events)
    - `nettools/`: System command wrappers with security validation (sends "MethodOutput" events)
    - `iperf3/`: iPerf3 server integration with port management
    - `speedtest/`: Speedtest.net CLI and LibreSpeed implementations
    - `shell/`: WebSocket-based terminal emulation with security restrictions
  - `embed/`: Embedded UI files for single binary distribution
  - `fakeshell/`: Limited shell environment with command restrictions for security
  - `config/`: Environment-based configuration with IP detection and location services

### Frontend (Vue 3)
- **Entry Point**: `ui/src/main.js` - Vue 3 app with Pinia, i18n, and component auto-imports
- **Key Components**:
  - `App.vue`: Main layout with theme handling, tab navigation, responsive design
  - `components/Utilities.vue`: Looking Glass main interface with dynamic component loading
  - `components/Utilities/`: Individual tool components (Ping, IPerf3, MTR, etc.)
  - `stores/app.js`: Pinia store managing SSE connections, session state, and API calls

### Real-time Communication Architecture
- **SSE (Server-Sent Events)**: Primary communication method for tool output
  - `/session` endpoint establishes connection and provides session ID
  - Event types by tool:
    - `SessionId`: Authentication token for API requests
    - `Config`: Server configuration and feature flags
    - `MemoryUsage`: Real-time server metrics
    - `Ping`: Structured packet data with latency/loss statistics
    - `MethodOutput`: Raw command output with completion flags for MTR/traceroute
  - Auto-reconnection with exponential backoff on connection loss
- **WebSocket**: Used exclusively for interactive shell terminal at `/session/:session/shell`

### Critical Implementation Details

1. **Event Handling Differences**:
   - **Ping tool**: Uses Go library with event callbacks, sends structured JSON packet data as "Ping" events
   - **Network tools** (MTR, traceroute): Execute system commands, stream raw output as "MethodOutput" events
   - **Frontend components**: Must listen to correct event type and handle different data formats

2. **Output Streaming Strategy**:
   - Use direct byte streaming (`pipe.Read(buf)`) for real-time output, not line-based scanning
   - Avoid blocking main execution path with `cmd.Wait()` - handle completion asynchronously
   - Frontend must handle partial output chunks and completion flags

3. **Session Management**:
   - Each client gets unique session ID for isolation
   - Session-based authentication required for all network tool APIs
   - Proper cleanup using Go context cancellation and AbortController on frontend

4. **Docker Environment Requirements**:
   - MTR requires `--raw` flag to work without TTY in containers
   - Use official Speedtest CLI (`speedtest`), not Python version (`speedtest-cli`)
   - Network capabilities needed for raw socket operations (ping, traceroute)
   - All tools installed via `scripts/install-software.sh` in container builds

5. **Security Considerations**:
   - Extensive input validation in `isValidIPOrHostname()` to prevent command injection
   - Fake shell environment with restricted command set
   - Session-based isolation prevents cross-client interference
   - CORS middleware configured for web-based access

## Docker Images

Pre-built multi-architecture images available on DockerHub:
- **Image**: `soyorins/netmirror:latest`
- **Architectures**: `linux/amd64`, `linux/arm64`

## Deployment Scripts

NetMirror includes automated deployment scripts in the `scripts/` directory:

### `netmirror-deploy.sh` - One-Click Deployment
- **Master Node**: `curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- --name "Master Node" --location "Your Location" --port 3000 --non-interactive`
- **Child Node**: `curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- --name "Child Node" --location "Location" --port 3001 --master "http://master-ip:3000" --admin-key "api-key" --non-interactive`

**Key Parameters**:
- `--node-url`: Use for reverse proxy/CDN setups where public URL differs from container URL
- `--non-interactive`: Skip prompts for automation
- `--master`: Master node URL for child deployments
- `--admin-key`: Required for child node registration

**Docker Container Name**: `netmirror-node-{PORT}` (e.g., `netmirror-node-3000`)

## Environment Variables

Key configuration via `.env` file:
- `HTTP_PORT`: Server port (default: 80)
- `LISTEN_IP`: IP address for server binding (default: all interfaces)
- `LOCATION`: Server location string (auto-detected via ipapi.co if not set)
- `PUBLIC_IPV4`/`PUBLIC_IPV6`: Public IP addresses (auto-detected if not set)
- `APP_TITLE`: Browser title (default: "NetMirror")
- `LOGO`: Supports URL, Base64, emoji, SVG, or text
- `UTILITIES_*`: Feature flags for enabling/disabling tools (PING, SPEEDTESTDOTNET, FAKESHELL, IPERF3, etc.)
- `SPEEDTEST_FILE_LIST`: Available test file sizes (default: "1MB 10MB 100MB 1GB")
- `IPERF3_PORT_MIN`/`IPERF3_PORT_MAX`: iPerf3 server port range (default: 30000-31000)
- `DISPLAY_TRAFFIC`: Toggle real-time traffic display (default: true)
- `SPONSOR_MESSAGE`: Custom sponsor message (text, URL, or file path)
- `ADMIN_API_KEY`: Secret key for admin API access (enables node management panel)
- `DATA_DIR`: Directory for node configuration storage (default: `./data`)

### Node Configuration (Legacy)
- `LG_NODES`: Semicolon-separated list in format `NAME|LOCATION|URL` (e.g., `London|London, UK|https://lg1.example.com`)
- `LG_CURRENT_URL`/`LG_CURRENT_NAME`/`LG_CURRENT_LOCATION`: Current node metadata

## API Endpoints

### Network Tools (require session header)
- `GET /method/ping?host=...&count=...` - Ping (IPv4)
- `GET /method/ping6?host=...` - Ping (IPv6)
- `GET /method/mtr?host=...` - MTR
- `GET /method/mtr6?host=...` - MTR (IPv6)
- `GET /method/traceroute?host=...` - Traceroute
- `GET /method/traceroute6?host=...` - Traceroute (IPv6)
- `GET /method/iperf3/server` - iPerf3 server info
- `GET /method/speedtest_dot_net?options=...` - Speedtest.net

### Node Management (require `X-Api-Key` header or `api_key` query param)
- `GET /nodes` - List all nodes (public)
- `POST /api/admin/nodes` - Create node
- `GET /api/admin/nodes/add?name=...&location=...&url=...` - Create node via GET (for automation)
- `PUT /api/admin/nodes/:id` - Update node
- `DELETE /api/admin/nodes/:id` - Delete node

## UI Technology Stack

### Core Technologies
- **Vue 3**: Composition API with `<script setup>` syntax
- **Pinia**: State management for SSE connections and app state
- **Vite**: Build tool with HMR and component auto-imports
- **Tailwind CSS**: Utility-first CSS with custom primary color theme
- **TypeScript**: Type checking available via `npm run type-check`

### Key Libraries
- **@vueuse/core**: Vue composition utilities for reactive state management
- **@headlessui/vue**: Unstyled, accessible UI components
- **vue-i18n**: Internationalization (en-US, zh-CN supported)
- **xterm.js**: Terminal emulator for WebSocket shell interface
- **ApexCharts**: Real-time traffic visualization
- **Axios**: HTTP client with session header management

### Styling System
- **Glass morphism design**: Backdrop blur effects throughout UI
- **Dark/light theme**: Persistent theme with system preference detection
- **Responsive breakpoints**: Mobile-first design with floating action buttons
- **Animation system**: CSS keyframes with staggered delays for smooth transitions

## Common Issues and Solutions

1. **Network tools not showing output**: 
   - Verify correct SSE event type listener ("Ping" vs "MethodOutput")
   - Check session ID is properly set in request headers
   - Ensure tool is enabled in server configuration

2. **WebSocket terminal not connecting**: 
   - Verify session ID in WebSocket URL construction
   - Check network capabilities in Docker container for raw socket access
   - Confirm fake shell is enabled via `UTILITIES_FAKESHELL=true`

3. **Frontend build embedding issues**: 
   - Always run `cd ui && npm run build` before backend compilation
   - Use `make build` which handles proper UI embedding sequence
   - Check `backend/embed/ui.go` generates correctly after frontend build

4. **Theme and styling problems**: 
   - Ensure all text inputs use `text-gray-900 dark:text-gray-100` for visibility
   - Use Tailwind `primary-*` color classes for consistent theming
   - Check CSS custom properties are properly defined in `:root`

5. **Real-time communication failures**:
   - Monitor browser Developer Tools for SSE connection status
   - Check for CORS issues in browser console
   - Verify server logs for session management errors

## Development Workflow

### Frontend Development
1. **Live development**: Use `cd ui && npm run dev` for Vite dev server with HMR
2. **Production testing**: Always build and test in Docker environment: `make dev`
3. **Code quality**: Run `npm run lint`, `npm run format`, and `npm run type-check`
4. **Component development**: Use auto-import system - components register automatically

### Backend Development
1. **Live development**: Use `cd backend && go run main.go` or `make dev-backend`
2. **Production builds**: Use `make build` which embeds frontend files correctly
3. **Docker testing**: Essential for network tools testing: `docker-compose up -d`
4. **Debugging**: Check logs with `docker-compose logs -f looking-glass`

### Full Stack Changes
1. **Frontend changes**: Build frontend first with `cd ui && npm run build`
2. **Backend embedding**: Rebuild backend to embed new UI files
3. **Container testing**: Test in production-like environment with Docker
4. **Session testing**: Test with multiple browser tabs for session isolation

### Code Organization Patterns
- **Component structure**: Each tool has dedicated component in `components/Utilities/`
- **Store management**: Centralized state in `stores/app.js` with reactive patterns
- **API integration**: Session-based requests with automatic reconnection
- **Error handling**: Toast notifications for user feedback + console logging
- **Type safety**: Use TypeScript checking for frontend code quality