package tokens

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"sync"
	"time"
)

// TokenStorage interface for different storage backends
type TokenStorage interface {
	GetTokens() ([]RegistrationToken, error)
	AddToken(token RegistrationToken) error
	GetToken(id string) (*RegistrationToken, error)
	GetTokenByValue(tokenValue string) (*RegistrationToken, error)
	UpdateToken(id string, token RegistrationToken) error
	DeleteToken(id string) error
}

// FileTokenStorage implements TokenStorage using JSON file
type FileTokenStorage struct {
	filePath string
	mu       sync.RWMutex
}

// NewFileTokenStorage creates a new file-based storage
func NewFileTokenStorage(filePath string) *FileTokenStorage {
	return &FileTokenStorage{filePath: filePath}
}

// GetTokens returns all tokens
func (fs *FileTokenStorage) GetTokens() ([]RegistrationToken, error) {
	fs.mu.RLock()
	defer fs.mu.RUnlock()

	if _, err := os.Stat(fs.filePath); os.IsNotExist(err) {
		return []RegistrationToken{}, nil
	}

	data, err := os.ReadFile(fs.filePath)
	if err != nil {
		return nil, err
	}

	var tokens []RegistrationToken
	if err := json.Unmarshal(data, &tokens); err != nil {
		return nil, err
	}

	return tokens, nil
}

// AddToken adds a new token
func (fs *FileTokenStorage) AddToken(token RegistrationToken) error {
	fs.mu.Lock()
	defer fs.mu.Unlock()

	tokens, err := fs.getTokensUnsafe()
	if err != nil {
		return err
	}

	// Generate unique ID if not provided
	if token.ID == "" {
		token.ID = generateTokenID()
		// Ensure ID is truly unique
		for {
			exists := false
			for _, t := range tokens {
				if t.ID == token.ID {
					exists = true
					break
				}
			}
			if !exists {
				break
			}
			token.ID = generateTokenID()
		}
	}

	// Generate token value if not provided
	if token.Token == "" {
		token.Token = generateSecureToken()
	}

	tokens = append(tokens, token)
	return fs.saveTokensUnsafe(tokens)
}

// GetToken returns a token by ID
func (fs *FileTokenStorage) GetToken(id string) (*RegistrationToken, error) {
	fs.mu.RLock()
	defer fs.mu.RUnlock()

	tokens, err := fs.getTokensUnsafe()
	if err != nil {
		return nil, err
	}

	for _, t := range tokens {
		if t.ID == id {
			return &t, nil
		}
	}

	return nil, fmt.Errorf("token not found")
}

// GetTokenByValue returns a token by its value
func (fs *FileTokenStorage) GetTokenByValue(tokenValue string) (*RegistrationToken, error) {
	fs.mu.RLock()
	defer fs.mu.RUnlock()

	tokens, err := fs.getTokensUnsafe()
	if err != nil {
		return nil, err
	}

	for _, t := range tokens {
		if t.Token == tokenValue {
			return &t, nil
		}
	}

	return nil, fmt.Errorf("token not found")
}

// UpdateToken updates an existing token
func (fs *FileTokenStorage) UpdateToken(id string, token RegistrationToken) error {
	fs.mu.Lock()
	defer fs.mu.Unlock()

	tokens, err := fs.getTokensUnsafe()
	if err != nil {
		return err
	}

	for i, t := range tokens {
		if t.ID == id {
			token.ID = id
			tokens[i] = token
			return fs.saveTokensUnsafe(tokens)
		}
	}

	return fmt.Errorf("token not found")
}

// DeleteToken deletes a token
func (fs *FileTokenStorage) DeleteToken(id string) error {
	fs.mu.Lock()
	defer fs.mu.Unlock()

	tokens, err := fs.getTokensUnsafe()
	if err != nil {
		return err
	}

	for i, t := range tokens {
		if t.ID == id {
			tokens = append(tokens[:i], tokens[i+1:]...)
			return fs.saveTokensUnsafe(tokens)
		}
	}

	return fmt.Errorf("token not found")
}

// Internal methods without locking (must be called with lock held)

func (fs *FileTokenStorage) getTokensUnsafe() ([]RegistrationToken, error) {
	if _, err := os.Stat(fs.filePath); os.IsNotExist(err) {
		return []RegistrationToken{}, nil
	}

	data, err := os.ReadFile(fs.filePath)
	if err != nil {
		return nil, err
	}

	var tokens []RegistrationToken
	if err := json.Unmarshal(data, &tokens); err != nil {
		return nil, err
	}

	return tokens, nil
}

func (fs *FileTokenStorage) saveTokensUnsafe(tokens []RegistrationToken) error {
	data, err := json.MarshalIndent(tokens, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(fs.filePath, data, 0644)
}

// Helper functions

// generateTokenID generates a unique ID for tokens
func generateTokenID() string {
	bytes := make([]byte, 4)
	if _, err := rand.Read(bytes); err != nil {
		return fmt.Sprintf("token_%d_%d", time.Now().Unix(), time.Now().UnixNano()%1000000)
	}
	return fmt.Sprintf("token_%s", hex.EncodeToString(bytes))
}

// generateSecureToken generates a cryptographically secure token value
func generateSecureToken() string {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		// Fallback to timestamp-based token
		return fmt.Sprintf("tk_%d_%d", time.Now().Unix(), time.Now().UnixNano())
	}
	return base64.URLEncoding.EncodeToString(bytes)
}

// Global storage instance
var storage TokenStorage

// Initialize storage
func init() {
	dataDir := os.Getenv("DATA_DIR")
	if dataDir == "" {
		dataDir = "./data"
	}

	// Ensure data directory exists
	os.MkdirAll(dataDir, 0755)

	storage = NewFileTokenStorage(dataDir + "/tokens.json")
}

// GetStorage returns the global storage instance
func GetStorage() TokenStorage {
	return storage
}
