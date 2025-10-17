package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/ahoward/tc/projects/go/dao"
)

// Request represents the input JSON structure
type Request struct {
	Operation string                 `json:"operation"`
	Params    map[string]interface{} `json:"params"`
}

func main() {
	// Read and parse input JSON from stdin
	var req Request
	decoder := json.NewDecoder(os.Stdin)

	if err := decoder.Decode(&req); err != nil {
		errorResponse := map[string]interface{}{
			"error": fmt.Sprintf("Adapter error: Invalid JSON input - %s", err.Error()),
		}
		json.NewEncoder(os.Stdout).Encode(errorResponse)
		os.Exit(1)
	}

	// Initialize params if nil
	if req.Params == nil {
		req.Params = make(map[string]interface{})
	}

	// Create DAO instance and call operation
	d := dao.NewDAO()
	response := d.Call(req.Operation, req.Params)

	// Write response JSON to stdout
	encoder := json.NewEncoder(os.Stdout)
	if err := encoder.Encode(response); err != nil {
		errorResponse := map[string]interface{}{
			"error": fmt.Sprintf("Adapter error: %s", err.Error()),
		}
		json.NewEncoder(os.Stdout).Encode(errorResponse)
		os.Exit(1)
	}

	os.Exit(0)
}
