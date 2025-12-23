package tokens

import (
	"time"
)

// RegistrationToken represents a one-time deployment token
type RegistrationToken struct {
	ID               string     `json:"id"`
	Token            string     `json:"token"`
	Name             string     `json:"name"`
	Location         string     `json:"location"`
	CreatedAt        time.Time  `json:"created_at"`
	ExpiresAt        time.Time  `json:"expires_at"`
	UsedAt           *time.Time `json:"used_at,omitempty"`
	UsedByIP         string     `json:"used_by_ip,omitempty"`
	RegisteredNodeID string     `json:"registered_node_id,omitempty"`
}

// TokenCreateRequest for API endpoint
type TokenCreateRequest struct {
	Name      string `json:"name" binding:"required"`
	Location  string `json:"location" binding:"required"`
	ExpiresIn int    `json:"expires_in"` // Hours, default 24
}

// TokenResponse for API list response
type TokenResponse struct {
	ID        string `json:"id"`
	Token     string `json:"token"`
	Name      string `json:"name"`
	Location  string `json:"location"`
	CreatedAt string `json:"created_at"`
	ExpiresAt string `json:"expires_at"`
	Status    string `json:"status"` // "pending", "used", "expired"
	UsedAt    string `json:"used_at,omitempty"`
	UsedByIP  string `json:"used_by_ip,omitempty"`
}

// NodeRegistrationRequest from child node
type NodeRegistrationRequest struct {
	Token string `json:"token" binding:"required"`
	URL   string `json:"url" binding:"required"`
}

// GetStatus returns the current status of the token
func (t *RegistrationToken) GetStatus() string {
	if t.UsedAt != nil {
		return "used"
	}
	if time.Now().After(t.ExpiresAt) {
		return "expired"
	}
	return "pending"
}

// ToResponse converts a RegistrationToken to TokenResponse
func (t *RegistrationToken) ToResponse() TokenResponse {
	resp := TokenResponse{
		ID:        t.ID,
		Token:     t.Token,
		Name:      t.Name,
		Location:  t.Location,
		CreatedAt: t.CreatedAt.Format(time.RFC3339),
		ExpiresAt: t.ExpiresAt.Format(time.RFC3339),
		Status:    t.GetStatus(),
	}
	if t.UsedAt != nil {
		resp.UsedAt = t.UsedAt.Format(time.RFC3339)
	}
	if t.UsedByIP != "" {
		resp.UsedByIP = t.UsedByIP
	}
	return resp
}
