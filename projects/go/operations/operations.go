package operations

import (
	"crypto/rand"
	"fmt"
	"regexp"
	"strings"
	"time"
)

// GenerateUUID creates a UUID v4 using crypto/rand (no external dependencies)
func GenerateUUID() string {
	b := make([]byte, 16)
	_, err := rand.Read(b)
	if err != nil {
		// Fallback to timestamp-based UUID if crypto/rand fails
		return fmt.Sprintf("%08x-0000-4000-8000-%012x", time.Now().Unix(), time.Now().UnixNano())
	}

	// Set version (4) and variant bits
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80

	return fmt.Sprintf("%08x-%04x-%04x-%04x-%012x",
		b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}

// ProcessPrompt simulates AI prompt processing
func ProcessPrompt(params map[string]interface{}) (map[string]interface{}, error) {
	text, ok := params["text"].(string)
	if !ok || text == "" {
		return nil, fmt.Errorf("Missing required parameter: text")
	}

	if len(text) > 10000 {
		return nil, fmt.Errorf("Text must be between 1 and 10000 characters")
	}

	// Simulated AI processing: uppercase + suffix
	result := map[string]interface{}{
		"text":      text,
		"processed": strings.ToUpper(text) + " [AI-processed]",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	}

	return result, nil
}

// CreateTemplate creates a reusable template with variable placeholders
func CreateTemplate(params map[string]interface{}) (map[string]interface{}, error) {
	name, ok := params["name"].(string)
	if !ok || name == "" {
		return nil, fmt.Errorf("Missing required parameter: name")
	}

	pattern, ok := params["pattern"].(string)
	if !ok || pattern == "" {
		return nil, fmt.Errorf("Missing required parameter: pattern")
	}

	variables, _ := params["variables"].([]interface{})

	// Validate name format
	validName := regexp.MustCompile(`^[a-zA-Z0-9-]+$`)
	if !validName.MatchString(name) {
		return nil, fmt.Errorf("Invalid template name: must be alphanumeric with hyphens")
	}

	result := map[string]interface{}{
		"id":        GenerateUUID(),
		"name":      name,
		"pattern":   pattern,
		"variables": variables,
	}

	return result, nil
}

// RenderTemplate renders a template with variable substitution
func RenderTemplate(params map[string]interface{}) (map[string]interface{}, error) {
	templateID, ok := params["template_id"].(string)
	if !ok || templateID == "" {
		return nil, fmt.Errorf("Missing required parameter: template_id")
	}

	values, ok := params["values"].(map[string]interface{})
	if !ok {
		values = make(map[string]interface{})
	}

	// For demo: simple rendered output
	rendered := fmt.Sprintf("Rendered template %s with variables", templateID)

	result := map[string]interface{}{
		"template_id":    templateID,
		"rendered":       rendered,
		"variables_used": values,
	}

	return result, nil
}

// TrackUsage tracks operation usage for analytics
func TrackUsage(params map[string]interface{}) (map[string]interface{}, error) {
	operation, ok := params["operation"].(string)
	if !ok || operation == "" {
		return nil, fmt.Errorf("Missing required parameter: operation")
	}

	durationMS, ok := params["duration_ms"].(float64)
	if !ok {
		return nil, fmt.Errorf("Missing required parameter: duration_ms")
	}

	if durationMS < 0 {
		return nil, fmt.Errorf("duration_ms must be non-negative")
	}

	result := map[string]interface{}{
		"tracked":   true,
		"operation": operation,
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	}

	return result, nil
}
