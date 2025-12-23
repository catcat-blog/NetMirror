# NetMirror - 现代化的 Looking-glass 服务器

[![Docker Pulls](https://img.shields.io/docker/pulls/soyorins/netmirror-panel)](https://hub.docker.com/r/soyorins/netmirror-panel)
[![License](https://img.shields.io/badge/license-Apache%202.0%20%2B%20Commons%20Clause-blue)](LICENSE)

NetMirror 是一个功能丰富的现代 Looking-glass 服务器，拥有美观的 Web 界面，用于网络诊断和性能测试。

## 架构

NetMirror 采用 Panel + Agent 架构：

```
                    ┌─────────────────────────────────────┐
                    │           Panel (主节点)             │
                    │  - 完整 Web UI                       │
                    │  - 管理界面                          │
                    │  - Token 管理                        │
                    │  - 节点注册                          │
                    └──────────────┬──────────────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
           ▼                       ▼                       ▼
┌─────────────────────┐ ┌─────────────────────┐ ┌─────────────────────┐
│   Agent (东京)       │ │   Agent (伦敦)       │ │   Agent (新加坡)     │
│   - 仅 API          │ │   - 仅 API          │ │   - 仅 API          │
│   - 无 UI           │ │   - 无 UI           │ │   - 无 UI           │
│   - 自动注册         │ │   - 自动注册         │ │   - 自动注册         │
└─────────────────────┘ └─────────────────────┘ └─────────────────────┘
```

- **Panel**: 完整功能的主节点，包含 Web UI、管理面板和 Token 管理
- **Agent**: 轻量级 API 节点，自动向 Panel 注册

## 功能特性

- 网络工具：Ping、iPerf3、MTR、Traceroute、Speedtest
- 实时流量：网络接口流量实时监控
- 交互式 Shell：安全的模拟 Shell 环境
- Token 部署：一键 Agent 部署和自动注册
- 管理面板：基于 Web 的节点和 Token 管理
- 现代 UI：基于 Vue.js 和 Tailwind CSS 的响应式界面

## 快速开始

### 部署 Panel（主节点）

```bash
docker run -d \
  --name netmirror-panel \
  --network host \
  -e ADMIN_API_KEY=your-secret-key \
  -e HTTP_PORT=3000 \
  -v ./data:/data \
  soyorins/netmirror-panel:latest
```

访问面板：`http://your-server-ip:3000`

### 部署 Agent 节点

1. 打开 Panel 的管理界面（右下角设置图标）
2. 进入 "Deploy Tokens" 部分
3. 点击 "Create Token" 设置节点名称和位置
4. 复制生成的安装脚本
5. 在目标服务器运行脚本：

```bash
curl -fsSL 'GENERATED_SCRIPT_URL' | bash
```

Agent 会自动：
- 安装 Docker（如果需要）
- 检测外部 IP 地址
- 启动 Agent 容器
- 向 Panel 注册

### 手动 Agent 部署

```bash
docker run -d \
  --name netmirror-agent \
  --network host \
  -e AGENT_MODE=true \
  -e HTTP_PORT=3000 \
  soyorins/netmirror-agent:latest
```

然后通过 API 手动注册：
```bash
curl -X POST "http://panel:3000/api/register" \
  -H "Content-Type: application/json" \
  -d '{"token":"YOUR_TOKEN","url":"http://agent-ip:3000"}'
```

## Docker 镜像

| 镜像 | 描述 | 大小 |
|------|------|------|
| `soyorins/netmirror-panel` | 完整 Panel（带 UI） | ~100MB |
| `soyorins/netmirror-agent` | 仅 API Agent | ~85MB |

支持架构：`linux/amd64`, `linux/arm64`

## 配置

### Panel 配置

| 变量 | 默认值 | 描述 |
|------|--------|------|
| `HTTP_PORT` | `80` | 服务端口 |
| `LISTEN_IP` | `0.0.0.0` | 监听地址 |
| `ADMIN_API_KEY` | - | 管理面板访问必需 |
| `LOCATION` | 自动检测 | 服务器位置描述 |
| `DATA_DIR` | `/data` | 数据存储目录 |

### 功能开关

| 变量 | 默认值 | 描述 |
|------|--------|------|
| `DISPLAY_TRAFFIC` | `true` | 实时流量显示 |
| `ENABLE_SPEEDTEST` | `true` | 速度测试功能 |
| `UTILITIES_PING` | `true` | Ping 工具 |
| `UTILITIES_MTR` | `true` | MTR 工具 |
| `UTILITIES_TRACEROUTE` | `true` | Traceroute 工具 |
| `UTILITIES_FAKESHELL` | `true` | 模拟 Shell |
| `UTILITIES_IPERF3` | `true` | iPerf3 服务器 |

### Agent 配置

| 变量 | 默认值 | 描述 |
|------|--------|------|
| `AGENT_MODE` | `true` | Agent 模式（自动设置） |
| `HTTP_PORT` | `3000` | API 端口 |
| `LG_CURRENT_NAME` | - | 节点显示名称 |
| `LG_CURRENT_LOCATION` | - | 节点位置 |
| `LG_CURRENT_URL` | 自动检测 | 节点公开 URL |

## 管理面板

点击右下角浮动按钮中的设置图标访问管理面板。

### 节点管理

- 查看所有注册节点的状态
- 编辑节点名称和位置（URL 在注册时设置）
- 删除节点
- 测试所有节点的连接性

### Token 管理

- 创建部署 Token（设置名称、位置和过期时间）
- 生成一键安装脚本
- 查看和撤销活动 Token

## API 端点

### 公开

| 端点 | 描述 |
|------|------|
| `GET /` | 服务器信息 |
| `GET /nodes` | 节点列表 |
| `GET /nodes/latency` | 延迟测试 |

### 网络工具（需要 session）

| 端点 | 描述 |
|------|------|
| `GET /method/ping?host=...` | Ping |
| `GET /method/mtr?host=...` | MTR |
| `GET /method/traceroute?host=...` | Traceroute |

### 管理（需要 API key）

| 端点 | 描述 |
|------|------|
| `GET /api/admin/nodes` | 节点列表 |
| `PUT /api/admin/nodes/:id` | 更新节点 |
| `DELETE /api/admin/nodes/:id` | 删除节点 |
| `POST /api/admin/tokens` | 创建 Token |
| `DELETE /api/admin/tokens/:id` | 删除 Token |
| `POST /api/register` | Agent 注册（Token 认证）|

## 从源码构建

### 前置条件

- Go 1.21+
- Node.js 18+
- Docker

### 构建步骤

```bash
# 构建前端
cd ui
npm install
npm run build

# 构建后端
cd ../backend
go build -o ../netmirror

# 运行
./netmirror
```

### Docker 构建

```bash
# 构建 Panel 镜像
docker build -f Dockerfile -t netmirror-panel .

# 构建 Agent 镜像
docker build -f Dockerfile.agent -t netmirror-agent .
```

## 许可证

Apache License, Version 2.0 with Commons Clause Restriction.
