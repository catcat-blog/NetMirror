# NetMirror Deployment Scripts

This directory contains deployment scripts for NetMirror Looking Glass servers.

## Scripts

### deploy-agent.sh

Manual agent deployment script for advanced users.

```bash
./deploy-agent.sh \
  --master http://panel-ip:3000 \
  --token YOUR_TOKEN \
  --name "Tokyo Agent" \
  --location "Tokyo, JP" \
  --port 3000
```

Parameters:

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `--master` | Panel URL | Yes | - |
| `--token` | Registration token | Yes | - |
| `--name` | Node display name | No | Agent Node |
| `--location` | Node location | No | Unknown |
| `--port` | HTTP port | No | 3000 |
| `--url` | Custom public URL | No | Auto-detected |
| `--image` | Docker image | No | soyorins/netmirror-agent:latest |
| `--dir` | Deployment directory | No | ./netmirror-agent |

### install-software.sh

Installs required system tools (mtr, traceroute, etc.) in the container.

### install-speedtest.sh

Installs the official Speedtest CLI in the container.

## Recommended Deployment Method

Use the Panel's token-based deployment instead of manual scripts:

1. Access the Panel admin interface
2. Create a deployment token with node name and location
3. Copy the generated install script
4. Run on target server

The generated script handles everything automatically:
- Docker installation
- External IP detection
- Container setup
- Registration with panel

## Docker Images

| Image | Description |
|-------|-------------|
| `soyorins/netmirror-panel` | Full panel with web UI |
| `soyorins/netmirror-agent` | API-only agent (smaller) |

## Troubleshooting

### Container failed to start

```bash
# Check logs
docker logs netmirror-agent-3000

# Check if port is available
netstat -tlnp | grep 3000
```

### Registration failed

```bash
# Test panel connectivity
curl http://panel-ip:3000/

# Verify token
curl -X POST http://panel-ip:3000/api/register \
  -H "Content-Type: application/json" \
  -d '{"token":"YOUR_TOKEN","url":"http://agent-ip:3000"}'
```

### Docker permission denied

```bash
sudo usermod -aG docker $USER
# Then logout and login again
```
