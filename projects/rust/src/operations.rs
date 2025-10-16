use serde_json::{json, Value};
use uuid::Uuid;
use chrono::Utc;

/// Process a prompt with simulated AI processing
pub fn process_prompt(params: &Value) -> Result<Value, String> {
    let text = params.get("text")
        .and_then(|v| v.as_str())
        .ok_or_else(|| "Missing required parameter: text".to_string())?;

    if text.is_empty() {
        return Err("Missing required parameter: text".to_string());
    }

    if text.len() > 10000 {
        return Err("Text must be between 1 and 10000 characters".to_string());
    }

    // Simulated AI processing: uppercase + suffix
    Ok(json!({
        "text": text,
        "processed": format!("{} [AI-processed]", text.to_uppercase()),
        "timestamp": Utc::now().to_rfc3339()
    }))
}

/// Create a reusable template with variable placeholders
pub fn create_template(params: &Value) -> Result<Value, String> {
    let name = params.get("name")
        .and_then(|v| v.as_str())
        .ok_or_else(|| "Missing required parameter: name".to_string())?;

    let pattern = params.get("pattern")
        .and_then(|v| v.as_str())
        .ok_or_else(|| "Missing required parameter: pattern".to_string())?;

    let variables = params.get("variables")
        .and_then(|v| v.as_array())
        .cloned()
        .unwrap_or_default();

    // Validate name format (alphanumeric + hyphens)
    if !name.chars().all(|c| c.is_alphanumeric() || c == '-') {
        return Err("Invalid template name: must be alphanumeric with hyphens".to_string());
    }

    Ok(json!({
        "id": Uuid::new_v4().to_string(),
        "name": name,
        "pattern": pattern,
        "variables": variables
    }))
}

/// Render a template with variable substitution
pub fn render_template(params: &Value) -> Result<Value, String> {
    let template_id = params.get("template_id")
        .and_then(|v| v.as_str())
        .ok_or_else(|| "Missing required parameter: template_id".to_string())?;

    let values = params.get("values")
        .and_then(|v| v.as_object())
        .cloned()
        .unwrap_or_default();

    // For demo: simple rendered output
    let rendered = format!("Rendered template {} with variables", template_id);

    Ok(json!({
        "template_id": template_id,
        "rendered": rendered,
        "variables_used": values
    }))
}

/// Track usage of an operation for analytics
pub fn track_usage(params: &Value) -> Result<Value, String> {
    let operation = params.get("operation")
        .and_then(|v| v.as_str())
        .ok_or_else(|| "Missing required parameter: operation".to_string())?;

    let duration_ms = params.get("duration_ms")
        .and_then(|v| v.as_f64())
        .ok_or_else(|| "Missing required parameter: duration_ms".to_string())?;

    if duration_ms < 0.0 {
        return Err("duration_ms must be non-negative".to_string());
    }

    Ok(json!({
        "tracked": true,
        "operation": operation,
        "timestamp": Utc::now().to_rfc3339()
    }))
}
