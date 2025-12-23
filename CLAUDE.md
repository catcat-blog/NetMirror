# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NetMirror is a modern network diagnostics and performance testing tool with a Vue 3 frontend and Go backend. It uses a Panel + Agent architecture where the Panel serves the full UI and manages Agent nodes via tokens.

## Architecture

```
Panel (Master)              Agent Nodes
┌─────────────────┐         ┌─────────────────┐
│ Full Web UI     │         │ API Only        │
│ Admin Interface │◄───────►│ No UI           │
│ Token Manager   │  SSE    │ Auto-registered │
│ Node Registry   │         │ AGENT_MODE=true │
└─────────────────┘         └─────────────────┘
```

- **Panel Image**: `soyorins/netmirror-panel` - Full UI + Admin
- **Agent Image**: `soyorins/netmirror-agent` - API only, smaller

## Key Commands

### Development
```bash
# Quick start with Docker Compose
docker-compose up -d

# Frontend development
cd ui && npm install && npm run dev

# Backend development
cd backend && go run main.go

# Build
cd ui && npm run build
cd backend && go build -o als
```

### Docker Build
```bash
# Build panel (full UI)
docker build -f Dockerfile -t netmirror-panel .

# Build agent (API only)
docker build -f Dockerfile.agent -t netmirror-agent .
```

## Backend Structure

- `backend/main.go` - Entry point
- `backend/als/route.go` - All API routes
- `backend/als/controller/` - API controllers
  - `ping/` - Ping implementation
  - `nettools/` - MTR, traceroute
  - `iperf3/` - iPerf3 server
  - `speedtest/` - Speedtest integration
  - `shell/` - Fake shell
  - `tokens/` - Token management for agent deployment
  - `nodes/` - Node CRUD operations
- `backend/config/` - Configuration with AGENT_MODE support
- `backend/embed/` - Embedded UI files

## Frontend Structure

- `ui/src/main.js` - Vue 3 entry
- `ui/src/App.vue` - Main layout
- `ui/src/components/`
  - `Utilities.vue` - Main tools interface
  - `Utilities/` - Individual tools (Ping, MTR, etc.)
  - `Admin.vue` - Admin panel
  - `NodeEditModal.vue` - Node editing (URL read-only)
  - `TokenCreateModal.vue` - Token creation
  - `InstallScriptModal.vue` - Shows install script
- `ui/src/stores/`
  - `app.js` - Main state, SSE connections
  - `nodeAdmin.js` - Admin operations

## Key Implementation Details

### Agent Mode
When `AGENT_MODE=true`:
- UI routes are not registered
- Root `/` returns JSON: `{"mode":"agent","api":true,"ui":false}`
- All API endpoints still work

### Token-based Deployment
1. Admin creates token with name/location
2. Token generates install script
3. Script deploys agent container
4. Agent calls `/api/register` with token
5. Panel adds node to registry

### SSE Events
- `SessionId` - Client session token
- `Config` - Server configuration
- `Ping` - Ping packet data
- `MethodOutput` - Command output for MTR/traceroute

## Environment Variables

### Panel
- `ADMIN_API_KEY` - Required for admin access
- `HTTP_PORT` - Server port (default: 80)
- `DATA_DIR` - Storage directory (default: /data)
- `AGENT_MODE` - Set to true for agent mode

### Agent
- `AGENT_MODE=true` - Set automatically in agent image
- `LG_CURRENT_NAME` - Node display name
- `LG_CURRENT_LOCATION` - Node location
- `LG_CURRENT_URL` - Node public URL

## API Endpoints

### Public
- `GET /` - Server info
- `GET /nodes` - List nodes
- `GET /session` - SSE connection

### Network Tools (requires session)
- `GET /method/ping?host=...`
- `GET /method/mtr?host=...`
- `GET /method/traceroute?host=...`

### Admin (requires X-Api-Key)
- `GET/PUT/DELETE /api/admin/nodes/:id`
- `GET/POST/DELETE /api/admin/tokens/:id`
- `POST /api/register` - Token-based registration

## Docker Files

- `Dockerfile` - Panel image (includes frontend)
- `Dockerfile.agent` - Agent image (no frontend, smaller)
- `docker-compose.yml` - Local development

## GitHub Actions

`.github/workflows/docker-build.yml` builds:
- `soyorins/netmirror-panel` - amd64 + arm64
- `soyorins/netmirror-agent` - amd64 + arm64

Uses Blacksmith runners for faster builds.
