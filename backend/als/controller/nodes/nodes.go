package nodes

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// Node represents a Looking Glass node
type Node struct {
	ID       string `json:"id,omitempty"`       // 用于API管理的唯一ID
	Name     string `json:"name"`
	Location string `json:"location"`
	URL      string `json:"url"`
	Current  bool   `json:"current"`
	ApiKey   string `json:"api_key,omitempty"`  // 仅在创建/更新时使用
}

// NodeRequest represents the request payload for node management
type NodeRequest struct {
	Name     string `json:"name" binding:"required"`
	Location string `json:"location" binding:"required"`
	URL      string `json:"url" binding:"required"`
}

// LatencyResponse represents the latency test result
type LatencyResponse struct {
	Node    string `json:"node"`
	Latency int    `json:"latency"` // in milliseconds
	Status  string `json:"status"`  // "good", "medium", "high", "error"
}

// NodeStorage interface for different storage backends
type NodeStorage interface {
	GetNodes() ([]Node, error)
	AddNode(node Node) error
	UpdateNode(id string, node Node) error
	DeleteNode(id string) error
	GetNode(id string) (*Node, error)
}

// FileStorage implements NodeStorage using JSON file
type FileStorage struct {
	filePath string
}

// NewFileStorage creates a new file-based storage
func NewFileStorage(filePath string) *FileStorage {
	return &FileStorage{filePath: filePath}
}

func (fs *FileStorage) GetNodes() ([]Node, error) {
	if _, err := os.Stat(fs.filePath); os.IsNotExist(err) {
		return []Node{}, nil
	}

	data, err := os.ReadFile(fs.filePath)
	if err != nil {
		return nil, err
	}

	var nodes []Node
	if err := json.Unmarshal(data, &nodes); err != nil {
		return nil, err
	}

	return nodes, nil
}

// generateUniqueID generates a unique ID for nodes
func generateUniqueID() string {
	// Generate random bytes
	bytes := make([]byte, 4)
	if _, err := rand.Read(bytes); err != nil {
		// Fallback to timestamp-based ID with nanoseconds
		return fmt.Sprintf("node_%d_%d", time.Now().Unix(), time.Now().UnixNano()%1000000)
	}
	return fmt.Sprintf("node_%s", hex.EncodeToString(bytes))
}

func (fs *FileStorage) AddNode(node Node) error {
	nodes, err := fs.GetNodes()
	if err != nil {
		return err
	}

	// Check for duplicate name or URL
	for _, n := range nodes {
		if n.Name == node.Name {
			return fmt.Errorf("node with name '%s' already exists", node.Name)
		}
		if n.URL == node.URL {
			return fmt.Errorf("node with URL '%s' already exists", node.URL)
		}
	}

	// Generate unique ID if not provided
	if node.ID == "" {
		node.ID = generateUniqueID()
		// Ensure ID is truly unique
		for {
			exists := false
			for _, n := range nodes {
				if n.ID == node.ID {
					exists = true
					break
				}
			}
			if !exists {
				break
			}
			node.ID = generateUniqueID()
		}
	}

	nodes = append(nodes, node)
	return fs.saveNodes(nodes)
}

func (fs *FileStorage) UpdateNode(id string, node Node) error {
	nodes, err := fs.GetNodes()
	if err != nil {
		return err
	}

	// Check for duplicate name or URL (excluding the node being updated)
	for _, n := range nodes {
		if n.ID != id {
			if n.Name == node.Name {
				return fmt.Errorf("node with name '%s' already exists", node.Name)
			}
			if n.URL == node.URL {
				return fmt.Errorf("node with URL '%s' already exists", node.URL)
			}
		}
	}

	for i, n := range nodes {
		if n.ID == id {
			node.ID = id
			nodes[i] = node
			return fs.saveNodes(nodes)
		}
	}

	return fmt.Errorf("node not found")
}

func (fs *FileStorage) DeleteNode(id string) error {
	nodes, err := fs.GetNodes()
	if err != nil {
		return err
	}

	for i, n := range nodes {
		if n.ID == id {
			nodes = append(nodes[:i], nodes[i+1:]...)
			return fs.saveNodes(nodes)
		}
	}

	return fmt.Errorf("node not found")
}

func (fs *FileStorage) GetNode(id string) (*Node, error) {
	nodes, err := fs.GetNodes()
	if err != nil {
		return nil, err
	}

	for _, n := range nodes {
		if n.ID == id {
			return &n, nil
		}
	}

	return nil, fmt.Errorf("node not found")
}

func (fs *FileStorage) saveNodes(nodes []Node) error {
	data, err := json.MarshalIndent(nodes, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(fs.filePath, data, 0644)
}

var storage NodeStorage

// GetStorage returns the global storage instance
func GetStorage() NodeStorage {
	return storage
}

// Initialize storage
func init() {
	// Use file storage for now, can be extended to database later
	dataDir := os.Getenv("DATA_DIR")
	if dataDir == "" {
		dataDir = "./data"
	}
	
	// Ensure data directory exists
	os.MkdirAll(dataDir, 0755)
	
	storage = NewFileStorage(dataDir + "/nodes.json")
}

// RequireApiKey is the exported auth middleware for admin operations
func RequireApiKey(c *gin.Context) {
	apiKey := c.GetHeader("X-Api-Key")
	if apiKey == "" {
		apiKey = c.Query("api_key")
	}

	expectedKey := os.Getenv("ADMIN_API_KEY")
	if expectedKey == "" {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Admin API key not configured",
		})
		c.Abort()
		return
	}

	if apiKey != expectedKey {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "Invalid API key",
		})
		c.Abort()
		return
	}

	c.Next()
}

// GetNodes returns the list of LG nodes
func GetNodes(c *gin.Context) {
	nodes, err := storage.GetNodes()
	if err != nil {
		c.JSON(500, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Mark current node
	currentNodeURL := os.Getenv("LG_CURRENT_URL")
	for i, node := range nodes {
		if node.URL == currentNodeURL {
			nodes[i].Current = true
		}
		// Remove API key from response
		nodes[i].ApiKey = ""
	}

	c.JSON(200, gin.H{
		"success": true,
		"nodes":   nodes,
	})
}

// Admin API endpoints for node management

// CreateNode creates a new node (admin only, used by token registration)
func CreateNode(c *gin.Context) {
	var req NodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	node := Node{
		Name:     req.Name,
		Location: req.Location,
		URL:      req.URL,
	}

	if err := storage.AddNode(node); err != nil {
		// Handle specific duplicate errors
		if strings.Contains(err.Error(), "already exists") {
			c.JSON(http.StatusConflict, gin.H{
				"success": false,
				"error":   err.Error(),
			})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   err.Error(),
			})
		}
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Node created successfully",
	})
}

// UpdateNode updates an existing node (admin only)
func UpdateNode(c *gin.Context) {
	id := c.Param("id")
	
	var req NodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	node := Node{
		Name:     req.Name,
		Location: req.Location,
		URL:      req.URL,
	}

	if err := storage.UpdateNode(id, node); err != nil {
		if err.Error() == "node not found" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error":   "Node not found",
			})
		} else if strings.Contains(err.Error(), "already exists") {
			c.JSON(http.StatusConflict, gin.H{
				"success": false,
				"error":   err.Error(),
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
		"message": "Node updated successfully",
	})
}

// DeleteNode deletes a node (admin only)
func DeleteNode(c *gin.Context) {
	id := c.Param("id")

	if err := storage.DeleteNode(id); err != nil {
		if err.Error() == "node not found" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error":   "Node not found",
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
		"message": "Node deleted successfully",
	})
}

// GetNodeDetail gets a specific node (admin only)
func GetNodeDetail(c *gin.Context) {
	id := c.Param("id")

	node, err := storage.GetNode(id)
	if err != nil {
		if err.Error() == "node not found" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error":   "Node not found",
			})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   err.Error(),
			})
		}
		return
	}

	// Remove API key from response
	node.ApiKey = ""

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"node":    node,
	})
}

// TestLatency tests the latency to a specific node
func TestLatency(c *gin.Context) {
	// Get timestamp from client
	timestampStr, ok := c.GetQuery("timestamp")
	if !ok || timestampStr == "" {
		c.JSON(400, gin.H{
			"success": false,
			"error":   "timestamp parameter required",
		})
		return
	}
	
	// Parse timestamp
	clientTimestamp, err := strconv.ParseInt(timestampStr, 10, 64)
	if err != nil {
		c.JSON(400, gin.H{
			"success": false,
			"error":   "Invalid timestamp format",
		})
		return
	}
	
	// Calculate latency (current time - client timestamp)
	currentTime := time.Now().UnixMilli()
	latency := int(currentTime - clientTimestamp)
	
	// Determine status based on latency
	status := "good"
	if latency > 300 {
		status = "high"
	} else if latency > 150 {
		status = "medium"
	}
	
	c.JSON(200, gin.H{
		"success": true,
		"latency": latency,
		"status":  status,
		"timestamp": currentTime,
	})
}

// GetNodeConfig returns the current node configuration
func GetNodeConfig(c *gin.Context) {
	// Get current node info from environment
	currentName := os.Getenv("LG_CURRENT_NAME")
	currentLocation := os.Getenv("LG_CURRENT_LOCATION")
	currentURL := os.Getenv("LG_CURRENT_URL")
	
	if currentName == "" {
		currentName = "Local"
	}
	if currentLocation == "" {
		currentLocation = "Local Server"
	}
	
	c.JSON(200, gin.H{
		"success": true,
		"current": Node{
			Name:     currentName,
			Location: currentLocation,
			URL:      currentURL,
			Current:  true,
		},
	})
}