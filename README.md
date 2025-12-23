# NetMirror - A Modern Looking-glass Server

[![Docker Pulls](https://img.shields.io/docker/pulls/soyorins/netmirror-panel)](https://hub.docker.com/r/soyorins/netmirror-panel)
[![License](https://img.shields.io/badge/license-Apache%202.0%20%2B%20Commons%20Clause-blue)](LICENSE)

NetMirror is a modern, feature-rich looking-glass server with a beautiful web interface for network diagnostics and performance testing.

## Architecture

NetMirror uses a Panel + Agent architecture:

```
                    ┌─────────────────────────────────────┐
                    │           Panel (Master)            │
                    │  - Full Web UI                      │
                    │  - Admin Interface                  │
                    │  - Token Management                 │
                    │  - Node Registry                    │
                    └──────────────┬──────────────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
           ▼                       ▼                       ▼
┌─────────────────────┐ ┌─────────────────────┐ ┌─────────────────────┐
│   Agent (Tokyo)     │ │   Agent (London)    │ │   Agent (Singapore) │
│   - API Only        │ │   - API Only        │ │   - API Only        │
│   - No UI           │ │   - No UI           │ │   - No UI           │
│   - Auto-registered │ │   - Auto-registered │ │   - Auto-registered │
└─────────────────────┘ └─────────────────────┘ └─────────────────────┘
```

- **Panel**: Full-featured master node with web UI, admin panel, and token management
- **Agent**: Lightweight API-only nodes that auto-register with the panel

## Features

- Network Tools: Ping, iPerf3, MTR, Traceroute, Speedtest
- Real-time Traffic: Live monitoring of network interface traffic
- Interactive Shell: Secure fake shell environment for diagnostics
- Token-based Deployment: One-click agent deployment with auto-registration
- Admin Panel: Web-based node and token management
- Modern UI: Clean responsive interface with Vue.js and Tailwind CSS

## Quick Start

### Deploy Panel (Master Node)

```bash
docker run -d \
  --name netmirror-panel \
  --network host \
  -e ADMIN_API_KEY=your-secret-key \
  -e HTTP_PORT=3000 \
  -v ./data:/data \
  soyorins/netmirror-panel:latest
```

Access the panel at `http://your-server-ip:3000`

### Deploy Agent Nodes

1. Open the Panel's admin interface (settings icon in bottom-right)
2. Go to "Deploy Tokens" section
3. Click "Create Token" and set node name/location
4. Copy the generated install script
5. Run the script on your target server:

```bash
curl -fsSL 'GENERATED_SCRIPT_URL' | bash
```

The agent will automatically:
- Install Docker if needed
- Detect external IP address
- Start the agent container
- Register with the panel

### Manual Agent Deployment

```bash
docker run -d \
  --name netmirror-agent \
  --network host \
  -e AGENT_MODE=true \
  -e HTTP_PORT=3000 \
  soyorins/netmirror-agent:latest
```

Then register manually via API:
```bash
curl -X POST "http://panel:3000/api/register" \
  -H "Content-Type: application/json" \
  -d '{"token":"YOUR_TOKEN","url":"http://agent-ip:3000"}'
```

## Docker Images

| Image | Description | Size |
|-------|-------------|------|
| `soyorins/netmirror-panel` | Full panel with UI | ~100MB |
| `soyorins/netmirror-agent` | API-only agent | ~85MB |

Supported architectures: `linux/amd64`, `linux/arm64`

## Configuration

### Panel Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `HTTP_PORT` | `80` | Server port |
| `LISTEN_IP` | `0.0.0.0` | Listen address |
| `ADMIN_API_KEY` | - | Required for admin panel access |
| `LOCATION` | Auto-detected | Server location description |
| `PUBLIC_IPV4` | Auto-detected | Public IPv4 address |
| `PUBLIC_IPV6` | Auto-detected | Public IPv6 address |
| `DATA_DIR` | `/data` | Data storage directory |

### Feature Toggles

| Variable | Default | Description |
|----------|---------|-------------|
| `DISPLAY_TRAFFIC` | `true` | Real-time traffic display |
| `ENABLE_SPEEDTEST` | `true` | Speed test feature |
| `UTILITIES_PING` | `true` | Ping utility |
| `UTILITIES_MTR` | `true` | MTR utility |
| `UTILITIES_TRACEROUTE` | `true` | Traceroute utility |
| `UTILITIES_SPEEDTESTDOTNET` | `true` | Speedtest.net utility |
| `UTILITIES_FAKESHELL` | `true` | Fake shell utility |
| `UTILITIES_IPERF3` | `true` | iPerf3 server |

### Agent Configuration

Agents inherit most settings from environment variables. Key settings:

| Variable | Default | Description |
|----------|---------|-------------|
| `AGENT_MODE` | `true` | Agent mode (set automatically) |
| `HTTP_PORT` | `3000` | API port |
| `LG_CURRENT_NAME` | - | Node display name |
| `LG_CURRENT_LOCATION` | - | Node location |
| `LG_CURRENT_URL` | Auto-detected | Node public URL |

## Admin Panel

Access the admin panel by clicking the settings icon in the floating action button (bottom-right corner).

### Node Management

- View all registered nodes with status indicators
- Edit node name and location (URL is set during registration)
- Delete nodes
- Test connectivity to all nodes

### Token Management

- Create deployment tokens with name, location, and expiration
- Generate one-click install scripts
- View and revoke active tokens

## API Endpoints

### Public

| Endpoint | Description |
|----------|-------------|
| `GET /` | Server info |
| `GET /nodes` | List all nodes |
| `GET /nodes/latency` | Test latency |

### Network Tools (requires session)

| Endpoint | Description |
|----------|-------------|
| `GET /method/ping?host=...` | Ping (IPv4) |
| `GET /method/ping6?host=...` | Ping (IPv6) |
| `GET /method/mtr?host=...` | MTR |
| `GET /method/traceroute?host=...` | Traceroute |

### Admin (requires API key)

| Endpoint | Description |
|----------|-------------|
| `GET /api/admin/nodes` | List nodes |
| `PUT /api/admin/nodes/:id` | Update node |
| `DELETE /api/admin/nodes/:id` | Delete node |
| `GET /api/admin/tokens` | List tokens |
| `POST /api/admin/tokens` | Create token |
| `DELETE /api/admin/tokens/:id` | Delete token |
| `POST /api/register` | Register agent (token auth) |

## Building from Source

### Prerequisites

- Go 1.21+
- Node.js 18+
- Docker

### Build Steps

```bash
# Build frontend
cd ui
npm install
npm run build

# Build backend
cd ../backend
go build -o ../netmirror

# Run
./netmirror
```

### Docker Build

```bash
# Build panel image
docker build -f Dockerfile -t netmirror-panel .

# Build agent image
docker build -f Dockerfile.agent -t netmirror-agent .
```

## License

Apache License, Version 2.0 with Commons Clause Restriction.
