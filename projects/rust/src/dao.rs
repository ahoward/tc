use serde_json::{json, Value};
use uuid::Uuid;
use crate::operations;
use crate::store::{ResultStore, OperationResponse};

/// DAO provides a unified interface for operation invocation
pub struct DAO {
    store: ResultStore,
}

impl DAO {
    /// Create a new DAO instance
    pub fn new() -> Self {
        DAO {
            store: ResultStore::new(),
        }
    }

    /// Call an operation with parameters
    pub fn call(&self, operation: &str, params: &Value) -> Value {
        // Special case: /result/poll retrieves existing result
        if operation == "/result/poll" {
            let poll_id = match params.get("id").and_then(|v| v.as_str()) {
                Some(id) => id,
                None => return json!({"error": "Missing required parameter: id"}),
            };

            return match self.store.get(poll_id) {
                Some(stored) => self.response_to_value(&stored),
                None => json!({"error": format!("Result not found or expired: {}", poll_id)}),
            };
        }

        // Generate correlation UUID
        let id = Uuid::new_v4().to_string();

        // Route to operation handler
        match self.route_operation(operation, params) {
            Ok(result) => {
                // Special case: /usage/track completes synchronously
                if operation == "/usage/track" {
                    let completed_response = OperationResponse {
                        id: id.clone(),
                        status: "completed".to_string(),
                        result: Some(result),
                        error: None,
                    };
                    self.store.set(id.clone(), completed_response.clone());
                    return self.response_to_value(&completed_response);
                }

                // Standard async pattern: store completed result, return pending
                let completed_response = OperationResponse {
                    id: id.clone(),
                    status: "completed".to_string(),
                    result: Some(result),
                    error: None,
                };
                self.store.set(id.clone(), completed_response);

                // Return initial pending response (async pattern)
                json!({
                    "id": id,
                    "status": "pending"
                })
            }
            Err(error) => {
                // Store failed result and return error
                let failed_response = OperationResponse {
                    id: id.clone(),
                    status: "failed".to_string(),
                    result: None,
                    error: Some(error.clone()),
                };
                self.store.set(id, failed_response);

                json!({"error": error})
            }
        }
    }

    /// Route operation to appropriate handler
    fn route_operation(&self, operation: &str, params: &Value) -> Result<Value, String> {
        match operation {
            "/prompt/generate" => operations::process_prompt(params),
            "/template/create" => operations::create_template(params),
            "/template/render" => operations::render_template(params),
            "/usage/track" => operations::track_usage(params),
            _ => Err(format!("Invalid operation: {}", operation)),
        }
    }

    /// Convert OperationResponse to JSON Value
    fn response_to_value(&self, resp: &OperationResponse) -> Value {
        let mut map = serde_json::Map::new();
        map.insert("id".to_string(), json!(resp.id));
        map.insert("status".to_string(), json!(resp.status));

        if let Some(ref result) = resp.result {
            map.insert("result".to_string(), result.clone());
        }

        if let Some(ref error) = resp.error {
            map.insert("error".to_string(), json!(error));
        }

        Value::Object(map)
    }
}

impl Default for DAO {
    fn default() -> Self {
        Self::new()
    }
}
