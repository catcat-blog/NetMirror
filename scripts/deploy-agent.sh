#!/bin/bash
# ============================================================================
# NetMirror Agent Deployment Script
#
# Deploy a pure API node (no UI) that registers with a master node.
#
# Usage:
#   curl -fsSL URL | bash -s -- --master http://master:3000 --token TOKEN
#
#   Or with all options:
#   ./deploy-agent.sh \
#     --master http://100.112.190.115:3000 \
#     --token abc123 \
#     --port 3001 \
#     --name "Tokyo Agent" \
#     --location "Tokyo, JP" \
#     --url http://public-ip:3001
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default values
MASTER_URL=""
TOKEN=""
PORT="${PORT:-3000}"
NODE_URL=""
NODE_NAME="${NODE_NAME:-Agent Node}"
NODE_LOCATION="${NODE_LOCATION:-Unknown}"
IMAGE="${IMAGE:-soyorins/netmirror-agent:latest}"
DEPLOY_DIR="${DEPLOY_DIR:-./netmirror-agent}"

# Helper functions
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --master)
            MASTER_URL="$2"
            shift 2
            ;;
        --token)
            TOKEN="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --url)
            NODE_URL="$2"
            shift 2
            ;;
        --name)
            NODE_NAME="$2"
            shift 2
            ;;
        --location)
            NODE_LOCATION="$2"
            shift 2
            ;;
        --image)
            IMAGE="$2"
            shift 2
            ;;
        --dir)
            DEPLOY_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "NetMirror Agent Deployment Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Required:"
            echo "  --master URL    Master node URL (e.g., http://master:3000)"
            echo "  --token TOKEN   Registration token from master"
            echo ""
            echo "Optional:"
            echo "  --port PORT     Listen port (default: 3000)"
            echo "  --url URL       Public URL of this node (auto-detected if not set)"
            echo "  --name NAME     Node display name (default: Agent Node)"
            echo "  --location LOC  Node location (default: Unknown)"
            echo "  --image IMAGE   Docker image (default: netmirror:latest)"
            echo "  --dir DIR       Deployment directory (default: ./netmirror-agent)"
            echo ""
            echo "Environment Variables:"
            echo "  PORT, NODE_URL, NODE_NAME, NODE_LOCATION, IMAGE, DEPLOY_DIR"
            exit 0
            ;;
        *)
            warn "Unknown option: $1"
            shift
            ;;
    esac
done

# Banner
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           NetMirror Agent Deployment                         ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Mode: Agent (API only, no UI)                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Validate required parameters
if [[ -z "$MASTER_URL" ]]; then
    error "Master URL is required. Use --master URL"
fi

if [[ -z "$TOKEN" ]]; then
    error "Registration token is required. Use --token TOKEN"
fi

# Step 1: Check Docker
log "Checking Docker..."
if ! command -v docker &>/dev/null; then
    log "Docker not found. Installing..."
    if curl -fsSL https://get.docker.com | sh; then
        success "Docker installed"
        [[ "$EUID" -ne 0 ]] && sudo usermod -aG docker "$USER" 2>/dev/null || true
    else
        error "Failed to install Docker"
    fi
else
    success "Docker available"
fi

# Ensure Docker is running
if ! docker info &>/dev/null; then
    log "Starting Docker daemon..."
    sudo systemctl start docker 2>/dev/null || true
    sleep 2
    docker info &>/dev/null || error "Docker daemon not running"
fi

# Step 2: Setup directory
log "Setting up: $DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

# Step 3: Detect external IP if NODE_URL not set
if [[ -z "$NODE_URL" ]]; then
    log "Detecting external IP..."
    for svc in "ifconfig.me" "ipinfo.io/ip" "api.ipify.org"; do
        IP=$(curl -s -4 --connect-timeout 5 "$svc" 2>/dev/null | tr -d '\n')
        if [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        fi
    done
    NODE_URL="http://${IP:-localhost}:$PORT"
fi

log "Node URL: $NODE_URL"

# Step 4: Create .env
log "Creating configuration..."
cat > .env << EOF
# NetMirror Agent Configuration
# Agent Mode - API only, no UI

AGENT_MODE=true

LISTEN_IP=0.0.0.0
HTTP_PORT=$PORT

# Node Identity
LOCATION=$NODE_LOCATION
LG_CURRENT_NAME=$NODE_NAME
LG_CURRENT_LOCATION=$NODE_LOCATION
LG_CURRENT_URL=$NODE_URL

# Features
DISPLAY_TRAFFIC=true
UTILITIES_PING=true
UTILITIES_MTR=true
UTILITIES_TRACEROUTE=true
UTILITIES_SPEEDTESTDOTNET=true
UTILITIES_FAKESHELL=true
UTILITIES_IPERF3=true
ENABLE_SPEEDTEST=true

# Storage
DATA_DIR=/data
EOF

success "Configuration created"

# Step 5: Create data directory
mkdir -p ./data

# Step 6: Stop existing container
CONTAINER_NAME="netmirror-agent-$PORT"
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log "Removing existing container: $CONTAINER_NAME"
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

# Step 7: Check/pull image
log "Checking image: $IMAGE"
if ! docker image inspect "$IMAGE" &>/dev/null; then
    log "Pulling image..."
    docker pull "$IMAGE" || error "Failed to pull image: $IMAGE"
fi

# Step 8: Start container
log "Starting container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart always \
    --network host \
    --env-file .env \
    -v "$(pwd)/data:/data" \
    "$IMAGE"

# Wait and verify
log "Waiting for startup..."
sleep 3

# Verify container is running by checking API response
RETRIES=5
for i in $(seq 1 $RETRIES); do
    if curl -s "http://localhost:$PORT/" 2>/dev/null | grep -q '"api":true'; then
        success "Container is running and API is responding"
        break
    fi
    if [ "$i" -eq "$RETRIES" ]; then
        warn "Container may still be starting. Check with: docker logs $CONTAINER_NAME"
    else
        sleep 2
    fi
done

# Step 9: Register with master
log "Registering with master node..."
REGISTER_RESPONSE=$(curl -s -X POST "$MASTER_URL/api/register" \
    -H "Content-Type: application/json" \
    -d "{\"token\":\"$TOKEN\",\"url\":\"$NODE_URL\"}" \
    2>/dev/null)

if echo "$REGISTER_RESPONSE" | grep -q '"success":true'; then
    success "Registered with master!"
else
    warn "Registration response: $REGISTER_RESPONSE"
    warn "Node running but registration may have failed"
fi

# Done
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Agent Deployment Complete!                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Name:${NC}       $NODE_NAME"
echo -e "  ${CYAN}Location:${NC}   $NODE_LOCATION"
echo -e "  ${CYAN}Node URL:${NC}   $NODE_URL"
echo -e "  ${CYAN}Master:${NC}     $MASTER_URL"
echo -e "  ${CYAN}Container:${NC}  $CONTAINER_NAME"
echo -e "  ${CYAN}Mode:${NC}       Agent (API only)"
echo ""
echo -e "${YELLOW}Commands:${NC}"
echo -e "  Logs:     docker logs -f $CONTAINER_NAME"
echo -e "  Restart:  docker restart $CONTAINER_NAME"
echo -e "  Stop:     docker stop $CONTAINER_NAME"
echo -e "  Remove:   docker rm -f $CONTAINER_NAME"
echo ""
