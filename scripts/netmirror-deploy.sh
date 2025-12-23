#!/bin/bash

# NetMirror Auto Deployment Script
# Supports both master node and child node deployment with auto-registration

set -e

REPO_URL="https://raw.githubusercontent.com/catcat-blog/NetMirror/main/.env.example"
IMAGE="soyorins/netmirror:latest"

# Generate secure random API key
generate_api_key() {
    if command -v openssl &> /dev/null; then
        openssl rand -hex 32
    elif command -v head &> /dev/null && [[ -r /dev/urandom ]]; then
        head -c 32 /dev/urandom | xxd -p -c 32
    else
        # Fallback: use timestamp and hostname
        echo "netmirror-$(date +%s)-$(hostname | head -c 8)" | tr -d '\n'
    fi
}
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show help
show_help() {
    cat << EOF
NetMirror Auto Deployment Script

Usage:
    $0 [OPTIONS]

Options:
    --name NAME           Node name (required, unless using --token)
    --location LOCATION   Node location (required, unless using --token)
    --port PORT           HTTP port (default: 3000)
    --dir DIRECTORY       Deployment directory (default: ./netmirror-node)
    --master URL          Master node URL (optional, if not provided, deploys as master node)
    --admin-key KEY       Admin API key for auto-registration (optional, auto-generated for master nodes)
    --token TOKEN         One-time deploy token (generated from Admin panel - simplest method)
    --node-url URL        Custom node URL for registration (optional, defaults to http://localhost:PORT)
    --non-interactive     Skip all prompts (use with required params)
    -h, --help            Show this help

Examples:
    # One-click deployment with token (recommended for child nodes)
    $0 --token "eyJhbGci..." --port 3001 --non-interactive

    # Interactive mode (child node)
    $0

    # Deploy as master node
    $0 --name "Master Node" --location "Tokyo, JP" --port 3000 --non-interactive

    # Deploy master node with custom domain
    $0 --name "Master Node" --location "Tokyo, JP" --port 3000 --node-url "https://lg-master.example.com" --non-interactive

    # Deploy child node with master registration (legacy method)
    $0 --name "Tokyo Node" --location "Tokyo, JP" --master "http://master:3000" --admin-key "your-key" --non-interactive

    # Deploy child node with custom domain
    $0 --name "Tokyo Node" --location "Tokyo, JP" --master "http://master:3000" --admin-key "your-key" --node-url "https://lg-tokyo.example.com" --non-interactive

    # With custom deployment directory
    $0 --name "Tokyo Node" --location "Tokyo, JP" --dir "/opt/netmirror" --non-interactive

EOF
}

# Parse command line arguments
parse_args() {
    INTERACTIVE=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name)
                NODE_NAME="$2"
                shift 2
                ;;
            --location)
                NODE_LOCATION="$2"
                shift 2
                ;;
            --port)
                PORT="$2"
                shift 2
                ;;
            --dir)
                DEPLOY_DIR="$2"
                shift 2
                ;;
            --master)
                MASTER_URL="$2"
                shift 2
                ;;
            --admin-key)
                ADMIN_KEY="$2"
                shift 2
                ;;
            --token)
                DEPLOY_TOKEN="$2"
                shift 2
                ;;
            --node-url)
                CUSTOM_URL="$2"
                shift 2
                ;;
            --non-interactive)
                INTERACTIVE=false
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set defaults
    PORT=${PORT:-3000}
    DEPLOY_DIR=${DEPLOY_DIR:-./netmirror-node}

    # Token-based deployment mode
    TOKEN_MODE=false
    if [[ -n "$DEPLOY_TOKEN" ]]; then
        TOKEN_MODE=true
        # Token mode doesn't require name/location - they come from the token
        log "Token-based deployment mode detected"
    fi

    # Validate required parameters in non-interactive mode (unless using token)
    if [[ "$INTERACTIVE" == "false" && "$TOKEN_MODE" == "false" ]]; then
        if [[ -z "$NODE_NAME" ]]; then
            error "Missing required parameter: --name"
            exit 1
        fi
        if [[ -z "$NODE_LOCATION" ]]; then
            error "Missing required parameter: --location"
            exit 1
        fi
    fi
}

# Verification functions
verify_master_node() {
    local master_url="$1"
    
    if [[ -z "$master_url" ]]; then
        return 0  # No master node to verify
    fi
    
    log "Verifying master node connection: $master_url"
    
    # Test basic connectivity
    if ! curl -s --connect-timeout 10 --max-time 15 "$master_url/" >/dev/null 2>&1; then
        error "Cannot connect to master node: $master_url"
        return 1
    fi
    
    # Test if it's actually a NetMirror instance by checking /nodes endpoint
    if ! curl -s --connect-timeout 10 --max-time 15 "$master_url/nodes" >/dev/null 2>&1; then
        error "Master node does not appear to be a NetMirror instance (missing /nodes endpoint)"
        return 1
    fi
    
    success "Master node connection verified"
    return 0
}

verify_admin_key() {
    local master_url="$1"
    local admin_key="$2"
    
    if [[ -z "$master_url" || -z "$admin_key" ]]; then
        return 0  # No verification needed
    fi
    
    log "Verifying admin API key..."
    
    # Clean up the API key (remove any whitespace/newlines)
    admin_key=$(echo "$admin_key" | tr -d '\r\n\t ')
    
    # Test admin API access with a simple GET request to /api/admin/nodes/add
    # This endpoint exists and will return 400 for GET without parameters, but 401 for bad API key
    local test_url="$master_url/api/admin/nodes/add?api_key=$admin_key"
    log "Testing URL: $test_url"
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/verify_response \
        "$test_url" 2>/tmp/curl_error || echo "000")
    
    if [[ "$response" == "000" ]]; then
        error "Curl failed. Error details:"
        if [[ -f /tmp/curl_error ]]; then
            cat /tmp/curl_error
        fi
        return 1
    fi
    
    if [[ "$response" == "400" ]]; then
        # 400 means API key is valid but missing required parameters - that's expected
        success "Admin API key verified"
        return 0
    elif [[ "$response" == "401" ]]; then
        error "Invalid admin API key"
        return 1
    elif [[ "$response" == "404" ]]; then
        error "Admin API endpoint not found (check NetMirror version)"
        return 1
    else
        error "Failed to verify admin API key (HTTP $response)"
        if [[ -f /tmp/verify_response ]]; then
            log "Response body:"
            cat /tmp/verify_response
        fi
        return 1
    fi
    
    # Clean up temp files
    rm -f /tmp/verify_response /tmp/curl_error
}

# Verify and fetch token metadata from master node
verify_deploy_token() {
    local token="$1"
    local master_url="$2"

    if [[ -z "$token" || -z "$master_url" ]]; then
        return 1
    fi

    log "Verifying deploy token with master node..."

    # The token verification happens during registration
    # For now, just verify the master node is reachable
    if ! verify_master_node "$master_url"; then
        return 1
    fi

    success "Master node verified, token will be validated during registration"
    return 0
}

# Register node using one-time deploy token
register_with_token() {
    local token="$1"
    local master_url="$2"
    local node_url="$3"

    if [[ -z "$token" || -z "$master_url" || -z "$node_url" ]]; then
        error "Missing required parameters for token registration"
        return 1
    fi

    log "Registering node with master using deploy token..."
    log "Master URL: $master_url"
    log "Node URL: $node_url"

    # Send registration request to master node
    local response_file="/tmp/token_register_response"
    local error_file="/tmp/token_register_error"

    local http_code=$(curl -s -w "%{http_code}" -o "$response_file" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"token\": \"$token\", \"url\": \"$node_url\"}" \
        "$master_url/api/register" \
        2>"$error_file" || echo "000")

    if [[ "$http_code" == "000" ]]; then
        error "Failed to connect to master node"
        if [[ -f "$error_file" ]]; then
            cat "$error_file"
        fi
        rm -f "$response_file" "$error_file"
        return 1
    fi

    if [[ "$http_code" == "201" || "$http_code" == "200" ]]; then
        # Parse response to get node info
        if [[ -f "$response_file" ]]; then
            local response_data=$(cat "$response_file")
            # Try to extract node info from response using simple parsing
            TOKEN_NODE_NAME=$(echo "$response_data" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            TOKEN_NODE_LOCATION=$(echo "$response_data" | grep -o '"location"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"location"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        fi
        success "Node registered successfully with master!"
        rm -f "$response_file" "$error_file"
        return 0
    elif [[ "$http_code" == "400" ]]; then
        error "Invalid or expired token"
        if [[ -f "$response_file" ]]; then
            log "Response: $(cat "$response_file")"
        fi
        rm -f "$response_file" "$error_file"
        return 1
    elif [[ "$http_code" == "404" ]]; then
        error "Token not found - it may have already been used"
        rm -f "$response_file" "$error_file"
        return 1
    elif [[ "$http_code" == "409" ]]; then
        warn "Token already used"
        rm -f "$response_file" "$error_file"
        return 1
    else
        error "Registration failed (HTTP $http_code)"
        if [[ -f "$response_file" ]]; then
            log "Response: $(cat "$response_file")"
        fi
        rm -f "$response_file" "$error_file"
        return 1
    fi
}

# Interactive retry for master node URL
get_master_url() {
    while true; do
        if [[ "$INTERACTIVE" == "false" ]]; then
            # In non-interactive mode, just verify what we have
            if [[ -n "$MASTER_URL" ]]; then
                if ! verify_master_node "$MASTER_URL"; then
                    error "Master node verification failed in non-interactive mode"
                    exit 1
                fi
            fi
            break
        fi
        
        if [[ -z "$MASTER_URL" ]]; then
            read -p "Master node URL (optional, press Enter to skip): " MASTER_URL
        fi
        
        if [[ -z "$MASTER_URL" ]]; then
            log "No master node configured"
            break
        fi
        
        if verify_master_node "$MASTER_URL"; then
            break
        else
            warn "Master node verification failed"
            read -p "Try again? [Y/n]: " retry
            if [[ "$retry" =~ ^[Nn]$ ]]; then
                MASTER_URL=""
                break
            fi
            # Clear MASTER_URL to prompt again
            MASTER_URL=""
        fi
    done
}

# Interactive retry for admin key
get_admin_key() {
    if [[ -z "$MASTER_URL" ]]; then
        return  # No master node, no need for admin key
    fi
    
    while true; do
        if [[ "$INTERACTIVE" == "false" ]]; then
            # In non-interactive mode, just verify what we have
            if [[ -n "$ADMIN_KEY" ]]; then
                if ! verify_admin_key "$MASTER_URL" "$ADMIN_KEY"; then
                    error "Admin key verification failed in non-interactive mode"
                    exit 1
                fi
            fi
            break
        fi
        
        if [[ -z "$ADMIN_KEY" ]]; then
            echo "Configure registration with master node:"
            read -p "Admin API key (press Enter to skip auto-registration): " ADMIN_KEY
        fi
        
        if [[ -z "$ADMIN_KEY" ]]; then
            log "No admin key provided, will skip auto-registration"
            break
        fi
        
        if verify_admin_key "$MASTER_URL" "$ADMIN_KEY"; then
            break
        else
            warn "Admin key verification failed"
            read -p "Try again? [Y/n]: " retry
            if [[ "$retry" =~ ^[Nn]$ ]]; then
                ADMIN_KEY=""
                break
            fi
            # Clear ADMIN_KEY to prompt again
            ADMIN_KEY=""
        fi
    done
}

# Step 1: Check/Install Docker
check_docker() {
    log "Step 1: Checking Docker..."
    
    if ! command -v docker &> /dev/null; then
        warn "Docker not found. Installing Docker..."
        
        # Auto-install Docker on common distros
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            rm get-docker.sh
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            rm get-docker.sh
        else
            error "Please install Docker manually: https://docs.docker.com/get-docker/"
            exit 1
        fi
        
        # Add user to docker group
        sudo usermod -aG docker $USER
        warn "Please logout and login again, or run: newgrp docker"
    fi
    
    success "Docker is ready"
}

# Step 2: Generate environment file
setup_env() {
    log "Step 2: Setting up environment..."

    # Create deployment directory
    mkdir -p "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
    log "Using deployment directory: $(pwd)"

    # Check for environment variables from install script template
    if [[ -n "${TOKEN_MASTER_URL:-}" && -z "$MASTER_URL" ]]; then
        MASTER_URL="$TOKEN_MASTER_URL"
        log "Using master URL from environment: $MASTER_URL"
    fi

    # Token-based deployment mode
    if [[ "$TOKEN_MODE" == "true" ]]; then
        log "Token-based deployment mode"

        # Require master URL for token registration
        if [[ -z "$MASTER_URL" ]]; then
            if [[ "$INTERACTIVE" == "true" ]]; then
                read -p "Master node URL (required for token registration): " MASTER_URL
            else
                error "Master URL is required for token-based deployment. Use --master or set TOKEN_MASTER_URL"
                exit 1
            fi
        fi

        # Verify master node connectivity
        if ! verify_master_node "$MASTER_URL"; then
            error "Cannot connect to master node"
            exit 1
        fi

        # For token mode, node info comes from registration response
        # Set placeholder names until we get the real ones from registration
        NODE_NAME="${NODE_NAME:-Token Node}"
        NODE_LOCATION="${NODE_LOCATION:-Auto-configured}"
        DEPLOYMENT_MODE="token"

        log "Token deployment configured, node info will be set during registration"
        return  # Skip the rest of normal setup, will continue after container starts
    fi

    # Get node info (interactive mode only)
    if [[ "$INTERACTIVE" == "true" ]]; then
        if [[ -z "$NODE_NAME" ]]; then
            read -p "Node name (e.g. Tokyo Node): " NODE_NAME
        fi
        if [[ -z "$NODE_LOCATION" ]]; then
            read -p "Node location (e.g. Tokyo, JP): " NODE_LOCATION
        fi
        if [[ -z "$PORT" ]]; then
            read -p "HTTP port [3000]: " PORT
            PORT=${PORT:-3000}
        fi
    fi

    # Determine deployment mode: master or child node
    DEPLOYMENT_MODE="child"
    if [[ -z "$MASTER_URL" ]]; then
        DEPLOYMENT_MODE="master"
        log "Detected master node deployment (no --master URL provided)"

        # For master nodes, ensure we have an admin API key
        if [[ -z "$ADMIN_KEY" ]]; then
            if [[ "$INTERACTIVE" == "true" ]]; then
                read -p "Generate API key automatically? [Y/n]: " auto_gen
                if [[ ! "$auto_gen" =~ ^[Nn]$ ]]; then
                    ADMIN_KEY=$(generate_api_key)
                    success "Generated API key: $ADMIN_KEY"
                else
                    read -p "Enter custom API key: " ADMIN_KEY
                fi
            else
                # Non-interactive mode: always generate API key for master nodes
                ADMIN_KEY=$(generate_api_key)
                success "Generated API key: $ADMIN_KEY"
            fi
        fi
    else
        log "Detected child node deployment (master URL: $MASTER_URL)"
        # Get and verify master node URL
        get_master_url

        # Get and verify admin key
        get_admin_key
    fi
    
    # Get local IP
    LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    log "Downloading environment template from repository..."
    
    # Download and process .env.example
    if curl -s "$REPO_URL" -o .env.tmp; then
        # Remove comments and empty lines, keep only variable definitions
        grep -v '^#' .env.tmp | grep -v '^$' | grep '=' > .env.clean || true
        rm .env.tmp
    else
        warn "Failed to download template, using built-in template"
        # Fallback built-in template
        cat > .env.clean << 'EOF'
LISTEN_IP=0.0.0.0
HTTP_PORT=3000
LOCATION=BGP
PUBLIC_IPV4=
PUBLIC_IPV6=
LOGO=<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="2"/><path d="m16.24 7.76-1.41 1.41M15.76 16.24l1.41 1.41M7.76 16.24l1.41-1.41M7.76 7.76l1.41 1.41M12 3v6M12 15v6M3 12h6M15 12h6"/></svg>
LOGO_TYPE=auto
DISPLAY_TRAFFIC=true
ENABLE_SPEEDTEST=true
UTILITIES_PING=true
UTILITIES_MTR=true
UTILITIES_TRACEROUTE=true
UTILITIES_SPEEDTESTDOTNET=true
UTILITIES_FAKESHELL=true
UTILITIES_IPERF3=true
SPEEDTEST_FILE_LIST=100MB 1GB 10GB
UTILITIES_IPERF3_PORT_MIN=30000
UTILITIES_IPERF3_PORT_MAX=31000
DATA_DIR=/data
LG_NODES=
LG_CURRENT_URL=
LG_CURRENT_NAME=
LG_CURRENT_LOCATION=
ADMIN_API_KEY=
EOF
    fi
    
    # Create final .env file with custom values
    cat > .env << EOF
# NetMirror Node Configuration
# Generated: $(date)
EOF
    
    # Process template and set custom values
    while IFS='=' read -r key value; do
        case "$key" in
            "HTTP_PORT") echo "HTTP_PORT=$PORT" >> .env ;;
            "LG_CURRENT_NAME") echo "LG_CURRENT_NAME=$NODE_NAME" >> .env ;;
            "LG_CURRENT_LOCATION") echo "LG_CURRENT_LOCATION=$NODE_LOCATION" >> .env ;;
            "LG_CURRENT_URL") echo "LG_CURRENT_URL=http://$LOCAL_IP:$PORT" >> .env ;;
            "DATA_DIR") echo "DATA_DIR=/data" >> .env ;;
            "LOCATION") echo "LOCATION=$NODE_LOCATION" >> .env ;;
            "LG_NODES") echo "LG_NODES=" >> .env ;;  # Clear default nodes to avoid auto-migration
            *) echo "$key=$value" >> .env ;;
        esac
    done < .env.clean
    
    # Add master node config if provided
    if [[ -n "$MASTER_URL" ]]; then
        echo >> .env
        echo "# Master Node Integration" >> .env
        echo "MASTER_NODE_URL=$MASTER_URL" >> .env
        echo "NODE_AUTO_REGISTER=true" >> .env
    fi
    
    # Add admin API key (for master nodes or child nodes with API access)
    if [[ -n "$ADMIN_KEY" ]]; then
        echo >> .env
        echo "# Admin API Configuration" >> .env
        echo "ADMIN_API_KEY=$ADMIN_KEY" >> .env
    fi
    
    rm .env.clean
    success "Environment file created: .env"
}

# Setup environment for token-based deployment
setup_env_token() {
    log "Setting up environment for token-based deployment..."

    # Create deployment directory
    mkdir -p "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
    log "Using deployment directory: $(pwd)"

    # Get local IP
    LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

    # Download env template or use built-in
    log "Downloading environment template from repository..."
    if curl -s "$REPO_URL" -o .env.tmp; then
        grep -v '^#' .env.tmp | grep -v '^$' | grep '=' > .env.clean || true
        rm .env.tmp
    else
        warn "Failed to download template, using built-in template"
        cat > .env.clean << 'EOF'
LISTEN_IP=0.0.0.0
HTTP_PORT=3000
LOCATION=BGP
PUBLIC_IPV4=
PUBLIC_IPV6=
LOGO=<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="2"/><path d="m16.24 7.76-1.41 1.41M15.76 16.24l1.41 1.41M7.76 16.24l1.41-1.41M7.76 7.76l1.41 1.41M12 3v6M12 15v6M3 12h6M15 12h6"/></svg>
LOGO_TYPE=auto
DISPLAY_TRAFFIC=true
ENABLE_SPEEDTEST=true
UTILITIES_PING=true
UTILITIES_MTR=true
UTILITIES_TRACEROUTE=true
UTILITIES_SPEEDTESTDOTNET=true
UTILITIES_FAKESHELL=true
UTILITIES_IPERF3=true
SPEEDTEST_FILE_LIST=100MB 1GB 10GB
UTILITIES_IPERF3_PORT_MIN=30000
UTILITIES_IPERF3_PORT_MAX=31000
DATA_DIR=/data
LG_NODES=
LG_CURRENT_URL=
LG_CURRENT_NAME=
LG_CURRENT_LOCATION=
ADMIN_API_KEY=
EOF
    fi

    # Create .env file with placeholder values (will be updated after registration)
    cat > .env << EOF
# NetMirror Node Configuration (Token Deployment)
# Generated: $(date)
EOF

    # Process template and set values
    while IFS='=' read -r key value; do
        case "$key" in
            "HTTP_PORT") echo "HTTP_PORT=$PORT" >> .env ;;
            "LG_CURRENT_NAME") echo "LG_CURRENT_NAME=$NODE_NAME" >> .env ;;
            "LG_CURRENT_LOCATION") echo "LG_CURRENT_LOCATION=$NODE_LOCATION" >> .env ;;
            "LG_CURRENT_URL") echo "LG_CURRENT_URL=http://$LOCAL_IP:$PORT" >> .env ;;
            "DATA_DIR") echo "DATA_DIR=/data" >> .env ;;
            "LOCATION") echo "LOCATION=$NODE_LOCATION" >> .env ;;
            "LG_NODES") echo "LG_NODES=" >> .env ;;
            *) echo "$key=$value" >> .env ;;
        esac
    done < .env.clean

    # Add master node config
    echo >> .env
    echo "# Master Node Integration (Token Deployment)" >> .env
    echo "MASTER_NODE_URL=$MASTER_URL" >> .env
    echo "NODE_AUTO_REGISTER=true" >> .env

    rm .env.clean
    success "Environment file created: .env"
}

# Step 3: Run container
run_container() {
    log "Step 3: Starting NetMirror container..."
    
    # Create data directory
    mkdir -p ./data
    
    # Download additional config files from repository
    log "Downloading project configuration files..."
    
    # Download .air.toml for hot reload (optional)
    curl -s "https://raw.githubusercontent.com/catcat-blog/NetMirror/main/.air.toml" -o .air.toml 2>/dev/null || true
    
    # Stop existing container
    CONTAINER_NAME="netmirror-node-$PORT"
    if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
        log "Stopping existing container..."
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi
    
    # Pull latest image
    log "Pulling latest image: $IMAGE"
    docker pull "$IMAGE"
    
    # Create docker-compose.yml based on project template
    log "Creating docker-compose configuration..."
    cat > docker-compose.yml << EOF
version: '3.3'

services:
  netmirror:
    image: $IMAGE
    container_name: $CONTAINER_NAME
    restart: always
    network_mode: host
    env_file:
      - .env
    volumes:
      - ./data:/data
      - ./.air.toml:/app/.air.toml
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:$PORT/"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF
    
    # Start with docker compose (v2) first, then docker-compose (v1), finally docker run
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        log "Starting with docker compose (v2)..."
        docker compose up -d
    elif command -v docker-compose &> /dev/null; then
        log "Starting with docker-compose (v1)..."
        docker-compose up -d
    else
        log "Starting with docker run (network_mode=host)..."
        docker run -d \
            --name "$CONTAINER_NAME" \
            --restart always \
            --network host \
            --env-file .env \
            -v "$(pwd)/data:/data" \
            -v "$(pwd)/.air.toml:/app/.air.toml" \
            --health-cmd="wget --quiet --tries=1 --spider http://localhost:$PORT/" \
            --health-interval=30s \
            --health-timeout=10s \
            --health-retries=3 \
            --log-driver json-file \
            --log-opt max-size=10m \
            --log-opt max-file=3 \
            "$IMAGE"
    fi
    
    # Wait a moment for startup
    sleep 3
    
    if docker ps | grep -q "$CONTAINER_NAME"; then
        success "Container started successfully!"
        success "Access URL: http://localhost:$PORT (using host network)"
    else
        error "Container failed to start. Check logs: docker logs $CONTAINER_NAME"
        exit 1
    fi
}

# Step 4: Report to master node (for child nodes) or self-register master node
report_to_master() {
    # Token-based registration
    if [[ "$DEPLOYMENT_MODE" == "token" ]]; then
        log "Step 4: Registering with master node using deploy token..."

        # Determine node URL for registration
        if [[ -n "$CUSTOM_URL" ]]; then
            NODE_URL="$CUSTOM_URL"
        else
            # Get external IP
            EXTERNAL_IP=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 ipinfo.io/ip 2>/dev/null || echo "localhost")
            NODE_URL="http://$EXTERNAL_IP:$PORT"
        fi

        # Register with token
        if register_with_token "$DEPLOY_TOKEN" "$MASTER_URL" "$NODE_URL"; then
            # Update node info from registration response
            if [[ -n "$TOKEN_NODE_NAME" ]]; then
                NODE_NAME="$TOKEN_NODE_NAME"
            fi
            if [[ -n "$TOKEN_NODE_LOCATION" ]]; then
                NODE_LOCATION="$TOKEN_NODE_LOCATION"
            fi

            # Update .env file with actual node info
            if [[ -n "$TOKEN_NODE_NAME" || -n "$TOKEN_NODE_LOCATION" ]]; then
                log "Updating .env with node info from registration..."
                sed -i "s/^LG_CURRENT_NAME=.*/LG_CURRENT_NAME=$NODE_NAME/" .env
                sed -i "s/^LG_CURRENT_LOCATION=.*/LG_CURRENT_LOCATION=$NODE_LOCATION/" .env
                sed -i "s/^LOCATION=.*/LOCATION=$NODE_LOCATION/" .env
            fi

            success "=== Token Deployment Complete! ==="
            echo
            echo -e "${GREEN}Node Information:${NC}"
            echo "  Name: $NODE_NAME"
            echo "  Location: $NODE_LOCATION"
            echo "  URL: $NODE_URL"
            echo "  Master Node: $MASTER_URL"
            echo "  Deployment Path: $(pwd)"
            echo
        else
            error "Token registration failed!"
            echo
            echo "The deploy token may have expired or already been used."
            echo "Please generate a new token from the Admin panel."
            exit 1
        fi
        return
    fi

    if [[ "$DEPLOYMENT_MODE" == "master" ]]; then
        log "Step 4: Self-registering master node..."
        
        # Get external IP for master node URL
        EXTERNAL_IP=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 ipinfo.io/ip 2>/dev/null || echo "localhost")
        
        # Use custom URL if provided, otherwise use auto-detected IP
        if [[ -n "$CUSTOM_URL" ]]; then
            MASTER_NODE_URL="$CUSTOM_URL"
        else
            MASTER_NODE_URL="http://$EXTERNAL_IP:$PORT"
        fi
        
        # Self-register the master node (always use localhost for self-registration)
        ENCODED_NAME=$(printf '%s' "$NODE_NAME" | sed 's/ /+/g')
        ENCODED_LOCATION=$(printf '%s' "$NODE_LOCATION" | sed 's/ /+/g')
        
        log "Self-registering master node to its own API..."
        RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/master_register_response \
            "http://localhost:$PORT/api/admin/nodes/add?api_key=$ADMIN_KEY&name=$ENCODED_NAME&location=$ENCODED_LOCATION&url=$MASTER_NODE_URL" \
            2>/tmp/master_register_error || echo "000")
            
        if [[ "$RESPONSE" == "201" ]] || [[ "$RESPONSE" == "200" ]]; then
            success "Master node self-registered successfully!"
        elif [[ "$RESPONSE" == "409" ]]; then
            warn "Master node already exists in database"
        else
            warn "Failed to self-register master node (HTTP $RESPONSE), but deployment continues"
            if [[ -f /tmp/master_register_response ]]; then
                log "Response: $(cat /tmp/master_register_response)"
            fi
        fi
        
        rm -f /tmp/master_register_response /tmp/master_register_error
        
        success "=== Master Node Deployed Successfully! ==="
        echo
        echo -e "${GREEN}Node Information:${NC}"
        echo "  Name: $NODE_NAME"
        echo "  Location: $NODE_LOCATION"
        echo "  URL: $MASTER_NODE_URL"
        echo "  Admin Panel: $MASTER_NODE_URL (click settings icon ⚙️)"
        echo "  Deployment Path: $(pwd)"
        echo
        return
    fi
    
    # Child node registration logic (existing code)
    if [[ -z "$MASTER_URL" || -z "$ADMIN_KEY" ]]; then
        if [[ -n "$MASTER_URL" && -z "$ADMIN_KEY" ]]; then
            warn "Master node configured but no admin key provided"
            echo "Manual registration info:"
            echo "  Master Node: $MASTER_URL"
            echo "  Node Name: $NODE_NAME"
            echo "  Node Location: $NODE_LOCATION" 
            echo "  Node URL: http://localhost:$PORT"
        fi
        return
    fi
    
    log "Step 4: Registering with master node..."
    
    # Clean up the API key (remove any whitespace/newlines)
    ADMIN_KEY=$(echo "$ADMIN_KEY" | tr -d '\r\n\t ')
    
    # Get custom URL if provided
    if [[ -n "$CUSTOM_URL" ]]; then
        NODE_URL="$CUSTOM_URL"
    else
        NODE_URL="http://localhost:$PORT"
    fi
    
    # URL encode the parameters (simpler approach)
    ENCODED_NAME=$(printf '%s' "$NODE_NAME" | sed 's/ /+/g')
    ENCODED_LOCATION=$(printf '%s' "$NODE_LOCATION" | sed 's/ /+/g')
    ENCODED_URL="$NODE_URL"
    
    # Try to register with master node using GET request
    log "Attempting registration..."
    log "Request: $MASTER_URL/api/admin/nodes/add?api_key=$ADMIN_KEY&name=$ENCODED_NAME&location=$ENCODED_LOCATION&url=$ENCODED_URL"
    
    RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/register_response \
        "$MASTER_URL/api/admin/nodes/add?api_key=$ADMIN_KEY&name=$ENCODED_NAME&location=$ENCODED_LOCATION&url=$ENCODED_URL" \
        2>/tmp/register_error || echo "000")
    
    if [[ "$RESPONSE" == "000" ]]; then
        error "Curl failed during registration. Error details:"
        if [[ -f /tmp/register_error ]]; then
            cat /tmp/register_error
        fi
        return 1
    fi
    
    if [[ "$RESPONSE" == "201" ]] || [[ "$RESPONSE" == "200" ]]; then
        success "Successfully registered with master node!"
        success "Registered URL: $NODE_URL"
    elif [[ "$RESPONSE" == "409" ]]; then
        warn "Node already exists in master node"
    else
        error "Registration failed (HTTP $RESPONSE)"
        if [[ -f /tmp/register_response ]]; then
            log "Response body:"
            cat /tmp/register_response
        fi
    fi
    
    # Clean up temp files
    rm -f /tmp/register_response /tmp/register_error
}

# Main execution
main() {
    # Parse command line arguments
    parse_args "$@"
    
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════╗"
    echo "║        NetMirror Auto Deploy         ║"
    echo "║    Master & Child Node Deployment    ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    if [[ "$INTERACTIVE" == "false" ]]; then
        log "Running in non-interactive mode"
        if [[ "$TOKEN_MODE" == "true" ]]; then
            log "Token-based deployment on port $PORT"
        else
            log "Node: $NODE_NAME ($NODE_LOCATION) on port $PORT"
        fi
        log "Deploy to: $DEPLOY_DIR"
        if [[ -n "$MASTER_URL" ]]; then
            log "Master node: $MASTER_URL"
        fi
        echo
    fi

    check_docker

    # Use appropriate setup function based on deployment mode
    if [[ "$TOKEN_MODE" == "true" ]]; then
        setup_env_token
    else
        setup_env
    fi

    run_container
    report_to_master
    
    echo
    success "=== Deployment Complete! ==="
    echo
    
    if [[ "$DEPLOYMENT_MODE" == "master" ]]; then
        echo -e "${GREEN}Master Node Information:${NC}"
        echo "  Name: $NODE_NAME"
        echo "  Location: $NODE_LOCATION"
        echo "  Access URL: http://localhost:$PORT"
        echo "  Admin Panel: Click the settings icon (⚙️) in bottom-right corner"
        echo "  Deployment Path: $(pwd)"
        echo
        echo -e "${YELLOW}🔑 Admin API Key:${NC}"
        echo "  $ADMIN_KEY"
        echo
        echo -e "${GREEN}📦 Child Node Deployment Command:${NC}"
        echo
        echo -e "${YELLOW}Basic Deployment (uses auto-detected IP):${NC}"
        echo "curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- \\"
        echo "  --name \"Child Node Name\" \\"
        echo "  --location \"Child Location\" \\"
        echo "  --port \"3001\" \\"
        echo "  --master \"$MASTER_NODE_URL\" \\"
        echo "  --admin-key \"$ADMIN_KEY\" \\"
        echo "  --non-interactive"
        echo
        echo -e "${YELLOW}With Custom Domain/URL (Recommended):${NC}"
        echo "curl -fsSL https://raw.githubusercontent.com/catcat-blog/NetMirror/main/scripts/netmirror-deploy.sh | bash -s -- \\"
        echo "  --name \"Child Node Name\" \\"
        echo "  --location \"Child Location\" \\"
        echo "  --port \"3001\" \\"
        echo "  --master \"$MASTER_NODE_URL\" \\"
        echo "  --admin-key \"$ADMIN_KEY\" \\"
        echo "  --node-url \"https://your-domain.com\" \\"
        echo "  --non-interactive"
        echo
        echo -e "${BLUE}💡 Important Notes:${NC}"
        echo "  • Replace 'Child Node Name', 'Child Location', and port number with actual values"
        echo "  • Use --node-url if you have a custom domain, reverse proxy, or CDN"
        echo "  • The node-url should be the public-facing URL that users will access"
        echo "  • Example: --node-url \"https://lg-singapore.example.com\""
        echo
        echo -e "${GREEN}🔑 One-Click Deployment (Recommended):${NC}"
        echo "  1. Open Admin Panel: $MASTER_NODE_URL (click settings icon)"
        echo "  2. Click 'Deploy Tokens' and create a new token"
        echo "  3. Copy the install command and run on child server"
        echo "  4. The node auto-registers with pre-configured name and location"
        echo
    elif [[ "$DEPLOYMENT_MODE" == "token" ]]; then
        # Token deployment info already printed in report_to_master
        echo -e "${GREEN}Token-based Deployment Summary:${NC}"
        echo "  Name: $NODE_NAME"
        echo "  Location: $NODE_LOCATION"
        echo "  Master Node: $MASTER_URL"
        echo "  Deployment Path: $(pwd)"
        echo
    else
        echo -e "${GREEN}Child Node Information:${NC}"
        echo "  Name: $NODE_NAME"
        echo "  Location: $NODE_LOCATION"
        echo "  URL: http://localhost:$PORT (host network mode)"
        echo "  Master Node: $MASTER_URL"
        echo "  Deployment Path: $(pwd)"
        echo
    fi
    echo -e "${GREEN}Management Commands:${NC}"
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        echo "  View logs: docker compose logs -f"
        echo "  Stop: docker compose down"
        echo "  Restart: docker compose restart"
        echo "  Remove: docker compose down && docker rmi $IMAGE"
    elif command -v docker-compose &> /dev/null; then
        echo "  View logs: docker-compose logs -f"
        echo "  Stop: docker-compose down"
        echo "  Restart: docker-compose restart"
        echo "  Remove: docker-compose down && docker rmi $IMAGE"
    else
        echo "  View logs: docker logs -f netmirror-node-$PORT"
        echo "  Stop: docker stop netmirror-node-$PORT"
        echo "  Restart: docker restart netmirror-node-$PORT"
        echo "  Remove: docker rm -f netmirror-node-$PORT"
    fi
    echo
    echo -e "${YELLOW}Files Created:${NC}"
    echo "  Configuration: $(pwd)/.env"
    echo "  Docker Compose: $(pwd)/docker-compose.yml"
    echo "  Air Config: $(pwd)/.air.toml"
    echo "  Data directory: $(pwd)/data"
    echo
    echo -e "${YELLOW}Next Steps:${NC}"  
    echo "  1. Test the web interface at http://localhost:$PORT"
    echo "  2. Verify node appears in master node admin panel"
    echo "  3. Run network diagnostics to test functionality"
}

# Check if running as root for Docker installation
if [[ $EUID -eq 0 ]] && [[ "${1:-}" != "--allow-root" ]]; then
    # Check if we're in non-interactive mode by looking for --non-interactive flag
    NON_INTERACTIVE_ROOT=false
    for arg in "$@"; do
        if [[ "$arg" == "--non-interactive" ]]; then
            NON_INTERACTIVE_ROOT=true
            break
        fi
    done
    
    if [[ "$NON_INTERACTIVE_ROOT" == "true" ]]; then
        warn "Running as root in non-interactive mode. Files will be owned by root."
    else
        warn "Running as root. This script will create files owned by root."
        if read -t 10 -p "Continue? Add --allow-root to skip this check. [y/N]: " confirm 2>/dev/null; then
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            warn "Cannot read input (possibly running via curl). Continuing as root..."
        fi
    fi
fi

main "$@"