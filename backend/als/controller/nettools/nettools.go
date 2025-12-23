package nettools

import (
	"context"
	"fmt"
	"io"
	"net"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/X-Zero-L/als/als/client"
	"github.com/gin-gonic/gin"
)

// NetworkTool represents a network diagnostic tool
type NetworkTool struct {
	Name      string
	Command   string
	Args      []string
	IPv6      bool
	Timeout   time.Duration
	EventName string
}

// GetNetworkTools returns available network tools
func GetNetworkTools() map[string]NetworkTool {
	return map[string]NetworkTool{
		"mtr": {
			Name:      "mtr",
			Command:   "mtr",
			Args:      []string{"--report", "--report-cycles", "10", "--no-dns"},
			IPv6:      false,
			Timeout:   60 * time.Second,
			EventName: "MTROutput",
		},
		"mtr6": {
			Name:      "mtr6",
			Command:   "mtr",
			Args:      []string{"--report", "--report-cycles", "10", "--no-dns", "-6"},
			IPv6:      true,
			Timeout:   60 * time.Second,
			EventName: "MTR6Output",
		},
		"traceroute": {
			Name:      "traceroute",
			Command:   "traceroute",
			Args:      []string{},
			IPv6:      false,
			Timeout:   60 * time.Second,
			EventName: "TracerouteOutput",
		},
		"traceroute6": {
			Name:      "traceroute6",
			Command:   "traceroute6",
			Args:      []string{},
			IPv6:      true,
			Timeout:   60 * time.Second,
			EventName: "Traceroute6Output",
		},
	}
}

// HandleNetworkTool handles network tool requests
func HandleNetworkTool(toolName string) gin.HandlerFunc {
	return func(c *gin.Context) {
		ip, ok := c.GetQuery("ip")
		if !ok || ip == "" {
			c.JSON(400, &gin.H{
				"success": false,
				"error":   "Invalid IP Address",
			})
			return
		}

		// Validate input to prevent command injection
		if !isValidIPOrHostname(ip) {
			c.JSON(400, &gin.H{
				"success": false,
				"error":   "Invalid IP address or hostname format",
			})
			return
		}

		v, exists := c.Get("clientSession")
		if !exists {
			c.JSON(500, &gin.H{
				"success": false,
				"error":   "Client session not found",
			})
			return
		}

		clientSession := v.(*client.ClientSession)

		tools := GetNetworkTools()
		tool, exists := tools[toolName]
		if !exists {
			c.JSON(400, &gin.H{
				"success": false,
				"error":   "Tool not supported",
			})
			return
		}

		// Create timeout context
		timeout := tool.Timeout
		ctx, cancel := context.WithTimeout(clientSession.GetContext(c.Request.Context()), timeout)
		defer cancel()

		// Build command
		args := append(tool.Args, ip)
		cmd := exec.CommandContext(ctx, tool.Command, args...)

		// Send start message
		clientSession.Channel <- &client.Message{
			Name:    tool.EventName,
			Content: fmt.Sprintf(`{"output":"Starting %s to %s...\n","finished":false}`, tool.Name, ip),
		}

		// WaitGroup to ensure all output is sent before completion message
		var wg sync.WaitGroup

		// Writer function with WaitGroup synchronization
		writer := func(pipe io.ReadCloser, err error) {
			defer wg.Done()
			if err != nil {
				return
			}
			for {
				buf := make([]byte, 1024)
				n, err := pipe.Read(buf)
				if err != nil {
					return
				}
				msg := &client.Message{
					Name:    tool.EventName,
					Content: fmt.Sprintf(`{"output":%s,"finished":false}`, strconv.Quote(string(buf[:n]))),
				}
				clientSession.Channel <- msg
			}
		}

		wg.Add(2)
		go writer(cmd.StdoutPipe())
		go writer(cmd.StderrPipe())

		err := cmd.Start()
		if err != nil {
			wg.Wait() // Wait for goroutines even on error
			c.JSON(400, &gin.H{
				"success": false,
				"error":   err.Error(),
			})
			return
		}

		cmd.Wait()
		wg.Wait() // Wait for all output to be sent before completion message

		// Send completion message
		clientSession.Channel <- &client.Message{
			Name:    tool.EventName,
			Content: fmt.Sprintf(`{"output":"\n%s completed.\n","finished":true}`, tool.Name),
		}

		c.JSON(200, &gin.H{
			"success": true,
		})
	}
}

// isValidIPOrHostname validates if the input is a valid IP address or hostname
func isValidIPOrHostname(input string) bool {
	// Check if it's a valid IP address (v4 or v6)
	if net.ParseIP(input) != nil {
		return true
	}

	// Check if it's a valid hostname
	// Allow only alphanumeric, dots, hyphens
	hostnameRegex := regexp.MustCompile(`^[a-zA-Z0-9.-]+$`)
	if !hostnameRegex.MatchString(input) {
		return false
	}

	// Additional checks for shell injection attempts
	dangerousPatterns := []string{
		";", "&", "|", "`", "$", "(", ")", "{", "}", "[", "]",
		"<", ">", "\\", "'", "\"", "\n", "\r", "\t", "\x00",
		"*", "?", "~", "!", "#", "%", "^", "=", "+", " ",
	}

	for _, pattern := range dangerousPatterns {
		if strings.Contains(input, pattern) {
			return false
		}
	}

	// Check length limits
	if len(input) > 255 {
		return false
	}

	// Check that hostname doesn't start or end with special chars
	if strings.HasPrefix(input, "-") || strings.HasSuffix(input, "-") ||
		strings.HasPrefix(input, ".") || strings.HasSuffix(input, ".") {
		return false
	}

	return true
}
