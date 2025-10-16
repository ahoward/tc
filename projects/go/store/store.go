package store

import (
	"sync"
)

// OperationResponse represents a response from a DAO operation
type OperationResponse struct {
	ID     string                 `json:"id"`
	Status string                 `json:"status"`
	Result map[string]interface{} `json:"result,omitempty"`
	Error  string                 `json:"error,omitempty"`
}

// ResultStore provides thread-safe in-memory storage for operation results
type ResultStore struct {
	mu    sync.RWMutex
	store map[string]OperationResponse
}

// NewResultStore creates a new ResultStore instance
func NewResultStore() *ResultStore {
	return &ResultStore{
		store: make(map[string]OperationResponse),
	}
}

// Set stores an operation response by UUID
func (rs *ResultStore) Set(id string, response OperationResponse) {
	rs.mu.Lock()
	defer rs.mu.Unlock()
	rs.store[id] = response
}

// Get retrieves an operation response by UUID
func (rs *ResultStore) Get(id string) (OperationResponse, bool) {
	rs.mu.RLock()
	defer rs.mu.RUnlock()
	response, exists := rs.store[id]
	return response, exists
}

// Delete removes an operation response by UUID
func (rs *ResultStore) Delete(id string) {
	rs.mu.Lock()
	defer rs.mu.Unlock()
	delete(rs.store, id)
}

// Exists checks if a result exists for the given UUID
func (rs *ResultStore) Exists(id string) bool {
	rs.mu.RLock()
	defer rs.mu.RUnlock()
	_, exists := rs.store[id]
	return exists
}
