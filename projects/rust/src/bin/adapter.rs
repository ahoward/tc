use serde_json::Value;
use std::io::{self, Read};
use dao_demo::dao::DAO;

fn main() {
    // Read and parse input JSON from stdin
    let mut input_data = String::new();
    if let Err(e) = io::stdin().read_to_string(&mut input_data) {
        let error_response = serde_json::json!({
            "error": format!("Adapter error: Failed to read stdin - {}", e)
        });
        println!("{}", serde_json::to_string(&error_response).unwrap());
        std::process::exit(1);
    }

    let input: Value = match serde_json::from_str(&input_data) {
        Ok(v) => v,
        Err(e) => {
            let error_response = serde_json::json!({
                "error": format!("Adapter error: Invalid JSON input - {}", e)
            });
            println!("{}", serde_json::to_string(&error_response).unwrap());
            std::process::exit(1);
        }
    };

    // Extract operation and params
    let operation = input.get("operation")
        .and_then(|v| v.as_str())
        .unwrap_or("");

    let params = input.get("params")
        .cloned()
        .unwrap_or(Value::Object(serde_json::Map::new()));

    // Create DAO instance and call operation
    let dao = DAO::new();
    let response = dao.call(operation, &params);

    // Write response JSON to stdout
    match serde_json::to_string(&response) {
        Ok(json_str) => {
            println!("{}", json_str);
            std::process::exit(0);
        }
        Err(e) => {
            let error_response = serde_json::json!({
                "error": format!("Adapter error: {}", e)
            });
            println!("{}", serde_json::to_string(&error_response).unwrap());
            std::process::exit(1);
        }
    }
}
