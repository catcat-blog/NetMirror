package als

import (
	"fmt"
	"io/fs"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/X-Zero-L/als/als/controller"
	"github.com/X-Zero-L/als/als/controller/cache"
	"github.com/X-Zero-L/als/als/controller/iperf3"
	"github.com/X-Zero-L/als/als/controller/nettools"
	"github.com/X-Zero-L/als/als/controller/nodes"
	"github.com/X-Zero-L/als/als/controller/ping"
	"github.com/X-Zero-L/als/als/controller/session"
	"github.com/X-Zero-L/als/als/controller/shell"
	"github.com/X-Zero-L/als/als/controller/speedtest"
	"github.com/X-Zero-L/als/als/controller/tokens"
	"github.com/X-Zero-L/als/config"
	iEmbed "github.com/X-Zero-L/als/embed"
)

func SetupHttpRoute(e *gin.Engine) {
	// Add CORS middleware to allow cross-origin requests
	e.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With, session, X-Api-Key")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	e.GET("/session", session.Handle)

	// Node management endpoints (no session required for cross-node functionality)
	// Node management API (public endpoints)
	e.GET("/nodes", nodes.GetNodes)
	e.GET("/nodes/current", nodes.GetNodeConfig)
	e.GET("/nodes/latency", nodes.TestLatency)
	
	// Node management API (admin endpoints with API key authentication)
	admin := e.Group("/api/admin")
	admin.Use(nodes.RequireApiKey)
	{
		// Node management
		admin.POST("/nodes", nodes.CreateNode)
		admin.GET("/nodes/:id", nodes.GetNodeDetail)
		admin.PUT("/nodes/:id", nodes.UpdateNode)
		admin.DELETE("/nodes/:id", nodes.DeleteNode)

		// Token management (for one-click deployment)
		admin.POST("/tokens", tokens.CreateToken)
		admin.GET("/tokens", tokens.ListTokens)
		admin.DELETE("/tokens/:id", tokens.DeleteToken)
		admin.GET("/install-script/:token", tokens.GetInstallScript)
	}

	// Public node registration endpoint (token-based, no admin key required)
	e.POST("/api/register", tokens.RegisterNode)
	
	v1 := e.Group("/method", controller.MiddlewareSessionOnHeader())
	{
		if config.Config.FeatureIperf3 {
			v1.GET("/iperf3/server", iperf3.Handle)
		}

		if config.Config.FeaturePing {
			v1.GET("/ping", ping.Handle)
			v1.GET("/ping6", ping.HandlePing6)
		}

		if config.Config.FeatureMTR {
			v1.GET("/mtr", nettools.HandleNetworkTool("mtr"))
			v1.GET("/mtr6", nettools.HandleNetworkTool("mtr6"))
		}

		if config.Config.FeatureTraceroute {
			v1.GET("/traceroute", nettools.HandleNetworkTool("traceroute"))
			v1.GET("/traceroute6", nettools.HandleNetworkTool("traceroute6"))
		}

		if config.Config.FeatureSpeedtestDotNet {
			v1.GET("/speedtest_dot_net", speedtest.HandleSpeedtestDotNet)
		}

		if config.Config.FeatureIfaceTraffic {
			v1.GET("/cache/interfaces", cache.UpdateInterfaceCache)
		}
	}

	session := e.Group("/session/:session", controller.MiddlewareSessionOnUrl())
	{
		if config.Config.FeatureShell {
			session.GET("/shell", shell.HandleNewShell)
		}
	}

	speedtestRoute := session.Group("/speedtest", controller.MiddlewareSessionOnUrl())
	{
		if config.Config.FeatureFileSpeedtest {
			speedtestRoute.GET("/file/:filename", speedtest.HandleFakeFile)
		}

		if config.Config.FeatureLibrespeed {
			speedtestRoute.GET("/download", speedtest.HandleDownload)
			speedtestRoute.POST("/upload", speedtest.HandleUpload)
		}
	}

	// Static file routes - skip in Agent mode
	if !config.Config.AgentMode {
		e.Any("/assets/:filename", func(c *gin.Context) {
			filePath := c.Request.RequestURI
			filePath = filePath[1:]
			handleStatisFile(filePath, c)
		})

		e.GET("/css/:filename", func(c *gin.Context) {
			filePath := c.Request.RequestURI
			filePath = filePath[1:]
			handleStatisFile(filePath, c)
		})

		e.GET("/js/:filename", func(c *gin.Context) {
			filePath := c.Request.RequestURI
			filePath = filePath[1:]
			handleStatisFile(filePath, c)
		})

		e.GET("/", func(c *gin.Context) {
			handleIndexHTML(c)
		})

		e.GET("/speedtest_worker.js", func(c *gin.Context) {
			handleStatisFile("speedtest_worker.js", c)
		})

		e.GET("/favicon.ico", func(c *gin.Context) {
			handleFavicon(c)
		})
	} else {
		// Agent mode: return JSON info on root path
		e.GET("/", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"mode":     "agent",
				"name":     config.Config.Location,
				"version":  "2.2.0",
				"api":      true,
				"ui":       false,
			})
		})
	}
}

func handleStatisFile(filePath string, c *gin.Context) {
	uiFs := iEmbed.UIStaticFiles
	subFs, _ := fs.Sub(uiFs, "ui")
	httpFs := http.FileServer(http.FS(subFs))
	_, err := fs.ReadFile(subFs, filePath)
	if err != nil {
		c.String(404, "Not found")
		c.Abort()
		return
	}
	httpFs.ServeHTTP(c.Writer, c.Request)
}

func handleIndexHTML(c *gin.Context) {
	uiFs := iEmbed.UIStaticFiles
	subFs, _ := fs.Sub(uiFs, "ui")
	
	// 读取原始HTML文件
	htmlBytes, err := fs.ReadFile(subFs, "index.html")
	if err != nil {
		c.String(404, "Not found")
		c.Abort()
		return
	}
	
	htmlContent := string(htmlBytes)
	
	// 注入动态标题和favicon
	if config.Config.Location != "" {
		title := config.Config.Location
		htmlContent = strings.Replace(htmlContent, "<title>Looking glass server</title>", 
			fmt.Sprintf("<title>%s</title>", title), 1)
	}
	
	// 注入favicon
	if config.Config.Logo != "" && (config.Config.LogoType == "url" || config.Config.LogoType == "base64") {
		faviconLink := fmt.Sprintf(`<link rel="icon" href="%s">`, config.Config.Logo)
		htmlContent = strings.Replace(htmlContent, `<link rel="icon" href="/favicon.ico">`, faviconLink, 1)
	}
	
	c.Header("Content-Type", "text/html; charset=utf-8")
	c.String(200, htmlContent)
}

func handleFavicon(c *gin.Context) {
	// 如果配置了URL类型的logo，重定向到该URL
	if config.Config.Logo != "" && config.Config.LogoType == "url" {
		c.Redirect(302, config.Config.Logo)
		return
	}
	
	// 如果配置了base64类型的logo，直接返回数据
	if config.Config.Logo != "" && config.Config.LogoType == "base64" {
		// 解析data URL获取MIME类型和数据
		if strings.HasPrefix(config.Config.Logo, "data:") {
			parts := strings.Split(config.Config.Logo, ",")
			if len(parts) == 2 {
				// 解析MIME类型
				mimeType := "image/png" // 默认类型
				if strings.Contains(parts[0], "image/") {
					mimeStart := strings.Index(parts[0], "image/")
					mimeEnd := strings.Index(parts[0][mimeStart:], ";")
					if mimeEnd == -1 {
						mimeType = parts[0][mimeStart:]
					} else {
						mimeType = parts[0][mimeStart:mimeStart+mimeEnd]
					}
				}
				
				c.Header("Content-Type", mimeType)
				c.String(200, parts[1])
				return
			}
		}
	}
	
	// 如果配置了自定义logo且为emoji类型，生成emoji favicon
	if config.Config.Logo != "" && config.Config.LogoType == "emoji" {
		// 生成简单的emoji SVG favicon
		svgContent := fmt.Sprintf(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
			<text y="24" font-size="24">%s</text>
		</svg>`, config.Config.Logo)
		
		c.Header("Content-Type", "image/svg+xml")
		c.String(200, svgContent)
		return
	}
	
	// 如果配置了SVG logo，将其作为favicon
	if config.Config.Logo != "" && config.Config.LogoType == "svg" {
		c.Header("Content-Type", "image/svg+xml")
		c.String(200, config.Config.Logo)
		return
	}
	
	// 默认使用内置favicon
	handleStatisFile("favicon.ico", c)
}
