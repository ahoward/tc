package dao

import (
	"fmt"

	"github.com/ahoward/tc/projects/go/operations"
	"github.com/ahoward/tc/projects/go/store"
)

// DAO provides a unified interface for operation invocation
type DAO struct {
	store *store.ResultStore
}

// NewDAO creates a new DAO instance
func NewDAO() *DAO {
	return &DAO{
		store: store.NewResultStore(),
	}
}

// Call invokes an operation with parameters
func (d *DAO) Call(operation string, params map[string]interface{}) map[string]interface{} {
	// Special case: /result/poll retrieves existing result
	if operation == "/result/poll" {
		pollID, ok := params["id"].(string)
		if !ok || pollID == "" {
			return map[string]interface{}{
				"error": "Missing required parameter: id",
			}
		}

		stored, exists := d.store.Get(pollID)
		if !exists {
			return map[string]interface{}{
				"error": fmt.Sprintf("Result not found or expired: %s", pollID),
			}
		}

		return d.responseToMap(stored)
	}

	// Generate correlation UUID
	id := operations.GenerateUUID()

	// Route to operation handler
	result, err := d.routeOperation(operation, params)

	if err != nil {
		// Store failed result
		failedResponse := store.OperationResponse{
			ID:     id,
			Status: "failed",
			Error:  err.Error(),
		}
		d.store.Set(id, failedResponse)

		return map[string]interface{}{
			"error": err.Error(),
		}
	}

	// Special case: /usage/track completes synchronously
	if operation == "/usage/track" {
		completedResponse := store.OperationResponse{
			ID:     id,
			Status: "completed",
			Result: result,
		}
		d.store.Set(id, completedResponse)

		return d.responseToMap(completedResponse)
	}

	// Standard async pattern: store completed result, return pending
	completedResponse := store.OperationResponse{
		ID:     id,
		Status: "completed",
		Result: result,
	}
	d.store.Set(id, completedResponse)

	// Return initial pending response
	return map[string]interface{}{
		"id":     id,
		"status": "pending",
	}
}

// routeOperation routes operation to appropriate handler
func (d *DAO) routeOperation(operation string, params map[string]interface{}) (map[string]interface{}, error) {
	switch operation {
	case "/prompt/generate":
		return operations.ProcessPrompt(params)
	case "/template/create":
		return operations.CreateTemplate(params)
	case "/template/render":
		return operations.RenderTemplate(params)
	case "/usage/track":
		return operations.TrackUsage(params)
	default:
		return nil, fmt.Errorf("Invalid operation: %s", operation)
	}
}

// responseToMap converts OperationResponse to map for JSON encoding
func (d *DAO) responseToMap(resp store.OperationResponse) map[string]interface{} {
	m := map[string]interface{}{
		"id":     resp.ID,
		"status": resp.Status,
	}

	if resp.Result != nil {
		m["result"] = resp.Result
	}

	if resp.Error != "" {
		m["error"] = resp.Error
	}

	return m
}
