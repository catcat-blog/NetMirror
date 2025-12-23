package tokens

import (
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/X-Zero-L/als/als/controller/nodes"
	"github.com/gin-gonic/gin"
)

// CreateToken creates a new registration token (admin only)
func CreateToken(c *gin.Context) {
	var req TokenCreateRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Default expiry is 24 hours
	expiresIn := req.ExpiresIn
	if expiresIn <= 0 {
		expiresIn = 24
	}

	token := RegistrationToken{
		Name:      req.Name,
		Location:  req.Location,
		CreatedAt: time.Now(),
		ExpiresAt: time.Now().Add(time.Duration(expiresIn) * time.Hour),
	}

	if err := storage.AddToken(token); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Fetch the created token to get the generated ID and token value
	tokens, _ := storage.GetTokens()
	var createdToken *RegistrationToken
	for i := len(tokens) - 1; i >= 0; i-- {
		if tokens[i].Name == req.Name && tokens[i].Location == req.Location {
			createdToken = &tokens[i]
			break
		}
	}

	if createdToken == nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to retrieve created token",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"token":   createdToken.ToResponse(),
	})
}

// ListTokens returns all registration tokens (admin only)
func ListTokens(c *gin.Context) {
	tokens, err := storage.GetTokens()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	var response []TokenResponse
	for _, t := range tokens {
		response = append(response, t.ToResponse())
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"tokens":  response,
	})
}

// DeleteToken deletes a registration token (admin only)
func DeleteToken(c *gin.Context) {
	id := c.Param("id")

	if err := storage.DeleteToken(id); err != nil {
		if err.Error() == "token not found" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error":   "Token not found",
			})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   err.Error(),
			})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Token deleted successfully",
	})
}

// GetInstallScript returns the install script for a token (admin only)
func GetInstallScript(c *gin.Context) {
	tokenValue := c.Param("token")

	token, err := storage.GetTokenByValue(tokenValue)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Token not found",
		})
		return
	}

	// Check if token is still valid
	if token.GetStatus() != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Token is no longer valid (status: " + token.GetStatus() + ")",
		})
		return
	}

	// Generate master node URL
	masterURL := getMasterNodeURL(c.Request)

	script := generateInstallScript(token, masterURL)
	c.Header("Content-Type", "text/x-shellscript")
	c.Header("Content-Disposition", fmt.Sprintf("inline; filename=\"netmirror-install-%s.sh\"", token.ID))
	c.String(http.StatusOK, script)
}

// RegisterNode registers a node using a token (public endpoint, no admin key required)
func RegisterNode(c *gin.Context) {
	var req NodeRegistrationRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Find token by value
	token, err := storage.GetTokenByValue(req.Token)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "Invalid or expired token",
		})
		return
	}

	// Validate token status
	if token.UsedAt != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Token has already been used",
		})
		return
	}

	if time.Now().After(token.ExpiresAt) {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Token has expired",
		})
		return
	}

	// Create node using nodes package
	node := nodes.Node{
		Name:     token.Name,
		Location: token.Location,
		URL:      req.URL,
	}

	// Get nodes storage and add node
	nodeStorage := nodes.GetStorage()
	if err := nodeStorage.AddNode(node); err != nil {
		// If node already exists, it's okay - might be a retry
		if !strings.Contains(err.Error(), "already exists") {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   err.Error(),
			})
			return
		}
	}

	// Mark token as used
	now := time.Now()
	token.UsedAt = &now
	token.UsedByIP = c.ClientIP()
	storage.UpdateToken(token.ID, *token)

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Node registered successfully",
		"node": gin.H{
			"name":     token.Name,
			"location": token.Location,
			"url":      req.URL,
		},
	})
}

// getMasterNodeURL determines the master node URL from the request
func getMasterNodeURL(r *http.Request) string {
	// Try to get from environment first
	if masterURL := os.Getenv("LG_CURRENT_URL"); masterURL != "" {
		return masterURL
	}

	// Build from request
	scheme := "http"
	if r.TLS != nil {
		scheme = "https"
	}
	// Check for forwarded protocol
	if proto := r.Header.Get("X-Forwarded-Proto"); proto != "" {
		scheme = proto
	}

	host := r.Host
	// Check for forwarded host
	if forwardedHost := r.Header.Get("X-Forwarded-Host"); forwardedHost != "" {
		host = forwardedHost
	}

	return fmt.Sprintf("%s://%s", scheme, host)
}
