use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use serde::{Deserialize, Serialize};

/// OperationResponse represents a response from a DAO operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OperationResponse {
    pub id: String,
    pub status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub result: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

/// ResultStore provides thread-safe in-memory storage for operation results
#[derive(Clone)]
pub struct ResultStore {
    store: Arc<Mutex<HashMap<String, OperationResponse>>>,
}

impl ResultStore {
    /// Create a new ResultStore instance
    pub fn new() -> Self {
        ResultStore {
            store: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    /// Store an operation response by UUID
    pub fn set(&self, id: String, response: OperationResponse) {
        let mut store = self.store.lock().unwrap();
        store.insert(id, response);
    }

    /// Retrieve an operation response by UUID
    pub fn get(&self, id: &str) -> Option<OperationResponse> {
        let store = self.store.lock().unwrap();
        store.get(id).cloned()
    }

    /// Remove an operation response by UUID
    pub fn delete(&self, id: &str) -> Option<OperationResponse> {
        let mut store = self.store.lock().unwrap();
        store.remove(id)
    }

    /// Check if a result exists for the given UUID
    pub fn exists(&self, id: &str) -> bool {
        let store = self.store.lock().unwrap();
        store.contains_key(id)
    }
}

impl Default for ResultStore {
    fn default() -> Self {
        Self::new()
    }
}
